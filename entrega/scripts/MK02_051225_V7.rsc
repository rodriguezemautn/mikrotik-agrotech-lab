# jan/01/1970 22:39:22 by RouterOS 6.49.19
# software id = ZFXZ-LQ9Z
#
# model = 951Ui-2HnD
# serial number = 4AC902473E00
/interface bridge
add comment="Bridge para puertos locales opcionales" name=BR-LOCAL-OPTIONAL \
    protocol-mode=none vlan-filtering=yes
add comment="Bridge acceso gestin local - ether3 untagged VLAN 999" name=\
    BR-MGMT-ACCESS protocol-mode=none vlan-filtering=yes
add comment="Une VLAN 999 transporte con VLAN 999 acceso local" name=\
    BR-MGMT-UNION protocol-mode=none
add name=BR-TRANSPORT protocol-mode=none
add comment="Une VLAN 10" name=BR-VLAN10-UNION protocol-mode=none
add comment="Une VLAN 20" name=BR-VLAN20-UNION protocol-mode=none
add comment="Une VLAN 90" name=BR-VLAN90-UNION protocol-mode=none
add comment="Une VLAN 96" name=BR-VLAN96-UNION protocol-mode=none
add comment="Une VLAN 201" name=BR-VLAN201-UNION protocol-mode=none
/interface ethernet
set [ find default-name=ether1 ] comment=\
    "Trunk to SXT-MG (enlace PTP 8km) - Transporta C-VLANs tagged" l2mtu=1600 \
    mtu=1590 name=ether1-to-sxt
set [ find default-name=ether2 ] comment=\
    "ISP Q-in-Q Trunk from MK01 - Recibe S-VLAN 4000" l2mtu=1600 mtu=1590 \
    name=ether2-isp
set [ find default-name=ether3 ] comment=\
    "Management Access - VLAN 999 Untagged" l2mtu=1600 name=ether3-mgmt
set [ find default-name=ether4 ] comment=\
    "Puerto local opcional - Trunk VLANs" l2mtu=1600 name=ether4-local
set [ find default-name=ether5 ] comment=\
    "Puerto local opcional - Trunk VLANs" l2mtu=1600 name=ether5-local
/interface wireless
set [ find default-name=wlan1 ] comment="Reservado para AP local futuro" \
    ssid=MK02-Reserved
/interface wireless manual-tx-power-table
set wlan1 comment="Reservado para AP local futuro"
/interface wireless nstreme
set wlan1 comment="Reservado para AP local futuro"
/interface vlan
add comment="S-VLAN 4000 - Desencapsula Q-in-Q, C-VLANs pasan intactas" \
    interface=ether2-isp mtu=1590 name=s-vlan-4000-transport vlan-id=4000
add comment="VLAN 10 local" interface=BR-LOCAL-OPTIONAL name=vlan10-local \
    vlan-id=10
add comment="VLAN 20 local" interface=BR-LOCAL-OPTIONAL name=vlan20-local \
    vlan-id=20
add comment="VLAN 90 local" interface=BR-LOCAL-OPTIONAL name=vlan90-local \
    vlan-id=90
add comment="VLAN 96 local" interface=BR-LOCAL-OPTIONAL name=vlan96-local \
    vlan-id=96
add comment="VLAN 201 local" interface=BR-LOCAL-OPTIONAL name=vlan201-local \
    vlan-id=201
add comment="VLAN 999 desde bridge de acceso local" interface=BR-MGMT-ACCESS \
    name=vlan999-access vlan-id=999
add comment="VLAN 999 local" interface=BR-LOCAL-OPTIONAL name=vlan999-local \
    vlan-id=999
add interface=BR-TRANSPORT name=vlan999-transport vlan-id=999
/interface list
add comment="Interfaces de gestin" name=MGMT
add comment="Interfaces LAN" name=LAN
add comment="Interfaces WAN/Uplink" name=WAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/snmp community
set [ find default=yes ] addresses=10.200.1.0/24 name=agrotech-snmp
/interface bridge port
add bridge=BR-MGMT-ACCESS comment="Puerto gestin - VLAN 999 untagged" \
    frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes \
    interface=ether3-mgmt pvid=999
