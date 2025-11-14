# nov/13/2025 18:14:00 - Rev. 3 - Optimizado station-bridge, MTU, WPA3, bridge vlan full
# ========================================
# MK06: AP Extra Campo - WiFi
# IP: 10.200.1.25/24
# User: laboratorio / Lab2025!
# Station PtMP para el AP WiFi adicional.
# Cambios Rev.3: MTU=1590, ingress-filtering, WPA3 para todos SSIDs, bridge vlan
# ========================================

/system identity set name=agrotech-ap-extra
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
# 1. Bridge, Wireless y VLAN
# ----------------------------------------

/interface bridge
add name=BR-CAMPO vlan-filtering=yes protocol-mode=rstp ether-type=0x88a8 mtu=1590 ingress-filtering=yes frame-types=admit-only-vlan-tagged
add name=BR-WiFi-Priv vlan-filtering=yes mtu=1590
add name=BR-WiFi-Guest vlan-filtering=yes mtu=1590

/interface wireless security-profiles
add authentication-types=wpa3-psk mode=dynamic-keys name=PtMP-Secure supplicant-identity=agrotech-ap-extra wpa2-pre-shared-key="AgroTechWDS_2025!" management-protection=required
add authentication-types=wpa3-psk mode=dynamic-keys name=WiFi-Priv-Profile supplicant-identity=agrotech-ap-extra wpa2-pre-shared-key="AgroTechWiFi90_2025!" management-protection=required
add authentication-types=wpa3-psk mode=dynamic-keys name=WiFi-Guest-Profile supplicant-identity=agrotech-ap-extra wpa2-pre-shared-key="GuestWiFi96_2025!" management-protection=required

/interface wireless
set wlan1 disabled=no mode=station-bridge ssid="AGROTECH-CAMPO-PTMP" band=2ghz-b/g/n frequency=2462 channel-width=20mhz wireless-protocol=nv2 security-profile=PtMP-Secure tx-power=10 country=argentina mtu=1590
add disabled=no master-interface=wlan1 name=wlan-priv ssid="AgroTech-AP90" security-profile=WiFi-Priv-Profile mtu=1590  # Corregido master-interface=wlan1
add disabled=no master-interface=wlan1 name=wlan-guest ssid="AgroTech-AP96-Guest" security-profile=WiFi-Guest-Profile mtu=1590

/interface bridge port
add bridge=BR-CAMPO comment="Enlace PtMP" interface=wlan1 ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-CAMPO comment="Puerto Downstream Trunk (Tagged)" interface=ether2 ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-WiFi-Priv comment="AP Privado (Untagged)" interface=wlan-priv pvid=90 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged
add bridge=BR-WiFi-Guest comment="AP Invitados (Untagged)" interface=wlan-guest pvid=96 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged
add bridge=BR-WiFi-Priv interface=ether3 pvid=90 comment="Puerto Downstream PVID 90" ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged
add bridge=BR-WiFi-Guest interface=ether4 pvid=96 comment="Puerto Downstream PVID 96" ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged

/interface bridge vlan
add bridge=BR-CAMPO tagged=wlan1,ether2,BR-CAMPO vlan-ids=10,20,201
add bridge=BR-WiFi-Priv tagged=ether2,BR-WiFi-Priv untagged=wlan-priv,ether3 vlan-ids=90
add bridge=BR-WiFi-Guest tagged=ether2,BR-WiFi-Guest untagged=wlan-guest,ether4 vlan-ids=96

# ----------------------------------------
# 2. Direccionamiento L3
# ----------------------------------------

/ip address
add address=10.200.1.25/24 comment="IP de Gestion Segregada" interface=ether5 network=10.200.1.0

/ip route
add comment="Ruta por defecto a MK01 (vía MK03)" distance=1 gateway=10.200.1.1

# ----------------------------------------
# 3. Seguridad y Monitoreo
# ----------------------------------------

/ip firewall filter
add action=accept chain=input connection-state=established,related comment="1. Allow Established/Related"
add action=accept chain=input protocol=icmp comment="2. Allow ICMP/Ping"
add action=accept chain=input comment="3. Allow Mgmt from Link/WAN" src-address=10.200.1.0/24
add action=accept chain=input comment="4. Allow Mgmt from Local LANs" src-address=192.168.0.0/16
add action=drop chain=input comment="5. Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward comment="Allow transit"
add action=drop chain=forward src-address=192.168.96.0/24 dst-address=192.168.0.0/16 comment="Guest Isolation"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - AP Extra Campo"
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# ----------------------------------------
# 4. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl
/ip service set www address=10.200.1.25/32
/ip service set winbox address=10.200.1.0/24
/ip service set ssh address=10.200.1.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0