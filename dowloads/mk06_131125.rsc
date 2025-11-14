# jan/02/1970 20:52:16 by RouterOS 6.44.3
# software id = GCUB-ETCR
#
# model = 951Ui-2HnD
# serial number = 6433050CA0B0
/interface bridge
add name=BR-CAMPO vlan-filtering=yes
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=PtMP-Secure \
    supplicant-identity=agrotech-ap-extra wpa2-pre-shared-key=\
    AgroTechWDS_2025!
add authentication-types=wpa2-psk mode=dynamic-keys name=WiFi-Priv-Profile \
    supplicant-identity=agrotech-ap-extra wpa2-pre-shared-key=\
    AgroTechWiFi90_2025!
add authentication-types=wpa2-psk mode=dynamic-keys name=WiFi-Guest-Profile \
    supplicant-identity=agrotech-ap-extra wpa2-pre-shared-key=\
    GuestWiFi96_2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n country=argentina disabled=no \
    frequency=2462 mode=station-bridge scan-list=2462 security-profile=\
    PtMP-Secure ssid=AGROTECH-CAMPO-PTMP wireless-protocol=nv2
add disabled=no mac-address=4E:5E:0C:31:71:D1 master-interface=wlan1 name=\
    wlan-guest security-profile=WiFi-Guest-Profile ssid=AgroTech-Guest-Extra
add disabled=no mac-address=4E:5E:0C:31:71:D0 master-interface=wlan1 name=\
    wlan-priv security-profile=WiFi-Priv-Profile ssid=AgroTech-Extra
/interface bridge port
add bridge=BR-CAMPO comment="Uplink PtMP Trunk (Tagged)" interface=wlan1
add bridge=BR-CAMPO comment="Puerto Downstream Trunk (Tagged)" interface=\
    ether2
add bridge=BR-CAMPO comment="AP Privado (PVID 90)" interface=wlan-priv pvid=\
    90
add bridge=BR-CAMPO comment="AP Invitados (PVID 96)" interface=wlan-guest \
    pvid=96
/interface bridge vlan
add bridge=BR-CAMPO tagged=wlan1,ether2 untagged=wlan-priv vlan-ids=90
add bridge=BR-CAMPO tagged=wlan1,ether2 untagged=wlan-guest vlan-ids=96
add bridge=BR-CAMPO tagged=wlan1,ether2 vlan-ids=10,20,201
/ip address
add address=10.200.1.25/24 comment="IP de Gestion Segregada" interface=ether3 \
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
    "Lab - AP Extra Campo"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=agrotech-ap-extra
/system ntp client
set enabled=yes primary-ntp=10.200.1.1
