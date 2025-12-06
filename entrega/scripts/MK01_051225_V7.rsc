# nov/28/2025 03:47:32 by RouterOS 6.49.19
# software id = LLBU-WG2H
#
# model = 951Ui-2HnD
# serial number = 558304337A4F
/interface bridge
add comment="Bridge local para VLANs corporativas" name=BR-LOCAL \
    vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] comment="WAN - Internet" l2mtu=1600 name=\
    ether1-wan
set [ find default-name=ether2 ] comment="ISP Trunk - Q-in-Q Transport" \
    l2mtu=1600 mtu=1590 name=ether2-isp
set [ find default-name=ether3 ] comment="Management Access" l2mtu=1600 name=\
    ether3-mgmt
set [ find default-name=ether4 ] comment="Local Desktop/Servers" l2mtu=1600 \
    name=ether4-local
set [ find default-name=ether5 ] comment="Local CCTV/IoT" l2mtu=1600 name=\
    ether5-local
/interface vlan
add comment="VLAN 10 - Servers (Local La Plata)" interface=BR-LOCAL name=\
    vlan10-local vlan-id=10
add comment="VLAN 20 - Desktop (Local La Plata)" interface=BR-LOCAL name=\
    vlan20-local vlan-id=20
add comment="VLAN 90 - Private WiFi (Local La Plata)" interface=BR-LOCAL \
    name=vlan90-local vlan-id=90
add comment="VLAN 96 - Guest WiFi (Local La Plata)" interface=BR-LOCAL name=\
    vlan96-local vlan-id=96
add comment="VLAN 201 - CCTV (Local La Plata)" interface=BR-LOCAL name=\
    vlan201-local vlan-id=201
add comment="VLAN 999 - Management Network" interface=BR-LOCAL name=\
    vlan999-mgmt vlan-id=999
/interface list
add comment="Management interfaces" name=MGMT
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk comment="VLAN 90 - Red corporativa privada" \
    mode=dynamic-keys name=agrotech-private supplicant-identity=MikroTik \
    wpa2-pre-shared-key=AgroTech.Secure.Private.2025!
add authentication-types=wpa2-psk comment="VLAN 96 - Red invitados" mode=\
    dynamic-keys name=agrotech-guest supplicant-identity=MikroTik \
    wpa2-pre-shared-key=AgroTech.Guest.2025!
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n comment=\
    "AP Local Oficina La Plata" country=argentina disabled=no frequency=auto \
    mode=ap-bridge security-profile=agrotech-private ssid=Agrotech-Office-LP \
    wps-mode=disabled
/interface wireless manual-tx-power-table
set wlan1 comment="AP Local Oficina La Plata"
/interface wireless nstreme
set wlan1 comment="AP Local Oficina La Plata"
/ip pool
add comment="Pool VLAN 10 - Servers" name=pool-vlan10 ranges=\
    192.168.10.100-192.168.10.129
add comment="Pool VLAN 20 - Desktop" name=pool-vlan20 ranges=\
    192.168.20.100-192.168.20.129
add comment="Pool VLAN 90 - Private WiFi" name=pool-vlan90 ranges=\
    192.168.90.100-192.168.90.129
add comment="Pool VLAN 96 - Guest WiFi" name=pool-vlan96 ranges=\
    192.168.96.100-192.168.96.129
add comment="Pool VLAN 201 - CCTV" name=pool-vlan201 ranges=\
    192.168.201.100-192.168.201.129
add comment="Pool VLAN 999 - Management" name=pool-vlan999 ranges=\
    10.200.1.10-10.200.1.19
/ip dhcp-server
add address-pool=pool-vlan10 disabled=no interface=vlan10-local lease-time=1h \
    name=dhcp-vlan10
add address-pool=pool-vlan20 disabled=no interface=vlan20-local lease-time=1h \
    name=dhcp-vlan20
add address-pool=pool-vlan90 disabled=no interface=vlan90-local lease-time=8h \
    name=dhcp-vlan90
add address-pool=pool-vlan96 disabled=no interface=vlan96-local lease-time=1h \
    name=dhcp-vlan96
add address-pool=pool-vlan201 disabled=no interface=vlan201-local lease-time=\
    1d name=dhcp-vlan201
