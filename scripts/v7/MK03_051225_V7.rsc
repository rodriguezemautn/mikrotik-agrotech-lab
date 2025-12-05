# jan/15/1970 05:50:55 by RouterOS 6.49.19
# software id = 3JKZ-AQ07
#
# model = 951Ui-2HnD
# serial number = 4AC9041BDB96
/interface bridge
add comment="Bridge Campo - L2 Transport + PTMP" name=BR-CAMPO \
    vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] comment="Trunk from SXT-CA" l2mtu=1600 mtu=\
    1590 name=ether1-ptp
set [ find default-name=ether2 ] comment="Spare port" l2mtu=1600 name=\
    ether2-spare
set [ find default-name=ether3 ] comment=Management l2mtu=1600 name=\
    ether3-mgmt
set [ find default-name=ether4 ] comment="Local VLAN 10 - Servers" l2mtu=1600 \
    name=ether4-servers
set [ find default-name=ether5 ] comment="Local VLAN 20 - Desktop" l2mtu=1600 \
    name=ether5-desktop
/interface vlan
add comment="VLAN 10 para DHCP local" interface=BR-CAMPO name=vlan10-dhcp \
    vlan-id=10
add comment="VLAN 20 para DHCP local" interface=BR-CAMPO name=vlan20-dhcp \
    vlan-id=20
add comment="VLAN 90 para DHCP local" interface=BR-CAMPO name=vlan90-dhcp \
    vlan-id=90
add comment="VLAN 96 para DHCP local" interface=BR-CAMPO name=vlan96-dhcp \
    vlan-id=96
add comment="VLAN 201 para DHCP local" interface=BR-CAMPO name=vlan201-dhcp \
    vlan-id=201
add comment="Management VLAN" interface=BR-CAMPO name=vlan999-mgmt vlan-id=\
    999
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk comment="PTMP Campo security" mode=\
    dynamic-keys name=ptmp-campo supplicant-identity=MikroTik \
    wpa2-pre-shared-key=PtMP.Campo.AgroTech.2025!Secure
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n comment="PTMP AP Master" \
    country=argentina disabled=no distance=indoors frequency=2462 mode=\
    ap-bridge security-profile=ptmp-campo ssid=Agrotech-PTMP-Campo \
    wds-default-bridge=BR-CAMPO wds-mode=dynamic wireless-protocol=nv2 \
    wps-mode=disabled
/interface wireless manual-tx-power-table
set wlan1 comment="PTMP AP Master"
/interface wireless nstreme
set wlan1 comment="PTMP AP Master"
/ip pool
add comment="Backup VLAN 10" name=pool-vlan10-backup ranges=\
    192.168.10.150-192.168.10.199
add comment="Backup VLAN 20" name=pool-vlan20-backup ranges=\
    192.168.20.150-192.168.20.199
add comment="Backup VLAN 90" name=pool-vlan90-backup ranges=\
    192.168.90.150-192.168.90.199
add comment="Backup VLAN 96" name=pool-vlan96-backup ranges=\
    192.168.96.150-192.168.96.199
add comment="Backup VLAN 201" name=pool-vlan201-backup ranges=\
    192.168.201.150-192.168.201.199
/interface bridge port
add bridge=BR-CAMPO comment="Trunk from SXT-CA" interface=ether1-ptp
add bridge=BR-CAMPO comment="Management - VLAN 999" frame-types=\
    admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=\
    ether3-mgmt pvid=999
add bridge=BR-CAMPO comment="Servers - VLAN 10 Untagged" frame-types=\
    admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=\
    ether4-servers pvid=10
add bridge=BR-CAMPO comment="Desktop - VLAN 20 Untagged" frame-types=\
    admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=\
    ether5-desktop pvid=20
add bridge=BR-CAMPO comment="PTMP Link" interface=wlan1
/interface bridge vlan
add bridge=BR-CAMPO tagged=BR-CAMPO,ether1-ptp,wlan1 untagged=ether4-servers \
    vlan-ids=10
add bridge=BR-CAMPO tagged=BR-CAMPO,ether1-ptp,wlan1 untagged=ether5-desktop \
    vlan-ids=20
add bridge=BR-CAMPO tagged=BR-CAMPO,ether1-ptp,wlan1 vlan-ids=90
add bridge=BR-CAMPO tagged=BR-CAMPO,ether1-ptp,wlan1 vlan-ids=96
add bridge=BR-CAMPO tagged=BR-CAMPO,ether1-ptp,wlan1 vlan-ids=201
add bridge=BR-CAMPO tagged=BR-CAMPO,ether1-ptp,wlan1 untagged=ether3-mgmt \
    vlan-ids=999