add bridge=BR-MGMT-UNION comment="VLAN 999 desde acceso local ether3" \
    interface=vlan999-access
add bridge=BR-LOCAL-OPTIONAL comment="Puerto local 4 - Trunk todas las VLANs" \
    interface=ether4-local
add bridge=BR-LOCAL-OPTIONAL comment="Puerto local 5 - Trunk todas las VLANs" \
    interface=ether5-local
add bridge=BR-VLAN10-UNION interface=vlan10-local
add bridge=BR-VLAN20-UNION interface=vlan20-local
add bridge=BR-VLAN90-UNION interface=vlan90-local
add bridge=BR-VLAN96-UNION interface=vlan96-local
add bridge=BR-VLAN201-UNION interface=vlan201-local
add bridge=BR-MGMT-UNION comment="VLAN 999 desde puertos locales" interface=\
    vlan999-local
add bridge=BR-TRANSPORT interface=ether1-to-sxt
add bridge=BR-MGMT-UNION interface=vlan999-transport
add bridge=BR-TRANSPORT comment="Trunk directo desde MK01" interface=\
    ether2-isp
/interface bridge vlan
add bridge=BR-MGMT-ACCESS tagged=BR-MGMT-ACCESS untagged=ether3-mgmt \
    vlan-ids=999
add bridge=BR-LOCAL-OPTIONAL tagged=\
    BR-LOCAL-OPTIONAL,ether4-local,ether5-local vlan-ids=10
add bridge=BR-LOCAL-OPTIONAL tagged=\
    BR-LOCAL-OPTIONAL,ether4-local,ether5-local vlan-ids=20
add bridge=BR-LOCAL-OPTIONAL tagged=\
    BR-LOCAL-OPTIONAL,ether4-local,ether5-local vlan-ids=90
add bridge=BR-LOCAL-OPTIONAL tagged=\
    BR-LOCAL-OPTIONAL,ether4-local,ether5-local vlan-ids=96
add bridge=BR-LOCAL-OPTIONAL tagged=\
    BR-LOCAL-OPTIONAL,ether4-local,ether5-local vlan-ids=201
add bridge=BR-LOCAL-OPTIONAL tagged=\
    BR-LOCAL-OPTIONAL,ether4-local,ether5-local vlan-ids=999
/interface list member
add interface=ether3-mgmt list=MGMT
add interface=BR-MGMT-UNION list=MGMT
add interface=ether1-to-sxt list=WAN
add interface=ether2-isp list=WAN
/ip address
add address=10.200.1.10/24 comment="IP de Gestin MK02 - VLAN 999" interface=\
    BR-MGMT-UNION network=10.200.1.0
/ip dns
set servers=10.200.1.1,8.8.8.8
/ip firewall filter
add action=accept chain=input comment="01-INPUT: Accept established/related" \
    connection-state=established,related
add action=drop chain=input comment="02-INPUT: Drop invalid" \
    connection-state=invalid
add action=accept chain=input comment="03-INPUT: Accept ICMP Echo Request" \
    icmp-options=8:0 protocol=icmp
add action=accept chain=input comment=\
    "04-INPUT: Accept from Management VLAN 999" src-address=10.200.1.0/24
add action=accept chain=input comment="05-INPUT: Accept from Corporate VLANs" \
    src-address=192.168.0.0/16
add action=log chain=input comment="06-INPUT: Log dropped packets" \
    log-prefix="DROP-INPUT-MK02: "
add action=drop chain=input comment="07-INPUT: Drop all other"
add action=accept chain=forward comment=\
    "01-FORWARD: Accept established/related" connection-state=\
    established,related
add action=drop chain=forward comment="02-FORWARD: Drop invalid" \
    connection-state=invalid
add action=accept chain=forward comment=\
    "03-FORWARD: Accept all (L2 transparent bridge)"
/ip firewall mangle
add action=change-mss chain=forward comment="MSS Clamp for Q-in-Q MTU (1590)" \
    new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn
