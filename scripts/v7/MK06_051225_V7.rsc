# nov/28/2025 08:23:53 by RouterOS 6.49.19
# software id = GCUB-ETCR
#
# model = 951Ui-2HnD
# serial number = 6433050CA0B0
/interface bridge
add comment="Bridge Station PTMP" name=BR-CAMPO vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] l2mtu=1600 name=ether1-spare
set [ find default-name=ether2 ] l2mtu=1600 name=ether2-spare
set [ find default-name=ether3 ] comment=Management l2mtu=1600 name=\
    ether3-mgmt
set [ find default-name=ether4 ] comment="Trunk WiFi VLANs 90/96" l2mtu=1600 \
    name=ether4-trunk
set [ find default-name=ether5 ] l2mtu=1600 name=ether5-spare
/interface vlan
add interface=BR-CAMPO name=vlan999-mgmt vlan-id=999
/interface list
add name=MGMT
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk comment="PTMP security" mode=dynamic-keys \
    name=ptmp-campo supplicant-identity=MikroTik wpa2-pre-shared-key=\
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
/user group
set full policy="local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,pas\
    sword,web,sniff,sensitive,api,romon,dude,tikapp"
/interface bridge port
add bridge=BR-CAMPO comment="PTMP to MK03" interface=wlan1
add bridge=BR-CAMPO comment=Management frame-types=\
    admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=\
    ether3-mgmt pvid=999
add bridge=BR-CAMPO comment="Trunk WiFi - VLANs 90/96" interface=ether4-trunk
/ip neighbor discovery-settings
set discover-interface-list=!dynamic
/interface bridge vlan
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 vlan-ids=10
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 vlan-ids=20
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1,ether4-trunk vlan-ids=90
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1,ether4-trunk vlan-ids=96
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1 vlan-ids=201
add bridge=BR-CAMPO tagged=BR-CAMPO,wlan1,ether4-trunk untagged=ether3-mgmt \
    vlan-ids=999
/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-mgmt list=MGMT
/ip address
add address=10.200.1.25/24 comment="Management IP" interface=vlan999-mgmt \
    network=10.200.1.0
/ip dhcp-client
# DHCP client can not run on slave interface!
add disabled=no interface=ether4-trunk
/ip dns
set servers=10.200.1.1
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input icmp-options=8:0 protocol=icmp
add action=accept chain=input src-address=10.200.1.0/24
add action=accept chain=input src-address=192.168.0.0/16
add action=log chain=input log-prefix="DROP-MK06: "
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
    "Campo - AP Extra"
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK06-agrotech-ap-extra
/system logging
add prefix=MK06 topics=wireless,error,critical
/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7
/system scheduler
add interval=1d name=auto-backup on-event="/system backup save name=(\"MK06-au\
    to-\" . [:pick [/system clock get date] 7 11] . [:pick [/system clock get \
    date] 0 3] . [:pick [/system clock get date] 4 6])" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=nov/14/2025 start-time=04:15:00
add interval=1h name=hourly-topology-check on-event=\
    "/system script run full-topology-check" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=nov/25/2025 start-time=06:35:00
/system script
add dont-require-permissions=no name=check-connection owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== MK06 Connection Status ===\"\
    \n        /interface wireless monitor wlan1 once\
    \n        /ping 10.200.1.20 count=5\
    \n        :log info \"=== End Check ===\"\
    \n    "
add dont-require-permissions=no name=full-topology-check owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n        :log info \"=== FULL TOPOLOGY CHECK ===\"\
    \n        :local devices {\"10.200.1.1\";\"10.200.1.10\";\"10.200.1.50\";\
    \"10.200.1.51\";\"10.200.1.20\"; \\\
    \n                        \"10.200.1.21\";\"10.200.1.22\"}\
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
    \n                /tool e-mail send to=\"admin@agrotech.com\" \\\
    \n                    subject=(\"ALERTA: \" . \$name . \" OFFLINE\") \\\
    \n                    body=(\"Dispositivo \" . \$name . \" no responde\")\
    \n            }\
    \n            :set i (\$i + 1)\
    \n        }\
    \n        :log info \"=== END CHECK ===\"\
    \n    "
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