/ip address
add address=10.200.1.20/24 comment="Management IP" interface=vlan999-mgmt \
    network=10.200.1.0
add address=192.168.10.254/24 comment="Gateway Local VLAN 10 - Servers" \
    interface=vlan10-dhcp network=192.168.10.0
add address=192.168.20.254/24 comment="Gateway Local VLAN 20 - Desktop" \
    interface=vlan20-dhcp network=192.168.20.0
add address=192.168.90.254/24 comment="Gateway Local VLAN 90 - WiFi Privada" \
    interface=vlan90-dhcp network=192.168.90.0
add address=192.168.96.254/24 comment="Gateway Local VLAN 96 - WiFi Guest" \
    interface=vlan96-dhcp network=192.168.96.0
add address=192.168.201.254/24 comment="Gateway Local VLAN 201 - CCTV" \
    interface=vlan201-dhcp network=192.168.201.0
/ip dhcp-server network
add address=192.168.10.0/24 comment="VLAN 10 - Gateway en MK01" dns-server=\
    192.168.10.1,8.8.8.8 gateway=192.168.10.1
add address=192.168.20.0/24 comment="VLAN 20 - Gateway en MK01" dns-server=\
    192.168.20.1,8.8.8.8 gateway=192.168.20.1
add address=192.168.90.0/24 comment="VLAN 90 - Gateway en MK01" dns-server=\
    192.168.90.1,8.8.8.8 gateway=192.168.90.1
add address=192.168.96.0/24 comment="VLAN 96 - Gateway en MK01" dns-server=\
    192.168.96.1,8.8.8.8 gateway=192.168.96.1
add address=192.168.201.0/24 comment="VLAN 201 - Gateway en MK01" dns-server=\
    192.168.201.1 gateway=192.168.201.1
/ip dns
set allow-remote-requests=yes cache-max-ttl=1d cache-size=8192KiB servers=\
    8.8.8.8,1.1.1.1
/ip firewall filter
add action=accept chain=input comment="Accept established/related" \
    connection-state=established,related
add action=accept chain=input comment="Accept ICMP" icmp-options=8:0 \
    protocol=icmp
add action=accept chain=input comment="Accept from Management" src-address=\
    10.200.1.0/24
add action=accept chain=input comment="Accept from Corporate VLANs" \
    src-address=192.168.0.0/16
add action=log chain=input log-prefix="DROP-MK03: "
add action=drop chain=input
add action=accept chain=forward connection-state=established,related
add action=drop chain=forward connection-state=invalid
add action=drop chain=forward comment="Guest isolation" dst-address=\
    192.168.0.0/16 src-address=192.168.96.0/24
add action=accept chain=forward dst-address=192.168.0.0/16 src-address=\
    192.168.0.0/16
add action=accept chain=forward
/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes \
    protocol=tcp tcp-flags=syn
/ip route
add comment="Default to MK01" distance=1 gateway=10.200.1.1
add comment="Corporate VLANs via MK01" distance=1 dst-address=192.168.0.0/16 \
    gateway=10.200.1.1
/snmp
set contact=laboratorio@agrotech.local enabled=yes location=\
    "Campo A - PTMP AP Gateway"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK03-agrotech-ca-gw
/system logging
add prefix=MK03 topics=wireless,error,critical
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system scheduler
add interval=1d name=auto-backup on-event="/system backup save name=(\"MK03-au\
    to-\" . [:pick [/system clock get date] 7 11] . [:pick [/system clock get \
    date] 0 3] . [:pick [/system clock get date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=03:30:00
add interval=1h name=hourly-topology-check on-event=\
    "/system script run full-topology-check" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/12/1970 start-time=04:03:40
/system script
add dont-require-permissions=no name=check-ptmp-clients owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== PTMP Clients ===\"\
    \n        /interface wireless registration-table print\
    \n        :log info \"=== WDS Interfaces ===\"\
    \n        /interface wireless wds print\
    \n        :log info \"=== End Check ===\"\
    \n    "
add dont-require-permissions=no name=check-vlans owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== VLAN Status ===\"\
    \n        /interface bridge vlan print\
    \n        /interface bridge port print\
    \n        :log info \"=== End Check ===\"\
    \n    "
add dont-require-permissions=no name=ping-test-all owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== Connectivity Test ===\"\
    \n        :local targets {\"10.200.1.1\";\"10.200.1.10\";\"10.200.1.50\";\
    \"10.200.1.51\"}\
    \n        :foreach t in=\$targets do={\
    \n            :log info (\"Testing \" . \$t)\
    \n            /ping \$t count=3\
    \n        }\
    \n        :log info \"=== End Test ===\"\
    \n    "