add action=change-mss chain=postrouting comment="MSS Clamp postrouting" \
    new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn
/ip route
add comment="Default route via MK01" distance=1 gateway=10.200.1.1
add comment="VLAN 10 - Servers via MK01" distance=1 dst-address=\
    192.168.10.0/24 gateway=10.200.1.1
add comment="VLAN 20 - Desktop via MK01" distance=1 dst-address=\
    192.168.20.0/24 gateway=10.200.1.1
add comment="VLAN 90 - Private WiFi via MK01" distance=1 dst-address=\
    192.168.90.0/24 gateway=10.200.1.1
add comment="VLAN 96 - Guest WiFi via MK01" distance=1 dst-address=\
    192.168.96.0/24 gateway=10.200.1.1
add comment="VLAN 201 - CCTV via MK01" distance=1 dst-address=\
    192.168.201.0/24 gateway=10.200.1.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/snmp
set contact=protocolosinlambrica@gmail.com enabled=yes location=\
    "Magdalena Ciudad - Hub Q-in-Q Desencapsulador" trap-version=2
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK02-agrotech-mg-ap
/system logging
add prefix=MK02 topics=error,critical,warning
add prefix=MK02-IF topics=interface
add prefix=MK02-BR topics=bridge
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system scheduler
add comment="Backup diario automtico a las 03:15" interval=1d name=\
    auto-backup on-event="/system backup save name=(\"MK02-auto-\" . [:pick [/\
    system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pi\
    ck [/system clock get date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=03:15:00
add comment="Export diario automtico a las 03:20" interval=1d name=\
    export-backup on-event="/export file=(\"MK02-export-\" . [:pick [/system c\
    lock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/sys\
    tem clock get date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=03:20:00
add comment="Test de conectividad cada hora" interval=1h name=\
    hourly-connectivity-check on-event=\
    "/system script run ping-topology-test" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add comment="Verificacin completa diaria a las 6 AM" interval=1d name=\
    daily-full-check on-event="/system script run check-bridges; /system scrip\
    t run check-qinq-transport" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=06:00:00
/system script
add comment="Verificar estado de transporte Q-in-Q" dont-require-permissions=\
    no name=check-qinq-transport owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:log info \"==========================================\"\
    \n:log info \"=== MK02 Q-in-Q TRANSPORT STATUS CHECK ===\"\
    \n:log info \"==========================================\"\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 1. Estado de interfaces fisicas:\"\
    \n:local eth1 [/interface ethernet get ether1-to-sxt]\
    \n:local eth2 [/interface ethernet get ether2-isp]\
    \n:log info (\"ether1-to-sxt running: \" . [/interface get ether1-to-sxt r\
    unning])\
    \n:log info (\"ether2-isp running: \" . [/interface get ether2-isp running\
    ])\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 2. Estado S-VLAN 4000:\"\
    \n:log info (\"s-vlan-4000-transport running: \" . [/interface get s-vlan-\
    4000-transport running])\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 3. Estadisticas de interfaces:\"\
    \n/interface print stats where name~\"ether1|ether2|s-vlan-4000|BR-TRANSPO\
    RT\"\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 4. Bridge ports:\"\
    \n/interface bridge port print where bridge=BR-TRANSPORT\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 5. MAC addresses en bridge:\"\
    \n/interface bridge host print where bridge=BR-TRANSPORT\
    \n\
    \n:log info \"\"\
    \n:log info \"=== FIN CHECK ===\"\
    \n"
