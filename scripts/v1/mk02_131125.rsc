# nov/13/2025 18:14:00 - Rev. 2 - Agregado SMTP Client
# ========================================
# MK02: ISP Magdalena
# IP: 10.200.1.10/24
# User: laboratorio / Lab2025!
# Desencapsula S-VLAN 201 y gestiona AP local.
# ========================================

/system identity set name=agrotech-mg-ap
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/user set admin password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------
# 0. LIMPIEZA INICIAL y PRE-CONFIGURACIÓN
# ----------------------------------------

/interface bridge port remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find !default=yes]

# ----------------------------------------
# 1. Bridges, Wireless y VLAN Interfaces
# ----------------------------------------

/interface bridge
add comment="Core Transit L2 Bridge (VLANs 10, 20, 201)" name=BR-MAIN vlan-filtering=yes protocol-mode=rstp
add comment="Local AP VLAN 96" name=BR-WiFi-Guest vlan-filtering=yes
add comment="Local AP VLAN 90" name=BR-WiFi-Priv vlan-filtering=yes

/interface vlan
add comment="S-VLAN Decapsulation (Q-in-Q)" interface=ether2 name=VLAN201-Trunk vlan-id=201
add interface=VLAN201-Trunk name=VLAN10-Transit vlan-id=10
add interface=VLAN201-Trunk name=VLAN20-Transit vlan-id=20
add interface=VLAN201-Trunk name=VLAN90-Local vlan-id=90
add interface=VLAN201-Trunk name=VLAN96-Local vlan-id=96
add interface=VLAN201-Trunk name=VLAN201-Transit vlan-id=201

/interface wireless security-profiles
add name=WiFi-Priv-Profile mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="AgroTechWiFi90_2025!"
add name=WiFi-Guest-Profile mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="GuestWiFi96_2025!"

/interface wireless
set wlan1 disabled=no mode=ap-bridge ssid="AgroTech-Magdalena" band=2ghz-b/g/n frequency=2427 \
    channel-width=20mhz security-profile=WiFi-Priv-Profile tx-power=10 country=argentina
add disabled=no master-interface=wlan1 name=wlan-guest ssid="AgroTech-Guest-MG" security-profile=WiFi-Guest-Profile

/interface bridge port
add bridge=BR-MAIN interface=ether2 comment="From MK01"
add bridge=BR-MAIN interface=ether1 comment="To SXT-MG (PtP AP)"
add bridge=BR-MAIN interface=VLAN10-Transit
add bridge=BR-MAIN interface=VLAN20-Transit
add bridge=BR-MAIN interface=VLAN201-Transit

add bridge=BR-WiFi-Priv interface=wlan1
add bridge=BR-WiFi-Priv interface=VLAN90-Local

add bridge=BR-WiFi-Guest interface=wlan-guest
add bridge=BR-WiFi-Guest interface=VLAN96-Local

# ----------------------------------------
# 2. Direccionamiento L3 y DHCP
# ----------------------------------------

/ip address
add address=10.200.1.10/24 interface=ether5 network=10.200.1.0 comment="Management Link"
add address=192.168.90.10/24 interface=BR-WiFi-Priv network=192.168.90.0
add address=192.168.96.10/24 interface=BR-WiFi-Guest network=192.168.96.0

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
add action=accept chain=input dst-port=67-68 protocol=udp
add action=drop chain=input comment="Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward comment="VLAN 90 to anywhere (WAN/Transit)" src-address=192.168.90.0/24
add action=drop chain=forward comment="Guest WiFi Isolation" dst-address=192.168.0.0/16 src-address=192.168.96.0/24
add action=accept chain=forward comment="Allow all other transit/WAN"

# ----------------------------------------
# 4. NTP, SNMP y Logging (Monitoreo)
# ----------------------------------------

/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - Magdalena ISP"

/tool e-mail
set address="smtp.gmail.com" port=587 start-tls=yes from="protocolosinlambrica@gmail.com" \
    user="protocolosinlambrica@gmail.com" password="protocolos.25"

/system logging action
add name=email-alert target=email email-to=emanuelrodriguez644@gmail.com

/system logging
add topics=error,critical action=email-alert
add topics=system,info action=email-alert prefix="MK02-ALERT"

# ----------------------------------------
# 5. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl,winbox,ssh
/ip service set www address=10.200.1.10/32,192.168.0.0/16
/ip service set winbox address=10.200.1.0/24,192.168.0.0/16
/ip service set ssh address=10.200.1.0/24,192.168.0.0/16
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0