add address-pool=pool-vlan10 disabled=no lease-time=1h name=dhcp-qinq-vlan10
add address-pool=pool-vlan20 disabled=no lease-time=1h name=dhcp-qinq-vlan20
add address-pool=pool-vlan90 disabled=no lease-time=8h name=dhcp-qinq-vlan90
add address-pool=pool-vlan96 disabled=no lease-time=1h name=dhcp-qinq-vlan96
add address-pool=pool-vlan201 disabled=no lease-time=1d name=\
    dhcp-qinq-vlan201
add address-pool=pool-vlan999 disabled=no interface=vlan999-mgmt lease-time=\
    1d name=dhcp-vlan999
/interface bridge port
add bridge=BR-LOCAL comment="Management Access - VLAN 999 Untagged" \
    frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes \
    interface=ether3-mgmt pvid=999
add bridge=BR-LOCAL comment="Local Access - VLAN 10 Untagged" frame-types=\
    admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=\
    ether4-local pvid=10
add bridge=BR-LOCAL comment="Local Access - VLAN 201 Untagged" frame-types=\
    admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=\
    ether5-local pvid=201
add bridge=BR-LOCAL comment="AP Local - VLANs 90/96 Tagged" interface=wlan1
add bridge=BR-LOCAL comment="ISP trunk - receives Q-in-Q VLAN 4000" \
    interface=ether2-isp
/interface bridge vlan
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp untagged=ether4-local \
    vlan-ids=10
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp vlan-ids=20
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp vlan-ids=90
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp vlan-ids=96
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp untagged=ether5-local \
    vlan-ids=201
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp untagged=ether3-mgmt vlan-ids=\
    999
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp vlan-ids=4000
/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-mgmt list=MGMT
/ip address
add address=10.200.1.1/24 comment="Management IP - VLAN 999" interface=\
    vlan999-mgmt network=10.200.1.0
add address=192.168.10.1/24 comment="Gateway VLAN 10 - Servers" interface=\
    vlan10-local network=192.168.10.0
add address=192.168.20.1/24 comment="Gateway VLAN 20 - Desktop" interface=\
    vlan20-local network=192.168.20.0
add address=192.168.90.1/24 comment="Gateway VLAN 90 - Private WiFi" \
    interface=vlan90-local network=192.168.90.0
add address=192.168.96.1/24 comment="Gateway VLAN 96 - Guest WiFi" interface=\
    vlan96-local network=192.168.96.0
add address=192.168.201.1/24 comment="Gateway VLAN 201 - CCTV" interface=\
    vlan201-local network=192.168.201.0
add address=192.168.10.1/24 comment="Gateway remoto VLAN 10 via Q-in-Q" \
    network=192.168.10.0
add address=192.168.20.1/24 comment="Gateway remoto VLAN 20 via Q-in-Q" \
    network=192.168.20.0
add address=192.168.90.1/24 comment="Gateway remoto VLAN 90 via Q-in-Q" \
    network=192.168.90.0
add address=192.168.96.1/24 comment="Gateway remoto VLAN 96 via Q-in-Q" \
    network=192.168.96.0
add address=192.168.201.1/24 comment="Gateway remoto VLAN 201 via Q-in-Q" \
    network=192.168.201.0
add address=10.200.1.1/24 comment="Management IP remoto via Q-in-Q" network=\
    10.200.1.0
/ip dhcp-client
add comment=WAN disabled=no interface=ether1-wan
/ip dhcp-server network
add address=10.200.1.0/24 comment="VLAN 999 - Management" dns-server=\
    10.200.1.1 gateway=10.200.1.1
add address=192.168.10.0/24 comment="VLAN 10 - Servers" dns-server=\
    192.168.10.1 gateway=192.168.10.1
add address=192.168.20.0/24 comment="VLAN 20 - Desktop" dns-server=\
    192.168.20.1 gateway=192.168.20.1
add address=192.168.90.0/24 comment="VLAN 90 - Private WiFi" dns-server=\
    192.168.90.1 gateway=192.168.90.1
add address=192.168.96.0/24 comment="VLAN 96 - Guest WiFi" dns-server=\
    192.168.96.1 domain=guest.agrotech.local gateway=192.168.96.1
add address=192.168.201.0/24 comment="VLAN 201 - CCTV" dns-server=\
    192.168.201.1 gateway=192.168.201.1
