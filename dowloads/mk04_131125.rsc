# jan/02/1970 21:07:27 by RouterOS 6.44.3
# software id = 9TDR-2B2W
#
# model = 951Ui-2HnD
# serial number = 4AC904BEAE7D
/interface bridge
add name=BR-DRONES vlan-filtering=yes
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=PtMP-Secure \
    supplicant-identity=agrotech-cb-st wpa2-pre-shared-key=AgroTechWDS_2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=argentina disabled=no \
    frequency=2462 mode=station-bridge scan-list=2462 security-profile=\
    PtMP-Secure ssid=AGROTECH-CAMPO-PTMP wireless-protocol=nv2
/interface bridge port
add bridge=BR-DRONES comment="Enlace PtMP" interface=wlan1
add bridge=BR-DRONES comment="Puerto Downstream Tagged" interface=ether2
/interface bridge vlan
add bridge=BR-DRONES tagged=wlan1,ether2 vlan-ids=10,20,90,201
/ip address
add address=10.200.1.21/24 comment="IP de Gestion Segregada" interface=ether3 \
    network=10.200.1.0
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input protocol=icmp
add action=drop chain=input comment="Drop all other input"
add action=accept chain=input comment="Allow Mgmt from Local LANs" \
    src-address=192.168.0.0/16
add action=accept chain=input comment="Allow Mgmt from Link/WAN" src-address=\
    10.200.1.0/24
add action=accept chain=forward comment="Allow all forward traffic (Bridge)"
/ip route
add comment="Ruta a MK01" distance=1 gateway=10.200.1.1
/snmp
set contact=laboratorio@universidad.edu enabled=yes location=\
    "Lab - Centro Drones"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=agrotech-cb-st
/system ntp client
set enabled=yes primary-ntp=10.200.1.1
