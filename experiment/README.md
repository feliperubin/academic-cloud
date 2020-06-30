# Paper Experiment


Testbed:
- OS: Ubuntu 18.04 LTS, upgraded from Ubuntu 16.04.06 LTS
- Hypervisor: Type-1 KVM
- Hardware: PowerEdge R720  
- RAM: 64GB (4x 16GB - DDR3 - 1333MHz)  
- CPU: 16 cores (32 threads) Intel(R) Xeon(R) CPU E5-2650 0 @ 2.00GHz - Capacity 32.0 GHz 
- Storage: 300GB (1x 300GB - 15K RPM - SAS 6Gbps) 
- Network: 3x NICs (2x ITF) 1x NIC (4x ITF) 10x - 1Gbit/s 


Networks Addresses:
- Public Network: 10.32.45.0/24
	- Host Machine: 10.32.45.219  
	- Host Dedicated NIC for Bridge: 10.32.45.216
	- Gateway Public Address: 10.32.45.215
- Management Network 10.0.0.0/24
- Provider Network 10.0.1.0/24
- Overlay Network: 10.0.2.0/24


First Deployment Allocated Resources:
- Gateway: 2 GB RAM, 1-core (2 HT)
- Storage: 4 GB RAM, 1-core (2 HT)
- Controller: 8 GB RAM, 1-core ( 2 HT)
- KVM 1: 4 GB RAM, 1-core ( 2 HT)
- KVM 2: 4 GB RAM, 1-core ( 2 HT)
- Host: N/A (Wasn't Configured)

Second Deployment Allocated Resources:
- Gateway: 2 GB RAM, 1-core (2 HT)
- Storage: 4 GB RAM, 1-core (2 HT)
- Controller: 16 GB RAM, 2-core ( 4 HT)
- KVM 1: 8 GB RAM, 2-core ( 4 HT)
- KVM 2: 8 GB RAM, 2-core ( 4 HT)
- Host: 24 GB RAM, 8-core (16 HT)

