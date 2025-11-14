# jan/02/1970 21:50:39 by RouterOS 6.49.19
# software id = NNNW-EHRR
#
# model = SXT G-2HnD
# serial number = 41FE02CC65CB
/interface bridge
add name=BR-PTP vlan-filtering=yes
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=PtP-Secure \
    supplicant-identity=MikroTik wpa2-pre-shared-key=AgroTechWDS_2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=argentina disabled=no \
    frequency=auto mode=station-wds nv2-qos=frame-priority security-profile=\
    PtP-Secure ssid=AGROTECH-PTP-8KM wireless-protocol=nv2
/interface bridge port
add bridge=BR-PTP interface=wlan1
add bridge=BR-PTP interface=ether1
/interface bridge vlan
add bridge=BR-PTP tagged=wlan1,ether1 vlan-ids=10,20,90,96,201
/ip address
add address=10.200.1.51/24 comment="IP de Gestion PtP Cliente" interface=\
    ether1 network=10.200.1.0
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow Management" src-address=\
    10.200.1.0/24
add action=accept chain=input protocol=icmp
add action=drop chain=input comment="Drop all other input"
add action=accept chain=forward comment="Allow all forward traffic"
/ip route
add comment="Ruta por defecto hacia MK01" distance=1 gateway=10.200.1.1
/snmp
set contact=laboratorio@universidad.edu enabled=yes location=\
    "Lab - SXT Campo"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=sxt-ca
/system ntp client
set enabled=yes primary-ntp=10.200.1.1
