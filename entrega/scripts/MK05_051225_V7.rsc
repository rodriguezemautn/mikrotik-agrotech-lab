# jan/15/1970 05:53:43 by RouterOS 6.49.19
# software id = UXS0-IHTB
#
# model = 951Ui-2HnD
# serial number = 4AC904BA91D8
/interface bridge
add comment="Bridge Station PTMP" name=BR-CAMPO vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] l2mtu=1600 name=ether1-spare
set [ find default-name=ether2 ] l2mtu=1600 name=ether2-spare
set [ find default-name=ether3 ] comment=Management l2mtu=1600 name=\
    ether3-mgmt
set [ find default-name=ether4 ] comment="Desktop - VLAN 20" l2mtu=1600 name=\
    ether4-desktop
set [ find default-name=ether5 ] comment="CCTV - VLAN 201" l2mtu=1600 name=\
    ether5-cctv
/interface vlan
add interface=BR-CAMPO name=vlan999-mgmt vlan-id=999
/interface list
add name=MGMT
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=ptmp-campo \
    supplicant-identity=MikroTik wpa2-pre-shared-key=\
    PtMP.Campo.AgroTech.2025!Secure
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n comment=\
    "PTMP Station to MK03" country=argentina disabled=no distance=indoors \
    frequency=2462 mode=station-bridge security-profile=ptmp-campo ssid=\
    Agrotech-PTMP-Campo wds-default-bridge=BR-CAMPO wds-mode=dynamic \
    wireless-protocol=nv2 wps-mode=disabled
/interface wireless manual-tx-power-table
set wlan1 comment="PTMP Station to MK03"
/interface wireless nstreme
set wlan1 comment="PTMP Station to MK03"
/interface bridge port
add bridge=BR-CAMPO interface=wlan1
add bridge=BR-CAMPO frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes interface=ether3-mgmt pvid=999
add bridge=BR-CAMPO frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes interface=ether4-desktop pvid=20
add bridge=BR-CAMPO frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes interface=ether5-cctv pvid=201
/interface bridge vlan
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 vlan-ids=10
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 untagged=ether4-desktop vlan-ids=20
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 vlan-ids=90
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 vlan-ids=96
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 untagged=ether5-cctv vlan-ids=201
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 untagged=ether3-mgmt vlan-ids=999
/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-mgmt list=MGMT
/ip address
add address=10.200.1.22/24 interface=vlan999-mgmt network=10.200.1.0
/ip dns
set servers=10.200.1.1
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input icmp-options=8:0 protocol=icmp
add action=accept chain=input src-address=10.200.1.0/24
add action=accept chain=input src-address=192.168.0.0/16
add action=log chain=input log-prefix="DROP-MK05: "
add action=drop chain=input
add action=accept chain=forward connection-state=established,related
add action=drop chain=forward connection-state=invalid
add action=drop chain=forward comment="Guest isolation" dst-address=\
    192.168.0.0/16 src-address=192.168.96.0/24
add action=accept chain=forward
/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes \
    protocol=tcp tcp-flags=syn
/ip route
add distance=1 gateway=10.200.1.1
add distance=1 dst-address=192.168.0.0/16 gateway=10.200.1.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/snmp
set contact=protocolosinlambrica@gmail.com enabled=yes location=\
    "Campo - Galpon/Corrales/Tambo"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK05-agrotech-cc-st
/system logging
add prefix=MK05 topics=wireless,error,critical
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system scheduler
add interval=1d name=auto-backup on-event="/system backup save name=(\"MK05-au\
    to-\" . [:pick [/system clock get date] 7 11] . [:pick [/system clock get \
    date] 0 3] . [:pick [/system clock get date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=04:00:00
/system script
add dont-require-permissions=no name=check-connection owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== MK05 Connection Status ===\"\
    \n        /interface wireless monitor wlan1 once\
    \n        /ping 10.200.1.20 count=5\
    \n        :log info \"=== End Check ===\"\
    \n    "
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