/ip dns
set allow-remote-requests=yes cache-size=4096KiB servers=8.8.8.8,1.1.1.1
/ip firewall filter
add action=accept chain=input comment="01-INPUT: Accept established/related" \
    connection-state=established,related
add action=accept chain=input comment="02-INPUT: Accept ICMP Echo Request" \
    icmp-options=8:0 protocol=icmp
add action=accept chain=input comment=\
    "03-INPUT: Accept from Management VLAN 999" src-address=10.200.1.0/24
add action=accept chain=input comment="04-INPUT: Accept from Corporate VLANs" \
    src-address=192.168.0.0/16
add action=log chain=input comment="05-INPUT: Log dropped input" log-prefix=\
    "DROP-INPUT: "
add action=drop chain=input comment="06-INPUT: Drop all other input"
add action=accept chain=forward comment=\
    "01-FORWARD: Accept established/related" connection-state=\
    established,related
add action=log chain=forward comment="02-FORWARD: Log invalid connections" \
    connection-state=invalid log-prefix="INVALID-FWD: "
add action=drop chain=forward comment="03-FORWARD: Drop invalid connections" \
    connection-state=invalid
add action=accept chain=forward comment="04-FORWARD: Allow CCTV to Servers" \
    dst-address=192.168.10.0/24 src-address=192.168.201.0/24
add action=accept chain=forward comment="05-FORWARD: Allow Servers to CCTV" \
    dst-address=192.168.201.0/24 src-address=192.168.10.0/24
add action=drop chain=forward comment=\
    "06-FORWARD: Guest isolation - Block to corporate" dst-address=\
    192.168.0.0/16 src-address=192.168.96.0/24
add action=drop chain=forward comment="07-FORWARD: Block corporate to Guest" \
    dst-address=192.168.96.0/24 src-address=192.168.0.0/16
add action=accept chain=forward comment=\
    "08-FORWARD: Allow Guest to Internet only" out-interface=ether1-wan \
    src-address=192.168.96.0/24
add action=drop chain=forward comment="09-FORWARD: Block CCTV to Internet" \
    dst-address=!192.168.0.0/16 src-address=192.168.201.0/24
add action=accept chain=forward comment=\
    "10-FORWARD: Allow inter-VLAN corporate traffic" dst-address=\
    192.168.0.0/16 src-address=192.168.0.0/16
add action=accept chain=forward comment=\
    "11-FORWARD: Allow corporate to Internet" out-interface=ether1-wan \
    src-address=192.168.0.0/16
add action=log chain=forward comment="12-FORWARD: Log dropped forward" \
    log-prefix="DROP-FORWARD: "
add action=drop chain=forward comment="13-FORWARD: Drop all other forward"
/ip firewall mangle
add action=change-mss chain=forward comment="MSS Clamp for Q-in-Q MTU 1590" \
    new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn
# in/out-interface matcher not possible when interface (ether2-isp) is slave - use master instead (BR-LOCAL)
add action=mark-routing chain=prerouting comment="Mark traffic from Q-in-Q" \
    in-interface=ether2-isp new-routing-mark=from-qinq src-address=\
    10.200.1.0/24
/ip firewall nat
add action=masquerade chain=srcnat comment="NAT - Masquerade to Internet" \
    out-interface=ether1-wan
/ip route
add comment="Force Q-in-Q replies via qinq-vlan999" distance=1 dst-address=\
    10.200.1.0/24 gateway=*14 routing-mark=from-qinq
add comment="Default route to Internet" distance=1 gateway=10.10.10.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/snmp
set contact=laboratorio@agrotech.local enabled=yes location=\
    "La Plata - Gateway Central" trap-version=2
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK01-agrotech-lp-gw
/system logging
add prefix=MK01 topics=error,critical,warning
/system ntp client
set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system scheduler
add comment="Backup diario automatico a las 3 AM" interval=1d name=\
    auto-backup on-event="/system backup save name=(\"MK01-auto-\" . [:pick [/\
    system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pi\
    ck [/system clock get date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=03:00:00
add interval=1h name=hourly-topology-check on-event=\
    "/system script run full-topology-check" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=nov/24/2025 start-time=23:59:50
