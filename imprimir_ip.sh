# Imprimir la dirección IP de las máquinas
echo "publica"
VBoxManage guestproperty get asi_master /VirtualBox/GuestInfo/Net/1/V4/IP
VBoxManage guestproperty get asi_01 /VirtualBox/GuestInfo/Net/1/V4/IP
VBoxManage guestproperty get asi_02 /VirtualBox/GuestInfo/Net/1/V4/IP
echo ""
echo "Intra-NAT"
VBoxManage guestproperty get asi_master /VirtualBox/GuestInfo/Net/0/V4/IP
VBoxManage guestproperty get asi_01 /VirtualBox/GuestInfo/Net/0/V4/IP
VBoxManage guestproperty get asi_02 /VirtualBox/GuestInfo/Net/0/V4/IP
