-- This test does the following:
--	1. Send UDP packets from NIC 1 and recieve them back from NIC 2
-- 	2. Read the statistics (i.e., throughput, end-to-end latency) from the recieving device
-- This script demonstrates how to access device specific statistics ("normal" stats and xstats) via DPDK

local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local log    = require "log"
local ts     = require "timestamping"

local ffi = require "ffi"

-- set addresses and ports here
local DST_MAC     = "5c:b9:01:88:ea:60"
local SRC_IP_BASE = "10.0.1.10"
local DST_IP      = "10.0.0.1"
local SRC_PORT    = 1234
local DST_PORT    = 319

local interval = 200
local C = ffi.C

function configure(parser)
	parser:description("Generates UDP traffic and prints out device statistics. Edit the source to modify constants like IPs.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
        parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
        parser:option("-f --flows", "Number of flows (randomized source IP)."):default(2):convert(tonumber)
        parser:option("-s --size", "Packet size."):default(60):convert(tonumber)
        parser:option("-t --topology", "Network service topology."):default("linear"):convert(tostring)
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 4, txQueues = 4}
	rxDev = device.config{port = args.rxDev, rxQueues = 4, txQueues = 4}
	device.waitForLinks()

	if args.rate > 0 then
		txDev:getTxQueue(0):setRate(args.rate - (args.size + 4) * 8 / 1000)
	end

	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows, args.topology)
	mg.startTask("timerSlave", txDev:getTxQueue(1), rxDev:getRxQueue(1), 124, args.flows)
	mg.waitForTasks()
end

local function fillUdpPacket(buf, len)
		buf:getUdpPacket():fill{
		ethSrc = queue,
		ethDst = DST_MAC,
		ip4Src = SRC_IP_BASE,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end

--- Runs on the sending NIC
--- Generates UDP traffic and also fetches the stats
function loadSlave(queue, rxDev, size, flows, topo)

	log:info(green("Starting up: LoadSlave"))
        log:info(green("Service topology:", topo))

	mg.sleepMillis(1000)
	-- retrieve the number of xstats on the recieving NIC
	-- xstats related C definitions are in device.lua
	local numxstats = 0
        local xstats = ffi.new("struct rte_eth_xstat[?]", numxstats)

	-- because there is no easy function which returns the number of xstats we try to retrieve
	-- the xstats with a zero sized array
	-- if result > numxstats (0 in our case), then result equals the real number of xstats
	local result = C.rte_eth_xstats_get(rxDev.id, xstats, numxstats)
	numxstats = tonumber(result)

	local mempool = memory.createMemPool(function(buf)
		fillUdpPacket(buf, size)
	end)
	local bufs = mempool:bufArray()

	if queue.qid == 0
	then
		txCtr = stats:newDevTxCounter(queue, "CSV", "tx_stats.csv")
		rxCtr = stats:newDevRxCounter(rxDev, "CSV", "rx_stats.csv")
	end

	local baseIP = parseIPAddress(DST_IP)
        local counter = 0
        local ctr = 1
        local limiter = timer:new(interval)

        local sizes = {124, 252, 508, 1020, 1024, 1024, 1514, 1514}
        local newSize = sizes[ctr]

        print("Initial size: " .. newSize)
	os.execute("./scripts/start_sfc.sh "..topo.." &")

	mg.sleepMillis(2500)
        os.execute("./scripts/pcm.sh &")

	-- send out UDP packets until the user stops the script
	while mg.running() do
		bufs:alloc(size)
		
        	if limiter:expired()
        	then
			limiter:reset()
                        newSize = sizes[math.random(#sizes)]
                        print(interval .. "s expired.." .. "Pkt size set to " .. newSize .. " Bytes")
 	        end

		for i, buf in ipairs(bufs) do
                       	buf:setSize(newSize)
			local pkt = buf:getUdpPacket()
			pkt.ip4.dst:set(baseIP + counter)
			counter = incAndWrap(counter, flows) 
		end

		-- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		--bufs:offloadUdpChecksums()
		--queue:sendWithDelay(bufs)
		queue:send(bufs)

		txCtr:update()
		rxCtr:update()
       end
end

function timerSlave(txQueue, rxQueue, size, flows)
	log:info(green("Starting up: timerSlave"))
        if size < 84 then
                log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
                size = 84
        end
        local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)

        mg.sleepMillis(3500) -- ensure that the load task is running

        local counter = 0
        local rateLimit = timer:new(1)
        local baseIP = parseIPAddress(DST_IP)
	latency = {}
        local t = 0
	local timestamp_counter = 0

	while mg.running() do
		t = timestamper:measureLatency(size, function(buf)
			fillUdpPacket(buf, size)
			local pkt = buf:getUdpPacket()
			pkt.ip4.dst:set(baseIP + counter)
			counter = incAndWrap(counter, flows)
		end) 

                if t == nil
                then
                        t = 15000000
                end

                table.insert(latency, t)
                rateLimit:wait()
		timestamp_counter = timestamp_counter + 1
                rateLimit:reset()
        end

        -- print the latency stats after all the other stuff
        mg.sleepMillis(30)
        
        print("Total timestamps: "..timestamp_counter.."\n")

	latency_test = io.open("latency.csv", "w")
	for i = 1, #latency do
        	latency_test:write(i.." "..latency[i].."\n")
	end

        latency_test:close(latency_test)
end