/system script
add comment="Verificar estado de encapsulacion Q-in-Q" \
    dont-require-permissions=no name=check-qinq owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Q-in-Q Status Check ===\"\
    \n        :log info \"S-VLAN 4000 Status:\"\
    \n        /interface print stats where name=\"s-vlan-4000\"\
    \n        :log info \"C-VLANs Status:\"\
    \n        /interface print stats where name~\"qinq-vlan\"\
    \n        :log info \"=== End Check ===\"\
    \n    "
add comment="Verificar conectividad a equipos remotos" \
    dont-require-permissions=no name=check-connectivity owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Connectivity Check ===\"\
    \n        :local gateways {\"10.200.1.10\";\"10.200.1.20\";\"10.200.1.50\"\
    ;\"10.200.1.51\"}\
    \n        :foreach gw in=\$gateways do={\
    \n            :log info (\"Ping to \" . \$gw . \":\")\
    \n            /ping \$gw count=3\
    \n        }\
    \n        :log info \"=== End Check ===\"\
    \n    "
add dont-require-permissions=no name=full-topology-check owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== FULL TOPOLOGY CHECK ===\"\
    \n        :local devices {\"10.200.1.10\";\"10.200.1.50\";\"10.200.1.51\";\
    \"10.200.1.20\"; \\\
    \n                        \"10.200.1.21\";\"10.200.1.22\";\"10.200.1.25\"}\
    \n        :local names {\"MK02\";\"SXT-MG\";\"SXT-CA\";\"MK03\";\"MK04\";\
    \"MK05\";\"MK06\"}\
    \n        :local i 0\
    \n        :foreach dev in=\$devices do={\
    \n            :local name [:pick \$names \$i]\
    \n            :if ([/ping \$dev count=3] > 0) do={\
    \n                :log info (\" \" . \$name . \" (\" . \$dev . \") - ONLIN\
    E\")\
    \n            } else={\
    \n                :log error (\" \" . \$name . \" (\" . \$dev . \") - OFFL\
    INE\")\
    \n                # Enviar alerta\
    \n                /tool e-mail send to=\"protocolosinlambrica@gmail.com\" \
    \\\
    \n                    subject=(\"ALERTA: \" . \$name . \" OFFLINE\") \\\
    \n                    body=(\"Dispositivo \" . \$name . \" no responde\")\
    \n            }\
    \n            :set i (\$i + 1)\
    \n        }\
    \n        :log info \"=== END CHECK ===\"\
    \n    "
add dont-require-permissions=no name=check-dhcp-status owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:put \"=== DHCP SERVER STATUS ===\"\
    \n:put \"\"\
    \n:put \">>> Servers:\"\
    \n/ip dhcp-server print\
    \n:put \"\"\
    \n:put \">>> Leases activos:\"\
    \n/ip dhcp-server lease print where status=bound\
    \n:put \"\"\
    \n:put \">>> Pools:\"\
    \n/ip pool print\
    \n:put \"=== END ===\"\
    \n"
add dont-require-permissions=no name=test-full-connectivity owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source="\
    \n:put \"==============================================\"\
    \n:put \"=== TEST CONECTIVIDAD END-TO-END AGROTECH ===\"\
    \n:put \"==============================================\"\
    \n:put \"\"\
    \n\
    \n# Test VLAN 999 (Management)\
    \n:put \">>> VLAN 999 - Management:\"\
    \n:foreach ip in={\"10.200.1.10\";\"10.200.1.20\";\"10.200.1.21\";\"10.200\
    .1.22\";\"10.200.1.25\";\"10.200.1.50\";\"10.200.1.51\"} do={\
    \n    :local r [/ping \$ip count=2]\
    \n    :if (\$r > 0) do={:put (\"  \$ip: OK\")} else={:put (\"  \$ip: FAIL\
    \")}\
    \n}\
    \n\
    \n:put \"\"\
    \n:put \">>> VLAN 10 - Servers (si hay clientes):\"\
    \n/ip dhcp-server lease print where server~\"vlan10\"\
    \n\
    \n:put \"\"\
    \n:put \">>> VLAN 20 - Desktop (si hay clientes):\"\
    \n/ip dhcp-server lease print where server~\"vlan20\"\
    \n\
    \n:put \"\"\
    \n:put \"=== FIN TEST ===\"\
    \n"
/tool e-mail
set address=smtp.gmail.com from=protocolosinlambrica@gmail.com password=\
    protocolos.25 port=587 start-tls=yes user=protocolosinlambrica@gmail.com
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
