# nov/13/2025 18:14:00 - Rev. 3 - Optimizado station-bridge, MTU, WPA3, bridge vlan
# ========================================
# MK05: Station Campo C - Galpon
# IP: 10.200.1.22/24
# User: laboratorio / Lab2025!
# Station PtMP para el sector de Galpón.
# Cambios Rev.3: MTU=1590, ingress-filtering, fixed frequency, WPA3
# ========================================

/system identity set name=agrotech-cc-st
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
add name=BR-GALPON vlan-filtering=yes protocol-mode=rstp ether-type=0x88a8 mtu=1590 ingress-filtering=yes frame-types=admit-only-vlan-tagged

/interface wireless security-profiles
add authentication-types=wpa3-psk mode=dynamic-keys name=PtMP-Secure supplicant-identity=agrotech-cc-st wpa2-pre-shared-key="AgroTechWDS_2025!" management-protection=required

/interface wireless
set wlan1 disabled=no mode=station-bridge ssid="AGROTECH-CAMPO-PTMP" band=2ghz-b/g/n frequency=2462 channel-width=20mhz wireless-protocol=nv2 security-profile=PtMP-Secure tx-power=10 country=argentina mtu=1590

/interface bridge port
add bridge=BR-GALPON interface=wlan1 comment="Enlace PtMP" ingress-filtering=yes frame-types=admit-only-vlan-tagged
add bridge=BR-GALPON interface=ether2 comment="Puerto Downstream Tagged" ingress-filtering=yes frame-types=admit-only-vlan-tagged

/interface bridge vlan
add bridge=BR-GALPON tagged=wlan1,ether2,BR-GALPON vlan-ids=20,90,201

# ----------------------------------------
# 2. Direccionamiento L3
# ----------------------------------------

/ip address
add address=10.200.1.22/24 comment="IP de Gestion Segregada" interface=ether3 network=10.200.1.0

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

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - Campo C Galpon"
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# ----------------------------------------
# 4. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl
/ip service set www address=10.200.1.22/32
/ip service set winbox address=10.200.1.0/24
/ip service set ssh address=10.200.1.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0