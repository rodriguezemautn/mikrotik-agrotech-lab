# nov/13/2025 18:14:00 - Rev. 3 - Optimizado AP PTMP, MTU, WPA3, bridge vlan
# ========================================
# MK03: Gateway Campo A - AP PtMP
# IP: 10.200.1.20/24
# User: laboratorio / Lab2025!
# Gateway L3 para el campo y AP del PtMP.
# Cambios Rev.3: ether-type=0x88a8, MTU=1590, ingress-filtering, WPA3, no local WiFi APs (corregido ether3/4)
# ========================================

/system identity set name=agrotech-ca-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/user set admin password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------
# 0. LIMPIEZA INICIAL
# ----------------------------------------

/interface bridge port remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find !default=yes]

# ----------------------------------------
# 1. Bridges, Wireless y VLAN Interfaces
# ----------------------------------------

/interface bridge
add comment="Core Transit L2 Bridge (VLANs 10, 20, 201)" name=BR-MAIN vlan-filtering=yes protocol-mode=rstp ether-type=0x88a8 mtu=1590 ingress-filtering=yes frame-types=admit-only-vlan-tagged
add comment="Local AP VLAN 96" name=BR-WiFi-Guest vlan-filtering=yes mtu=1590
add comment="Local AP VLAN 90" name=BR-WiFi-Priv vlan-filtering=yes mtu=1590

/interface vlan
add interface=BR-MAIN name=VLAN10-Transit vlan-id=10
add interface=BR-MAIN name=VLAN20-Transit vlan-id=20
add interface=BR-MAIN name=VLAN90-Local vlan-id=90
add interface=BR-MAIN name=VLAN96-Local vlan-id=96
add interface=BR-MAIN name=VLAN201-Transit vlan-id=201

/interface wireless security-profiles
add name=PtMP-Secure mode=dynamic-keys authentication-types=wpa3-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="AgroTechWDS_2025!" management-protection=required
add name=WiFi-Priv-Profile mode=dynamic-keys authentication-types=wpa3-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="AgroTechWiFi90_2025!" management-protection=required
add name=WiFi-Guest-Profile mode=dynamic-keys authentication-types=wpa3-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="GuestWiFi96_2025!" management-protection=required

/interface wireless
set wlan1 disabled=no mode=ap-bridge ssid="AGROTECH-CAMPO-PTMP" band=2ghz-b/g/n frequency=2462 channel-width=20mhz wireless-protocol=nv2 nv2-qos=frame-priority security-profile=PtMP-Secure wds-mode=dynamic wds-default-bridge=BR-MAIN tx-power=10 country=argentina mtu=1590

/interface bridge port
add bridge=BR-MAIN interface=ether1 comment="From SXT-CA (Tagged)" ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-MAIN interface=wlan1 comment="To PtMP Stations (Tagged)" ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-MAIN interface=ether2 comment="Local Port (Tagged)" ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-MAIN interface=VLAN10-Transit ingress-filtering=yes
add bridge=BR-MAIN interface=VLAN20-Transit ingress-filtering=yes
add bridge=BR-MAIN interface=VLAN201-Transit ingress-filtering=yes

add bridge=BR-WiFi-Priv interface=VLAN90-Local
add bridge=BR-WiFi-Priv interface=ether3 pvid=90 comment="Local AP Privado (Untagged)" ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged
add bridge=BR-WiFi-Guest interface=VLAN96-Local
add bridge=BR-WiFi-Guest interface=ether4 pvid=96 comment="Local AP Invitados (Untagged)" ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged

/interface bridge vlan
add bridge=BR-MAIN tagged=wlan1,ether1,ether2,BR-MAIN untagged=VLAN10-Transit vlan-ids=10
add bridge=BR-MAIN tagged=wlan1,ether1,ether2,BR-MAIN untagged=VLAN20-Transit vlan-ids=20
add bridge=BR-MAIN tagged=wlan1,ether1,ether2,BR-MAIN untagged=VLAN90-Local vlan-ids=90
add bridge=BR-MAIN tagged=wlan1,ether1,ether2,BR-MAIN untagged=VLAN96-Local vlan-ids=96
add bridge=BR-MAIN tagged=wlan1,ether1,ether2,BR-MAIN untagged=VLAN201-Transit vlan-ids=201

# ----------------------------------------
# 2. Direccionamiento L3 y DHCP
# ----------------------------------------

/ip address
add address=10.200.1.20/24 interface=ether5 network=10.200.1.0 comment="Management Link"
add address=192.168.90.20/24 interface=BR-WiFi-Priv network=192.168.90.0
add address=192.168.96.20/24 interface=BR-WiFi-Guest network=192.168.96.0

/ip dhcp-relay  # Relay para reducir broadcasts over wireless
add name=dhcp-relay interface=BR-MAIN dhcp-server=192.168.10.1 local-address=10.200.1.20

/ip route
add comment="Ruta por defecto a MK01" distance=1 gateway=10.200.1.1

# ----------------------------------------
# 3. Seguridad (Firewall)
# ----------------------------------------

/ip address-list
add address=10.200.1.0/24 list=LAN-ACCESS comment="Enlace Gestion"
add address=192.168.0.0/16 list=LAN-ACCESS comment="Red Local Privada"

/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow LAN/Mgmt access to router" src-address-list=LAN-ACCESS
add action=accept chain=input protocol=icmp
add action=accept chain=input dst-port=53 protocol=udp
add action=accept chain=input dst-port=67-68 protocol=udp comment="Allow DHCP"
add action=drop chain=input comment="Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward comment="VLAN 90 to anywhere (WAN/Transit)" src-address=192.168.90.0/24
add action=drop chain=forward comment="Guest WiFi Isolation" dst-address=192.168.0.0/16 src-address=192.168.96.0/24
add action=accept chain=forward comment="Allow all other transit/WAN"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

# ----------------------------------------
# 4. NTP, SNMP y Logging (Monitoreo)
# ----------------------------------------

/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - Campo A Gateway"

/tool e-mail
set address="smtp.gmail.com" port=587 start-tls=yes from="protocolosinlambrica@gmail.com" user="protocolosinlambrica@gmail.com" password="protocolos.25"  # App password

/system logging action
add name=email-alert target=email email-to=emanuelrodriguez644@gmail.com

/system logging
add topics=error,critical action=email-alert
add topics=system,info action=email-alert prefix="MK03-ALERT"

# ----------------------------------------
# 5. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl
/ip service set www address=10.200.1.20/32,192.168.0.0/16
/ip service set winbox address=10.200.1.0/24,192.168.0.0/16
/ip service set ssh address=10.200.1.0/24,192.168.0.0/16
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0