add dont-require-permissions=no name=full-topology-check owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== FULL TOPOLOGY CHECK ===\"\
    \n        :local devices {\"10.200.1.1\";\"10.200.1.10\";\"10.200.1.50\";\
    \"10.200.1.51\";\"10.200.1.21\";\"10.200.1.22\";\"10.200.1.23\";\"10.200.1\
    .25\"}\
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
add comment="Verificar modo de operacion actual" dont-require-permissions=no \
    name=check-autonomous-mode owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== AUTONOMOUS MODE CHECK ===\"\
    \n        :local mk01status [/tool netwatch get [find host=10.200.1.1] sta\
    tus]\
    \n        :log info (\"MK01 Status: \" . \$mk01status)\
    \n        \
    \n        :if (\$mk01status = \"down\") do={\
    \n            :log warning \"MODO: AUTONOMO (MK01 caido)\"\
    \n            :log info \"DHCP Servers:\"\
    \n            /ip dhcp-server print where name~\"local\"\
    \n            :log info \"Rutas:\"\
    \n            /ip route print where comment~\"MK01\"\
    \n        } else={\
    \n            :log info \"MODO: NORMAL (MK01 operativo)\"\
    \n        }\
    \n        :log info \"=== END CHECK ===\"\
    \n    "
add dont-require-permissions=no name=ver-failover owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:put \"=== FAILOVER STATUS MK03 ===\"\
    \n:put \"\"\
    \n\
    \n# Test MK01\
    \n:local mk01 [/ping 10.200.1.1 count=3]\
    \n:if (\$mk01 > 0) do={\
    \n    :put \"MK01 Status: ONLINE (\$mk01/3 pings)\"\
    \n    :put \"Modo: NORMAL (DHCP en MK01)\"\
    \n} else={\
    \n    :put \"MK01 Status: OFFLINE\"\
    \n    :put \"Modo: FAILOVER (DHCP local activo)\"\
    \n}\
    \n\
    \n:put \"\"\
    \n:put \">>> DHCP Servers:\"\
    \n/ip dhcp-server print\
    \n\
    \n:put \"\"\
    \n:put \">>> Netwatch:\"\
    \n/tool netwatch print\
    \n\
    \n:put \"=== END ===\"\
    \n"
add dont-require-permissions=no name=test-failover owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:put \"=== TEST FAILOVER MANUAL ===\"\
    \n:put \"\"\
    \n:put \">>> Estado actual DHCP:\"\
    \n/ip dhcp-server print where disabled=no\
    \n:put \"\"\
    \n:put \">>> Simular caida MK01 (activar DHCP backup):\"\
    \n:put \"    /ip dhcp-server set [find name~\\\"backup\\\"] disabled=no\"\
    \n:put \"\"\
    \n:put \">>> Restaurar (desactivar DHCP backup):\"\
    \n:put \"    /ip dhcp-server set [find name~\\\"backup\\\"] disabled=yes\"\
    \n:put \"=== END ===\"\
    \n"
add dont-require-permissions=no name=ver-leases owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:put \"=== DHCP LEASES MK03 ===\"\
    \n:local total [:len [/ip dhcp-server lease find]]\
    \n:local bound [:len [/ip dhcp-server lease find where status=bound]]\
    \n:put (\"Total: \$total, Activos: \$bound\")\
    \n:put \"\"\
    \n/ip dhcp-server lease print where status=bound\
    \n:put \"=== END ===\"\
    \n"
/tool e-mail
set address=smtp.gmail.com from=agrotech-alerts@gmail.com password=\
    password_here port=587 start-tls=yes user=agrotech-alerts@gmail.com
/tool netwatch
add comment="Monitor MK01 - DHCP Failover" down-script="\
    \n:log warning \"============================================\"\
    \n:log warning \"MK01 OFFLINE - Activando DHCP Backup\"\
    \n:log warning \"============================================\"\
    \n/ip dhcp-server set [find name~\"backup\"] disabled=no\
    \n:log warning \"DHCP Backup ACTIVADO\"\
    \n:log warning \"MK03 es ahora servidor DHCP\"\
    \n" host=10.200.1.1 interval=10s timeout=3s up-script="\
    \n:log info \"============================================\"\
    \n:log info \"MK01 ONLINE - Desactivando DHCP Backup\"\
    \n:log info \"============================================\"\
    \n/ip dhcp-server set [find name~\"backup\"] disabled=yes\
    \n:log info \"DHCP Backup desactivado\"\
    \n:log info \"MK01 es servidor DHCP primario\"\
    \n"
