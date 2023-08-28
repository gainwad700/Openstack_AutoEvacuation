# Info
This script can be run on the control nodes.

# Description
The script checks if a compute node is down. If so, it will migrate/evacuate all the instances/VMs on that host to another host.
After this migration, those VMs will be booted on the new hypervisors.

# Installation
git clone https://github.com/gainwad700/Openstack_AutoEvacuation.git

## Registry
docker build .
docker tag registry1:5000/hostevac:1
docker push registry1:5000/hostevac:1

## Control nodes
docker run --name hostevac --network host registry1:5000/hostevac:1

# Passwortwechsel
Wird das Adminpasswort des Projekts geändert, muss dieser auch im Container geändert werden.
