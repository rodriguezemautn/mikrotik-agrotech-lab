# jan/15/1970 11:26:37 by RouterOS 6.49.19
# software id = NNNW-EHRR
#
# model = SXT G-2HnD
# serial number = 41FE02CC65CB
/interface bridge
add comment="Bridge L2 transparente para PtP" name=BR-PTP protocol-mode=none \
    vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] comment="Trunk to MK04" mtu=1590 name=\
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
    band=2ghz-b/g/n comment="PtP Station to SXT-MG (8km)" country=argentina \
    default-forwarding=no disabled=no distance=8000 frequency=2437 mode=\
    station-bridge scan-list=2437 security-profile=ptp-secure ssid=\
    Agrotech-PTP-MG-CA tx-power-mode=all-rates-fixed wds-default-bridge=\
    BR-PTP wds-mode=static wireless-protocol=nv2 wps-mode=disabled
/interface wireless manual-tx-power-table
set wlan1 comment="PtP Station to SXT-MG (8km)"
/interface wireless nstreme
set wlan1 comment="PtP Station to SXT-MG (8km)"
/interface bridge port
add bridge=BR-PTP comment="Trunk to MK04 - All VLANs" interface=ether1-trunk
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
add address=10.200.1.51/24 comment="Management IP" interface=vlan999-mgmt \
    network=10.200.1.0
/ip dns
set servers=10.200.1.1
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input icmp-options=8:0 protocol=icmp
add action=accept chain=input src-address=10.200.1.0/24
add action=log chain=input log-prefix="DROP-SXT-CA: "
add action=drop chain=input
add action=accept chain=forward connection-state=established,related
add action=drop chain=forward connection-state=invalid
add action=accept chain=forward comment="Accept all forward (L2 bridge)"
/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes \
    protocol=tcp tcp-flags=syn
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
    "Campo - PtP Station (8km from Magdalena)"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=SXT-CA-PTP-Station
/system logging
add prefix=SXT-CA topics=wireless,error,critical
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system script
add dont-require-permissions=no name=check-connection-status owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source="\
    \n        :log info \"=== Connection Status to SXT-MG ===\"\
    \n        /interface wireless print\
    \n        :log info \"Monitor:\"\
    \n        /interface wireless monitor wlan1 once\
    \n        :log info \"=== End Check ===\"\
    \n    "
add dont-require-permissions=no name=check-signal owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Signal Quality ===\"\
    \n        :local sig [/interface wireless monitor wlan1 once as-value]\
    \n        :log info (\"SSID: \" . (\$sig->\"ssid\"))\
    \n        :log info (\"Frequency: \" . (\$sig->\"frequency\"))\
    \n        :log info (\"Signal Strength: \" . (\$sig->\"signal-strength\") \
    . \" dBm\")\
    \n        :log info (\"TX CCQ: \" . (\$sig->\"tx-ccq\") . \"%\")\
    \n        :log info (\"Noise Floor: \" . (\$sig->\"noise-floor\") . \" dBm\
    \")\
    \n        :log info (\"TX Rate: \" . (\$sig->\"tx-rate\"))\
    \n        :log info (\"RX Rate: \" . (\$sig->\"rx-rate\"))\
    \n        :log info \"=== End Check ===\"\
    \n    "
add dont-require-permissions=no name=bw-test-to-mg owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Bandwidth Test to SXT-MG ===\"\
    \n        :log info \"Testing to 10.200.1.50...\"\
    \n        /tool bandwidth-test 10.200.1.50 duration=10s protocol=tcp\
    \n        :log info \"=== End Test ===\"\
    \n    "
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
