# nov/13/2025 18:14:00 - Rev. 2 - Archivo SXT-CA
# ========================================
# SXT-CA: PtP 8km Campo A (Station)
# IP: 10.200.1.51/24
# User: laboratorio / Lab2025!
# Station del enlace PtP de 8km.
# ========================================

/system identity set name=sxt-ca
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
add name=BR-PTP vlan-filtering=yes protocol-mode=rstp

/interface wireless security-profiles
add name=PtP-Secure mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="AgroTechWDS_2025!"

/interface wireless
set wlan1 disabled=no mode=station-wds ssid="AGROTECH-PTP-8KM" band=2ghz-b/g/n frequency=auto \
    channel-width=20mhz wireless-protocol=nv2 nv2-qos=frame-priority security-profile=PtP-Secure \
    tx-power=27 country=argentina installation=outdoor

/interface bridge port
add bridge=BR-PTP interface=wlan1
add bridge=BR-PTP interface=ether1 comment="To MK03"

/interface bridge vlan
add bridge=BR-PTP tagged=wlan1,ether1 vlan-ids=10,20,90,96,201

# ----------------------------------------
# 2. Direccionamiento L3
# ----------------------------------------

/ip address
add address=10.200.1.51/24 comment="IP de Gestion PtP Cliente" interface=ether1 network=10.200.1.0

/ip route
add comment="Ruta por defecto a MK01 (vía MK03)" distance=1 gateway=10.200.1.1

# ----------------------------------------
# 3. Seguridad y Monitoreo
# ----------------------------------------

/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow Management" src-address=10.200.1.0/24
add action=accept chain=input protocol=icmp
add action=drop chain=input comment="Drop all other input"

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - SXT Campo A"
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# El cliente SMTP no se configura aquí, ya que el SXT-CA actúa como L2 de tránsito.

# ----------------------------------------
# 4. Deshabilitar servicios no usados
# ----------------------------------------

/ip service disable ftp,telnet,www-ssl,api,api-ssl,winbox,ssh
/ip service set www address=10.200.1.51/32
/ip service set winbox address=10.200.1.0/24
/ip service set ssh address=10.200.1.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/port disable 0