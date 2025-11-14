# nov/13/2025 18:14:00 - Rev. 3 - Optimizado NV2 full, MTU, bridge vlan, WPA3
# ========================================
# SXT-MG: PtP 8km Magdalena (AP)
# IP: 10.200.1.50/24
# User: laboratorio / Lab2025!
# AP del enlace PtP de 8km.
# Cambios Rev.3: MTU=1590, ingress-filtering, ether-type=0x88a8, WPA3
# ========================================

/system identity set name=sxt-mg
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
add name=BR-PTP vlan-filtering=yes protocol-mode=rstp ether-type=0x88a8 mtu=1590 ingress-filtering=yes frame-types=admit-only-vlan-tagged

/interface wireless security-profiles
add name=PtP-Secure mode=dynamic-keys authentication-types=wpa3-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="AgroTechWDS_2025!" management-protection=required

/interface wireless
set wlan1 disabled=no mode=ap-bridge ssid="AGROTECH-PTP-8KM" band=2ghz-b/g/n frequency=2437 channel-width=20mhz wireless-protocol=nv2 nv2-qos=frame-priority security-profile=PtP-Secure wds-mode=dynamic wds-default-bridge=BR-PTP tx-power=27 country=argentina installation=outdoor mtu=1590

/interface bridge port
add bridge=BR-PTP interface=wlan1 ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-PTP interface=ether1 comment="To MK02" ingress-filtering=yes frame-types=admit-only-vlan-tagged

/interface bridge vlan
add bridge=BR-PTP tagged=wlan1,ether1,BR-PTP vlan-ids=10,20,90,96,201

# ----------------------------------------
# 2. Direccionamiento L3
# ----------------------------------------

/ip address
add address=10.200.1.50/24 comment="IP de Gestion PtP AP" interface=ether1 network=10.200.1.0

/ip route
add comment="Ruta por defecto a MK01 (vía MK02)" distance=1 gateway=10.200.1.1

# ----------------------------------------
# 3. Seguridad y Monitoreo
# ----------------------------------------

/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow Management" src-address=10.200.1.0/24
add action=accept chain=input protocol=icmp
add action=drop chain=input comment="Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward comment="Allow transit"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - SXT Magdalena"
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# ----------------------------------------
# 4. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl
/ip service set www address=10.200.1.50/32
/ip service set winbox address=10.200.1.0/24
/ip service set ssh address=10.200.1.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0