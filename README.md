# onvm
This directory contains some explorative experimental results related to the high-speed OpenNetVM platform on a COTS server.

The experiments include 4 different Service Function Chaining (SFC) settings:

Linear
DAG
DAG-2
Tree
We conduct two types of experiments:

Load stimulus: Perturbing the input traffic with different input rates and traffic patterns.
Resource stimulus: Perturbing the allocated resource to individual VNFs. Currently, we assign collocated parasite processes to each VNF to purturb its CPU share.
Please refer to each directory for further details.
