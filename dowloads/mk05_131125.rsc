# jan/02/1970 20:56:06 by RouterOS 6.44.3
# software id = UXS0-IHTB
#
# model = 951Ui-2HnD
# serial number = 4AC904BA91D8
/interface bridge
add name=BR-GALPON vlan-filtering=yes
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=PtMP-Secure \
    supplicant-identity=agrotech-cc-st wpa2-pre-shared-key=AgroTechWDS_2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=argentina disabled=no \
    frequency=2462 mode=station-bridge scan-list=2462 security-profile=\
    PtMP-Secure ssid=AGROTECH-CAMPO-PTMP wireless-protocol=nv2
/interface bridge port
add bridge=BR-GALPON comment="Enlace PtMP" interface=wlan1
add bridge=BR-GALPON comment="Puerto Downstream Tagged" interface=ether2
/interface bridge vlan
add bridge=BR-GALPON tagged=wlan1,ether2 vlan-ids=20,90,201
/ip address
add address=10.200.1.22/24 comment="IP de Gestion Segregada" interface=ether3 \
    network=10.200.1.0
/ip firewall filter
add action=accept chain=input comment="1. Allow Established/Related" \
    connection-state=established,related
add action=accept chain=input comment="2. Allow ICMP/Ping" protocol=icmp
add action=accept chain=input comment="3. Allow Mgmt from Link/WAN" \
    src-address=10.200.1.0/24
add action=accept chain=input comment="4. Allow Mgmt from Local LANs" \
    src-address=192.168.0.0/16
add action=drop chain=input comment="5. Drop all other input"
add action=accept chain=forward comment=\
    "6. Allow all forward traffic (Bridge)"
/ip route
add comment="Ruta a MK01" distance=1 gateway=10.200.1.1
/snmp
set contact=laboratorio@universidad.edu enabled=yes location=\
    "Lab - Galpon Campo C"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=agrotech-cc-st
/system ntp client
set enabled=yes primary-ntp=10.200.1.1
