# jan/01/1970 22:08:19 by RouterOS 6.49.19
# software id = ZFXZ-LQ9Z
#
# model = 951Ui-2HnD
# serial number = 4AC902473E00
/interface bridge
add comment="Bridge L2 para transporte transparente de VLANs" name=\
    BR-TRANSPORT vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] comment="Trunk to SXT-MG via CABLE" l2mtu=\
    1600 mtu=1590 name=ether1-to-sxt
set [ find default-name=ether2 ] comment="ISP Q-in-Q Trunk from MK01" l2mtu=\
    1600 mtu=1590 name=ether2-isp
set [ find default-name=ether3 ] comment="Management Access" l2mtu=1600 name=\
    ether3-mgmt
set [ find default-name=ether4 ] comment="Local Trunk opcional" l2mtu=1600 \
    name=ether4-local
set [ find default-name=ether5 ] comment="Local Trunk opcional" l2mtu=1600 \
    name=ether5-local
/interface wireless
set [ find default-name=wlan1 ] comment="Disponible para AP local futuro" \
    ssid=MikroTik
/interface wireless manual-tx-power-table
set wlan1 comment="Disponible para AP local futuro"
/interface wireless nstreme
set wlan1 comment="Disponible para AP local futuro"
/interface vlan
add comment="S-VLAN 4000 - Recepcion desde ISP (Service Tag)" interface=\
    ether2-isp mtu=1590 name=s-vlan-4000-in vlan-id=4000
add comment="C-VLAN 10 - Extraida de Q-in-Q" interface=s-vlan-4000-in mtu=\
    1580 name=vlan10-extracted vlan-id=10
add comment="C-VLAN 20 - Extraida de Q-in-Q" interface=s-vlan-4000-in mtu=\
    1580 name=vlan20-extracted vlan-id=20
add comment="C-VLAN 90 - Extraida de Q-in-Q" interface=s-vlan-4000-in mtu=\
    1580 name=vlan90-extracted vlan-id=90
add comment="C-VLAN 96 - Extraida de Q-in-Q" interface=s-vlan-4000-in mtu=\
    1580 name=vlan96-extracted vlan-id=96
add comment="C-VLAN 201 - Extraida de Q-in-Q" interface=s-vlan-4000-in mtu=\
    1580 name=vlan201-extracted vlan-id=201
add comment="C-VLAN 999 - Extraida de Q-in-Q" interface=s-vlan-4000-in mtu=\
    1580 name=vlan999-extracted vlan-id=999
/interface list
add comment="Management interfaces" name=MGMT
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=BR-TRANSPORT comment="C-VLAN 10 desencapsulada" interface=\
    vlan10-extracted
add bridge=BR-TRANSPORT comment="C-VLAN 20 desencapsulada" interface=\
    vlan20-extracted
add bridge=BR-TRANSPORT comment="C-VLAN 90 desencapsulada" interface=\
    vlan90-extracted
add bridge=BR-TRANSPORT comment="C-VLAN 96 desencapsulada" interface=\
    vlan96-extracted
add bridge=BR-TRANSPORT comment="C-VLAN 201 desencapsulada" interface=\
    vlan201-extracted
add bridge=BR-TRANSPORT comment="Trunk to SXT-MG via CABLE - All VLANs" \
    interface=ether1-to-sxt
add bridge=BR-TRANSPORT comment="Management Access - VLAN 999 Untagged" \
    frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes \
    interface=ether3-mgmt pvid=999
add bridge=BR-TRANSPORT comment="Local Trunk opcional - All VLANs" interface=\
    ether4-local
add bridge=BR-TRANSPORT comment="Local Trunk opcional - All VLANs" interface=\
    ether5-local
add bridge=BR-TRANSPORT comment="C-VLAN 999 desencapsulada" interface=\
    vlan999-extracted
/interface bridge vlan
add bridge=BR-TRANSPORT tagged=\
    BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local vlan-ids=10
add bridge=BR-TRANSPORT tagged=\
    BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local vlan-ids=20
add bridge=BR-TRANSPORT tagged=\
    BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local vlan-ids=90
add bridge=BR-TRANSPORT tagged=\
    BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local vlan-ids=96
add bridge=BR-TRANSPORT tagged=\
    BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local vlan-ids=201
add bridge=BR-TRANSPORT tagged=BR-TRANSPORT,ether1-to-sxt,vlan999-extracted \
    untagged=ether3-mgmt vlan-ids=999
