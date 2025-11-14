# nov/14/2025 - Rev. 4 - SXT-CA: PtP Station (Campo A)
# ====================================================================
# Dispositivo: sxt-ca
# Rol: Station del enlace PtP de 8km. Bridge L2 transparente con NV2 y MTU 1590.
# Configuracion de Gestion: 10.200.1.51/24 en ether1.
# ====================================================================

/system identity set name=sxt-ca
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/user set admin password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# 0. LIMPIEZA INICIAL
/interface bridge port remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find !default=yes]

# 1. BRIDGE, WIRELESS Y PUERTOS
/interface bridge
add name=BR-PTP vlan-filtering=yes protocol-mode=none mtu=1590 comment="L2 PTP Trunk (MTU 1590)"

# Seguridad Inalámbrica (RNF-01)
/interface wireless security-profiles
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=ptp-wds-sxt wpa-pre-shared-key=Link.Agrotech.SXT! wpa2-pre-shared-key=Link.Agrotech.SXT!

# Wireless Configuration - NV2 Station-Bridge
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz disabled=no mode=station-bridge name=wlan-ptp-st security-profile=ptp-wds-sxt ssid="Agrotech-PTP-2437" wds-mode=static wds-cost=2 wds-default-bridge=BR-PTP distance=8km country=argentina
/interface wireless set wlan-ptp-st wireless-protocol=nv2

# Puertos
/interface bridge port
# ether1: Gestion Local (Untagged) y Trunk L2 hacia MK03
add bridge=BR-PTP interface=ether1 pvid=999 comment="Local Mgmt/Trunk"
add bridge=BR-PTP interface=wlan-ptp-st comment="WDS Link"

# REGLAS DE VLAN FILTERING (Permite el paso de todas las C-VLANs)
/interface bridge vlan
# C-VLANs (10, 20, 90, 96) - Entran y salen etiquetadas por ether1 y wlan-ptp-st
add bridge=BR-PTP vlan-ids=10,20,90,96 tagged=ether1,wlan-ptp-st comment="C-VLANs Trunk"
# VLAN 999 - Gestion Local
add bridge=BR-PTP vlan-ids=999 untagged=ether1 comment="VLAN 999 - Gestion Local (Untagged on ether1)"

# 2. IP ADDRESSING Y RUTAS
/ip address
add address=10.200.1.51/24 interface=ether1 comment="IP de Gestion PtP Station"
/ip route
add distance=1 gateway=10.200.1.1 comment="Ruta por defecto a MK01"

# 3. SEGURIDAD Y MONITOREO
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input comment="Allow Management" src-address=10.200.1.0/24
add action=accept chain=input protocol=icmp
add action=drop chain=input comment="Drop all other input"
add action=accept chain=forward connection-state=established,related
add action=drop chain=forward comment="Drop all transit (L2 only)"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - SXT Campo A"
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# 4. DESHABILITAR SERVICIOS NO USADOS
/ip service disable ftp,telnet,www-ssl,api,api-ssl
/tool mac-server set [find] disabled=yes
/tool mac-server mac-winbox set [find] disabled=yes