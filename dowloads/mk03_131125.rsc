# nov/13/2025 11:52:34 by RouterOS 6.48.3
# software id = 3JKZ-AQ07
#
# model = 951Ui-2HnD
# serial number = 4AC9041BDB96
/interface bridge
add comment="Core Transit L2 Bridge (VLANs 10, 20, 201)" name=BR-MAIN \
    vlan-filtering=yes
add comment="Local AP VLAN 96" name=BR-WiFi-Guest vlan-filtering=yes
add comment="Local AP VLAN 90" name=BR-WiFi-Priv vlan-filtering=yes
/interface vlan
add interface=ether1 name=VLAN10-Transit vlan-id=10
add interface=ether1 name=VLAN20-Transit vlan-id=20
add interface=ether1 name=VLAN90-Local vlan-id=90
add interface=ether1 name=VLAN96-Local vlan-id=96
add interface=ether1 name=VLAN201-Transit vlan-id=201
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=WiFi-Priv-Profile \
    supplicant-identity=MikroTik wpa2-pre-shared-key=AgroTechWiFi90_2025!
add authentication-types=wpa2-psk mode=dynamic-keys name=WiFi-Guest-Profile \
    supplicant-identity=MikroTik wpa2-pre-shared-key=GuestWiFi96_2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=argentina disabled=no \
    frequency=2427 mode=ap-bridge security-profile=WiFi-Priv-Profile ssid=\
    AgroTech-Cauelas
add disabled=no mac-address=4E:5E:0C:31:71:DF master-interface=wlan1 name=\
    wlan-guest security-profile=WiFi-Guest-Profile ssid=AgroTech-Guest-CA
/ip pool
add name=POOL-WiFi-Priv ranges=192.168.90.10-192.168.90.200
add name=POOL-WiFi-Guest ranges=192.168.96.10-192.168.96.200
/ip dhcp-server
add address-pool=POOL-WiFi-Priv disabled=no interface=BR-WiFi-Priv \
    lease-time=4h name=DHCP-WiFi-Priv
add address-pool=POOL-WiFi-Guest disabled=no interface=BR-WiFi-Guest \
    lease-time=1h name=DHCP-WiFi-Guest
/interface bridge port
add bridge=BR-MAIN comment="C-VLAN 10 from La Plata" interface=VLAN10-Transit
add bridge=BR-MAIN comment="C-VLAN 20 from La Plata" interface=VLAN20-Transit
add bridge=BR-MAIN comment="C-VLAN 201 from La Plata" interface=\
    VLAN201-Transit
add bridge=BR-WiFi-Priv comment="wlan1 untagged (Local VLAN 90)" interface=\
    wlan1 pvid=90
add bridge=BR-WiFi-Priv comment="VLAN 90 L3 interface (Slave)" interface=\
    VLAN90-Local
add bridge=BR-WiFi-Guest comment="wlan-guest untagged (Local VLAN 96)" \
    interface=wlan-guest pvid=96
add bridge=BR-WiFi-Guest comment="VLAN 96 L3 interface (Slave)" interface=\
    VLAN96-Local
/interface bridge vlan
add bridge=BR-MAIN tagged=ether2 untagged=VLAN10-Transit vlan-ids=10
add bridge=BR-MAIN tagged=ether2 untagged=VLAN20-Transit vlan-ids=20
add bridge=BR-MAIN tagged=ether2 untagged=VLAN201-Transit vlan-ids=201
add bridge=BR-WiFi-Priv untagged=wlan1,VLAN90-Local vlan-ids=90
add bridge=BR-WiFi-Guest untagged=wlan-guest,VLAN96-Local vlan-ids=96
/ip address
add address=10.200.1.11/24 comment="IP de Gestion/WAN" interface=ether3 \
    network=10.200.1.0
add address=192.168.90.1/24 interface=BR-WiFi-Priv network=192.168.90.0
add address=192.168.96.1/24 interface=BR-WiFi-Guest network=192.168.96.0
/ip dhcp-server network
add address=192.168.90.0/24 dns-server=8.8.8.8,8.8.4.4 domain=agrotech.lab \
    gateway=192.168.90.1
add address=192.168.96.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=192.168.96.1
/ip dns
set allow-remote-requests=yes cache-size=5000KiB servers=\
    8.8.8.8,8.8.4.4,1.1.1.1
/ip firewall address-list
add address=10.200.1.0/24 comment="Red de Gestion/Enlace" list=LAN-ACCESS
add address=192.168.90.0/24 comment="Red Local Privada" list=LAN-ACCESS
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow LAN/Mgmt access to router" \
    src-address-list=LAN-ACCESS
add action=accept chain=input protocol=icmp
add action=accept chain=input dst-port=53 protocol=udp
add action=accept chain=input dst-port=67-68 protocol=udp
add action=drop chain=input comment="Drop all other input"
add action=accept chain=forward connection-state=established,related
add action=accept chain=forward comment="VLAN 90 to anywhere (WAN/Transit)" \
    src-address=192.168.90.0/24
add action=drop chain=forward comment="Guest WiFi Isolation" dst-address=\
    192.168.0.0/16 src-address=192.168.96.0/24
add action=accept chain=forward comment="Allow all other transit/WAN"
/ip firewall nat
add action=masquerade chain=srcnat comment=\
    "NAT for WAN access if required, or for local L3 traffic" out-interface=\
    ether3
/ip route
add comment="Default route to MK01" distance=1 gateway=10.200.1.1
add comment="Ruta a MK01" distance=1 gateway=10.200.1.1
/snmp
set contact=laboratorio@universidad.edu enabled=yes location=\
    "Lab - Casa Campo Magdalena"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=agrotech-ca-ap
/system logging
add topics=wireless,info
add topics=system,error,critical
/system ntp client
set enabled=yes primary-ntp=200.16.204.10 secondary-ntp=200.16.204.20
