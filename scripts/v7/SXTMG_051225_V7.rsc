# jan/12/1970 05:57:54 by RouterOS 6.49.19
# software id = QRX6-0SS9
#
# model = SXT G-2HnD
# serial number = 5A9505C44A45
/interface bridge
add comment="Bridge L2 transparente para PtP" name=BR-PTP protocol-mode=none \
    vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] comment="Trunk to MK02" mtu=1590 name=\
    ether1-trunk
/interface vlan
add comment="Management VLAN" interface=BR-PTP name=vlan999-mgmt vlan-id=999
/interface list
add name=MGMT
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk comment="PtP Link Security - 8km" mode=\
    dynamic-keys name=ptp-secure supplicant-identity=MikroTik \
    wpa2-pre-shared-key=PtP.Magdalena.Campo.2025!Secure
/interface wireless
set [ find default-name=wlan1 ] adaptive-noise-immunity=ap-and-client-mode \
    band=2ghz-b/g/n comment="PtP AP to SXT-CA (8km)" country=argentina \
    default-forwarding=no disabled=no distance=8000 frequency=2437 hide-ssid=\
    yes mode=ap-bridge scan-list=2437 security-profile=ptp-secure ssid=\
    Agrotech-PTP-MG-CA tx-power-mode=all-rates-fixed wds-default-bridge=\
    BR-PTP wds-mode=static wireless-protocol=nv2 wps-mode=disabled
/interface wireless manual-tx-power-table
set wlan1 comment="PtP AP to SXT-CA (8km)"
/interface wireless nstreme
set wlan1 comment="PtP AP to SXT-CA (8km)"
/interface bridge port
add bridge=BR-PTP comment="Trunk to MK02 - All VLANs" interface=ether1-trunk
add bridge=BR-PTP comment="PtP RF Link - All VLANs" interface=wlan1
/interface bridge vlan
add bridge=BR-PTP tagged=BR-PTP,ether1-trunk,wlan1 vlan-ids=10
add bridge=BR-PTP tagged=BR-PTP,ether1-trunk,wlan1 vlan-ids=20
add bridge=BR-PTP tagged=BR-PTP,ether1-trunk,wlan1 vlan-ids=90
add bridge=BR-PTP tagged=BR-PTP,ether1-trunk,wlan1 vlan-ids=96
add bridge=BR-PTP tagged=BR-PTP,ether1-trunk,wlan1 vlan-ids=201
add bridge=BR-PTP tagged=BR-PTP,ether1-trunk,wlan1 vlan-ids=999
/interface list member
add interface=vlan999-mgmt list=MGMT
/ip address
add address=10.200.1.50/24 comment="Management IP" interface=vlan999-mgmt \
    network=10.200.1.0
/ip dhcp-client
# DHCP client can not run on slave interface!
add comment=WAN disabled=no interface=ether1-trunk
/ip dns
set servers=10.200.1.1
/ip firewall filter
add action=accept chain=input comment="Accept established/related" \
    connection-state=established,related
add action=accept chain=input comment="Accept ICMP" icmp-options=8:0 \
    protocol=icmp
add action=accept chain=input comment="Accept from Management VLAN" \
    src-address=10.200.1.0/24
add action=log chain=input log-prefix="DROP-SXT-MG: "
add action=drop chain=input comment="Drop all other input"
add action=accept chain=forward connection-state=established,related
add action=drop chain=forward connection-state=invalid
add action=accept chain=forward comment="Accept all forward (L2 bridge)"
/ip firewall mangle
add action=change-mss chain=forward comment="MSS Clamp for PtP link" new-mss=\
    clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn
/ip route
add comment="Default route to MK01" distance=1 gateway=10.200.1.1
add comment="Corporate networks via MK01" distance=1 dst-address=\
    192.168.0.0/16 gateway=10.200.1.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/snmp
set contact=laboratorio@agrotech.local enabled=yes location=\
    "Magdalena - PtP AP (8km to Campo)"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=SXT-MG-PTP-AP
/system logging
add prefix=SXT-MG topics=wireless,error,critical
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system script
add comment="Verificar estado del enlace PtP" dont-require-permissions=no \
    name=check-ptp-status owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== PtP Link Status ===\"\
    \n        /interface wireless print\
    \n        :log info \"Registration Table:\"\
    \n        /interface wireless registration-table print detail\
    \n        :log info \"Link Stats:\"\
    \n        /interface wireless monitor wlan1 once\
    \n        :log info \"=== End Check ===\"\
    \n    "
add comment="Verificar seal y velocidad" dont-require-permissions=no name=\
    check-signal owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Signal Check ===\"\
    \n        :local reg [/interface wireless registration-table find]\
    \n        :if ([:len \$reg] > 0) do={\
    \n            :foreach i in=\$reg do={\
    \n                :local mac [/interface wireless registration-table get \
    \$i mac-address]\
    \n                :local signal [/interface wireless registration-table ge\
    t \$i signal-strength]\
    \n                :local txrate [/interface wireless registration-table ge\
    t \$i tx-rate]\
    \n                :local rxrate [/interface wireless registration-table ge\
    t \$i rx-rate]\
    \n                :log info (\"Client: \" . \$mac)\
    \n                :log info (\"Signal: \" . \$signal . \" dBm\")\
    \n                :log info (\"TX Rate: \" . \$txrate . \" Mbps\")\
    \n                :log info (\"RX Rate: \" . \$rxrate . \" Mbps\")\
    \n            }\
    \n        } else={\
    \n            :log warning \"No clients registered!\"\
    \n        }\
    \n        :log info \"=== End Check ===\"\
    \n    "
add comment="Test de throughput al SXT-CA" dont-require-permissions=no name=\
    check-throughput owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Throughput Test ===\"\
    \n        :log info \"Running bandwidth test to SXT-CA...\"\
    \n        :log info \"IP: 10.200.1.51\"\
    \n        # Descomentar cuando SXT-CA est operativo\
    \n        # /tool bandwidth-test 10.200.1.51 duration=10s protocol=tcp\
    \n        :log info \"=== End Test ===\"\
    \n    "
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