/interface list member
add interface=ether3-mgmt list=MGMT
add list=MGMT
/ip address
add address=10.200.1.10/24 comment="Management IP - VLAN 999 via Q-in-Q" \
    interface=vlan999-extracted network=10.200.1.0
/ip dns
set servers=10.200.1.1
/ip firewall filter
add action=accept chain=input comment="01-INPUT: Accept established/related" \
    connection-state=established,related
add action=accept chain=input comment="02-INPUT: Accept ICMP" icmp-options=\
    8:0 protocol=icmp
add action=accept chain=input comment="03-INPUT: Accept from Management" \
    src-address=10.200.1.0/24
add action=log chain=input comment="04-INPUT: Log dropped" log-prefix=\
    "DROP-INPUT-MK02: "
add action=drop chain=input comment="05-INPUT: Drop all other"
add action=accept chain=forward comment=\
    "01-FORWARD: Accept established/related" connection-state=\
    established,related
add action=drop chain=forward comment="02-FORWARD: Drop invalid" \
    connection-state=invalid
add action=accept chain=forward comment="03-FORWARD: Accept all (L2 bridge)"
/ip firewall mangle
add action=change-mss chain=forward comment="MSS Clamp for Q-in-Q MTU" \
    new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn
/ip route
add comment="Default route to MK01" distance=1 gateway=10.200.1.1
add comment="Route to VLAN 10 via MK01" distance=1 dst-address=\
    192.168.10.0/24 gateway=10.200.1.1
add comment="Route to VLAN 20 via MK01" distance=1 dst-address=\
    192.168.20.0/24 gateway=10.200.1.1
add comment="Route to VLAN 90 via MK01" distance=1 dst-address=\
    192.168.90.0/24 gateway=10.200.1.1
add comment="Route to VLAN 96 via MK01" distance=1 dst-address=\
    192.168.96.0/24 gateway=10.200.1.1
add comment="Route to VLAN 201 via MK01" distance=1 dst-address=\
    192.168.201.0/24 gateway=10.200.1.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/snmp
set contact=protocolosinlambrica@gmail.com enabled=yes location=\
    "Magdalena - Hub Desencapsulador Q-in-Q" trap-version=2
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK02-agrotech-mg-ap
/system logging
add prefix=MK02 topics=error,critical,warning
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system scheduler
add comment="Backup diario automatico" interval=1d name=auto-backup on-event="\
    /system backup save name=(\"MK02-auto-\" . [:pick [/system clock get date]\
    \_7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get\
    \_date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=03:15:00
/system script
add comment="Verificar desencapsulacion Q-in-Q" dont-require-permissions=no \
    name=check-qinq-decap owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Q-in-Q Decapsulation Status ===\"\
    \n        :log info \"S-VLAN 4000 Input:\"\
    \n        /interface print stats where name=\"s-vlan-4000-in\"\
    \n        :log info \"Extracted C-VLANs:\"\
    \n        /interface print stats where name~\"extracted\"\
    \n        :log info \"=== End Check ===\"\
    \n    "
add comment="Verificar trunk por cable a SXT-MG" dont-require-permissions=no \
    name=check-trunk-sxt owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Trunk to SXT-MG Status ===\"\
    \n        :log info \"ether1-to-sxt stats:\"\
    \n        /interface print stats where name=\"ether1-to-sxt\"\
    \n        :log info \"Bridge VLAN stats:\"\
    \n        /interface bridge vlan print where bridge=BR-TRANSPORT\
    \n        :log info \"=== End Check ===\"\
    \n    "
add comment="Verificar bridge y VLANs" dont-require-permissions=no name=\
    check-bridge owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Bridge Status ===\"\
    \n        /interface bridge print\
    \n        /interface bridge port print\
    \n        /interface bridge vlan print\
    \n        :log info \"=== End Check ===\"\
    \n    "
add comment="Test conectividad a toda la topologia" dont-require-permissions=\
    no name=ping-test-topology owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Connectivity Test ===\"\
    \n        :local targets {\"10.200.1.1\";\"10.200.1.50\";\"10.200.1.51\";\
    \"10.200.1.20\"}\
    \n        :foreach t in=\$targets do={\
    \n            :log info (\"Testing \" . \$t)\
    \n            /ping \$t count=3\
    \n        }\
    \n        :log info \"=== End Test ===\"\
    \n    "
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
