# First Deployment




Gateway:
RAM: 2048
vCPU: 2

Storage:
RAM: 4096
vCPU: 2

Controller:
RAM: 8192
vCPU: 2

KVM 1:
RAM: 4096
vCPU: 2

KVM 2:
RAM: 4096
vCPU: 2





provision() {
name="$1"
if [ "$name" == "gateway" ]; then 
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name $name \
--ram 2048 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:99:E5:CB:35:F6 \
--network network=privatenet,model=virtio,mac=02:BC:B9:48:1C:DB \
--network bridge=br0,model=virtio,mac=02:EB:B6:5B:E5:3C \
--network bridge=br0,model=virtio,mac=02:6F:D5:DB:C2:1F \
--noautoconsole

elif [ "$name" == "storage" ]; then 
# Storage
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name $name \
--ram 4096 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--disk=pool=default,size=50,format=qcow2,bus=virtio \
--import \
--network network=default,model=virtio,mac=02:F7:19:76:5F:9C \
--network network=privatenet,model=virtio,mac=02:52:87:1F:6E:CB \
--network bridge=br0,model=virtio,mac=02:4:75:F:A9:D \
--network bridge=br0,model=virtio,mac=02:76:2:5B:CB:CC \
--noautoconsole

elif [ "$name" == "controller" ]; then 
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name $name \
--ram 8192 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:CE:57:2B:FB:C8 \
--network network=privatenet,model=virtio,mac=02:E5:83:72:DA:43 \
--network bridge=br0,model=virtio,mac=02:2F:4A:AB:29:29 \
--network bridge=br0,model=virtio,mac=02:CE:59:5D:5C:E3 \
--noautoconsole

elif [ "$name" == "kvm1" ]; then 

virt-install \
--connect qemu:///system \
--virt-type kvm \
--accelerate \
--cpu host-passthrough \
--name $name \
--ram 4096 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:45:22:99:81:3C \
--network network=privatenet,model=virtio,mac=02:65:AC:8B:16:A2 \
--network bridge=br0,model=virtio,mac=02:24:5D:15:B5:ED \
--network bridge=br0,model=virtio,mac=02:50:9E:13:C8:0 \
--noautoconsole

elif [ "$name" == "kvm2" ]; then        
virt-install \
--connect qemu:///system \
--virt-type kvm \
--accelerate \
--cpu host-passthrough \
--name $name \
--ram 4096 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:DA:C5:C9:EA:90 \
--network network=privatenet,model=virtio,mac=02:6:32:DD:B8:69 \
--network bridge=br0,model=virtio,mac=02:31:F2:C5:F8:86 \
--network bridge=br0,model=virtio,mac=02:66:6B:D6:C1:3C \
--noautoconsole 
fi

