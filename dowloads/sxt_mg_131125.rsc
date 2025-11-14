# jan/01/1970 21:05:07 by RouterOS 6.49.19
# software id = QRX6-0SS9
#
# model = SXT G-2HnD
# serial number = 5A9505C44A45
/interface bridge
add name=BR-PTP vlan-filtering=yes
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=PtP-Secure \
    supplicant-identity=MikroTik wpa2-pre-shared-key=AgroTechWDS_2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=argentina disabled=no \
    frequency=2437 installation=outdoor mode=ap-bridge nv2-qos=frame-priority \
    security-profile=PtP-Secure ssid=AGROTECH-PTP-8KM wds-default-bridge=\
    BR-PTP wds-mode=dynamic wireless-protocol=nv2
/ip pool
add name=default-dhcp ranges=192.168.88.10-192.168.88.254
/ip dhcp-server
# DHCP server can not run on slave interface!
add address-pool=default-dhcp disabled=no interface=ether1 name=defconf
/interface bridge port
add bridge=BR-PTP interface=wlan1
add bridge=BR-PTP interface=ether1
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface bridge vlan
add bridge=BR-PTP tagged=wlan1,ether1 vlan-ids=10,20,90,96,201
/interface list member
add comment=defconf interface=ether1 list=LAN
add comment=defconf interface=wlan1 list=WAN
/ip address
add address=10.200.1.50/24 interface=ether1 network=10.200.1.0
/ip dhcp-client
# DHCP client can not run on slave interface!
add comment=defconf disabled=no interface=wlan1
/ip dhcp-server network
add address=192.168.88.0/24 comment=defconf dns-server=192.168.88.1 gateway=\
    192.168.88.1
/ip dns
set allow-remote-requests=yes
/ip dns static
add address=192.168.88.1 comment=defconf name=router.lan
/ip firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "defconf: accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow Management" src-address=\
    10.200.1.0/24
add action=accept chain=input protocol=icmp
add action=drop chain=input comment="Drop all other input"
add action=accept chain=forward comment="Allow all forward traffic"
/ip route
add distance=1 gateway=10.200.1.1
/snmp
set contact=laboratorio@universidad.edu enabled=yes location=\
    "Lab - SXT Magdalena"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=sxt-mg
/system ntp client
set enabled=yes primary-ntp=10.200.1.1
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
