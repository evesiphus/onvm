# onvm
This directory contains some explorative experimental results related to the high-speed OpenNetVM platform on a COTS server.

The experiments include 4 different Service Function Chaining (SFC) settings:

1-Linear

2-DAG

3-DAG-2

4-Tree

We conduct two types of experiments:

1-Load stimulus: Perturbing the input traffic with different input rates and traffic patterns.

2-Resource stimulus: Perturbing the allocated resource to individual VNFs. Currently, we assign collocated parasite processes to each VNF to purturb its CPU share.

Please refer to each directory for further details.

