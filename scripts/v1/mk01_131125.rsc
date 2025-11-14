# nov/13/2025 18:14:00 - Rev. 2 - Agregado SMTP Client
# ========================================
# MK01: Gateway La Plata
# IP: 10.200.1.1/24
# User: laboratorio / Lab2025!
# Implementa L3 local y Encapsulación Q-in-Q (S-VLAN 201)
# ========================================

/system identity set name=agrotech-lp-gw
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
add name=BR-MAIN vlan-filtering=yes protocol-mode=rstp
add name=BR-WiFi-Priv vlan-filtering=yes
add name=BR-WiFi-Guest vlan-filtering=yes

/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add name=WiFi-Priv-Profile mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="AgroTechWiFi90_2025!"
add name=WiFi-Guest-Profile mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="GuestWiFi96_2025!"

/interface wireless
set wlan1 disabled=no mode=ap-bridge ssid="AgroTech-LaPlata" band=2ghz-b/g/n frequency=2412 \
    channel-width=20mhz security-profile=WiFi-Priv-Profile tx-power=10 country=argentina
add disabled=no master-interface=wlan1 name=wlan-guest ssid="AgroTech-Guest-LP" security-profile=WiFi-Guest-Profile

/interface vlan
add interface=ether2 name=VLAN10-Servers vlan-id=10
add interface=ether2 name=VLAN20-Desktop vlan-id=20
add interface=ether2 name=VLAN90-WiFi-Priv vlan-id=90
add interface=ether2 name=VLAN96-WiFi-Guest vlan-id=96
add interface=ether2 name=VLAN201-CCTV vlan-id=201
add interface=ether2 name=VLAN201-Trunk vlan-id=201 comment="SP VLAN (Q-in-Q Tagging)"

/interface bridge port
add bridge=BR-MAIN interface=ether2
add bridge=BR-MAIN interface=ether4 comment="To ISP/WAN"
add bridge=BR-MAIN interface=VLAN10-Servers
add bridge=BR-MAIN interface=VLAN20-Desktop
add bridge=BR-MAIN interface=VLAN201-CCTV
add bridge=BR-MAIN interface=VLAN201-Trunk

add bridge=BR-WiFi-Priv interface=wlan1
add bridge=BR-WiFi-Priv interface=VLAN90-WiFi-Priv

add bridge=BR-WiFi-Guest interface=wlan-guest
add bridge=BR-WiFi-Guest interface=VLAN96-WiFi-Guest

# ----------------------------------------
# 2. Direccionamiento L3 y DHCP
# ----------------------------------------

/ip address
add address=10.200.1.1/24 interface=ether5 network=10.200.1.0 comment="Management Link to MK02/SXT"
add address=192.168.10.1/24 interface=VLAN10-Servers network=192.168.10.0
add address=192.168.20.1/24 interface=VLAN20-Desktop network=192.168.20.0
add address=192.168.90.1/24 interface=BR-WiFi-Priv network=192.168.90.0
add address=192.168.96.1/24 interface=BR-WiFi-Guest network=192.168.96.0
add address=192.168.201.1/24 interface=VLAN201-CCTV network=192.168.201.0

/ip pool
add name=dhcp-10 ranges=192.168.10.100-192.168.10.254
add name=dhcp-20 ranges=192.168.20.100-192.168.20.254
add name=dhcp-90 ranges=192.168.90.100-192.168.90.254
add name=dhcp-96 ranges=192.168.96.100-192.168.96.254
add name=dhcp-201 ranges=192.168.201.100-192.168.201.254

/ip dhcp-server
add address-pool=dhcp-10 disabled=no interface=VLAN10-Servers name=dhcp-10
add address-pool=dhcp-20 disabled=no interface=VLAN20-Desktop name=dhcp-20
add address-pool=dhcp-90 disabled=no interface=BR-WiFi-Priv name=dhcp-90
add address-pool=dhcp-96 disabled=no interface=BR-WiFi-Guest name=dhcp-96
add address-pool=dhcp-201 disabled=no interface=VLAN201-CCTV name=dhcp-201

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=192.168.90.1
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=192.168.96.1
add address=192.168.201.0/24 gateway=192.168.201.1 dns-server=192.168.201.1

/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.254 comment="Ruta por defecto a Internet (Simulado)"

# ----------------------------------------
# 3. Seguridad (Firewall y NAT)
# ----------------------------------------

/ip address-list
add address=192.168.10.0/24 list=LAN-SERVIDORES
add address=192.168.20.0/24 list=LAN-SERVIDORES

/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.200.1.0/24 comment="Allow Mgmt Link"
add action=accept chain=input src-address=192.168.0.0/16 comment="Allow Local LANs for Mgmt"
add action=accept chain=input protocol=icmp
add action=accept chain=input protocol=udp dst-port=53
add action=accept chain=input protocol=udp dst-port=67-68
add action=drop chain=input comment="Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward src-address=192.168.10.0/24 comment="Servers to Anywhere"
add action=accept chain=forward src-address=192.168.20.0/24 dst-address-list=LAN-SERVIDORES comment="Desktop to Servers"
add action=accept chain=forward src-address=192.168.90.0/24 dst-address-list=LAN-SERVIDORES comment="Private WiFi to Servers/Desktop"
add action=drop chain=forward src-address=192.168.96.0/24 dst-address=192.168.0.0/16 comment="Guest WiFi Isolation"
add action=accept chain=forward src-address=192.168.201.0/24 dst-address=192.168.10.0/24 comment="CCTV to Servers"
add action=accept chain=forward comment="Accept all other forwards (WAN/Local)"

/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether4 comment="NAT for WAN access"

# ----------------------------------------
# 4. NTP, SNMP y Logging (Monitoreo)
# ----------------------------------------

/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - La Plata Gateway"

/tool e-mail
set address="smtp.gmail.com" port=587 start-tls=yes from="protocolosinlambrica@gmail.com" \
    user="protocolosinlambrica@gmail.com" password="protocolos.25"

/system logging action
add name=email-alert target=email email-to=emanuelrodriguez644@gmail.com

/system logging
add topics=error,critical action=email-alert
add topics=system,info action=email-alert prefix="MK01-ALERT"

# ----------------------------------------
# 5. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl,winbox,ssh
/ip service set www address=10.200.1.1/32,192.168.0.0/16
/ip service set winbox address=10.200.1.0/24,192.168.0.0/16
/ip service set ssh address=10.200.1.0/24,192.168.0.0/16
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0