add comment="Test de conectividad a toda la topologa" \
    dont-require-permissions=no name=ping-topology-test owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:log info \"==========================================\"\
    \n:log info \"=== MK02 TOPOLOGY CONNECTIVITY TEST ===\"\
    \n:log info \"==========================================\"\
    \n\
    \n:local targets {\
    \n    \"10.200.1.1\"=\"MK01-Gateway\";\
    \n    \"10.200.1.50\"=\"SXT-MG-PTP-AP\";\
    \n    \"10.200.1.51\"=\"SXT-CA-PTP-Station\";\
    \n    \"10.200.1.20\"=\"MK03-Campo-GW\";\
    \n    \"10.200.1.21\"=\"MK04-Centro-Datos\";\
    \n    \"10.200.1.22\"=\"MK05-Galpon\";\
    \n    \"10.200.1.25\"=\"MK06-AP-Extra\"\
    \n}\
    \n\
    \n:foreach ip,name in=\$targets do={\
    \n    :local result [/ping \$ip count=3]\
    \n    :if (\$result > 0) do={\
    \n        :log info (\"OK   - \$name (\$ip) - \$result/3 respuestas\")\
    \n    } else={\
    \n        :log error (\"FAIL - \$name (\$ip) - Sin respuesta\")\
    \n    }\
    \n}\
    \n\
    \n:log info \"\"\
    \n:log info \"=== FIN TEST ===\"\
    \n"
add comment="Verificar estado de todos los bridges" dont-require-permissions=\
    no name=check-bridges owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:log info \"==========================================\"\
    \n:log info \"=== MK02 BRIDGE STATUS CHECK ===\"\
    \n:log info \"==========================================\"\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 1. Lista de Bridges:\"\
    \n/interface bridge print\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 2. Bridge Ports:\"\
    \n/interface bridge port print\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 3. Interfaces VLAN:\"\
    \n/interface vlan print\
    \n\
    \n:log info \"\"\
    \n:log info \">>> 4. MACs aprendidas en BR-TRANSPORT:\"\
    \n/interface bridge host print where bridge=BR-TRANSPORT\
    \n\
    \n:log info \"\"\
    \n:log info \"=== FIN CHECK ===\"\
    \n"
add comment="Diagnstico rpido del equipo" dont-require-permissions=no name=\
    quick-diag owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:log info \"=== QUICK DIAG MK02 ===\"\
    \n:log info (\"Uptime: \" . [/system resource get uptime])\
    \n:log info (\"CPU: \" . [/system resource get cpu-load] . \"%\")\
    \n:log info (\"Memory: \" . ([/system resource get free-memory] / 1048576)\
    \_. \"MB free\")\
    \n\
    \n:local pingMK01 [/ping 10.200.1.1 count=1]\
    \n:local pingSXT [/ping 10.200.1.50 count=1]\
    \n:local pingMK03 [/ping 10.200.1.20 count=1]\
    \n\
    \n:log info (\"MK01: \" . [:pick (\"FAIL\"\"OK  \") (\$pingMK01 * 4) ((\$p\
    ingMK01 * 4) + 4)])\
    \n:log info (\"SXT-MG: \" . [:pick (\"FAIL\"\"OK  \") (\$pingSXT * 4) ((\$\
    pingSXT * 4) + 4)])\
    \n:log info (\"MK03: \" . [:pick (\"FAIL\"\"OK  \") (\$pingMK03 * 4) ((\$p\
    ingMK03 * 4) + 4)])\
    \n:log info \"=== END ===\"\
    \n"
add comment="Muestra trfico en interfaces principales" \
    dont-require-permissions=no name=traffic-monitor owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:log info \"=== TRAFFIC MONITOR ===\"\
    \n:log info \"\"\
    \n\
    \n:local interfaces {\"ether1-to-sxt\";\"ether2-isp\";\"s-vlan-4000-transp\
    ort\";\"BR-TRANSPORT\"}\
    \n\
    \n:foreach iface in=\$interfaces do={\
    \n    :local stats [/interface get \$iface]\
    \n    :local rx [/interface get \$iface rx-byte]\
    \n    :local tx [/interface get \$iface tx-byte]\
    \n    :log info (\"\$iface: RX=\" . (\$rx / 1048576) . \"MB TX=\" . (\$tx \
    / 1048576) . \"MB\")\
    \n}\
    \n\
    \n:log info \"\"\
    \n:log info \"=== END ===\"\
    \n"
/tool bandwidth-server
set max-sessions=5
/tool graphing interface
add interface=ether1-to-sxt
add interface=ether2-isp
add interface=s-vlan-4000-transport
/tool graphing resource
add
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
