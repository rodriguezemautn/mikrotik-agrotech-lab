# nov/14/2025 - Rev. 4 - MK0X: Station PtMP - Plantilla
# ====================================================================
# Rol: Station PtMP (wlan1), Bridge L2 transparente, Acceso Local con PVIDs.
# Configuracion de Gestion: 10.200.1.XX/24 en ether3.
# ====================================================================

# MODIFICAR: name, address y location según el dispositivo (MK04, MK05, MK06)
:local DEVICE_NAME "agrotech-cb-st"
:local DEVICE_IP "10.200.1.21/24"
:local DEVICE_LOC "CB - Drones Station"
:local VLAN_ACCESS_PORT "ether4" # Puerto para Acceso Principal (e.g. Drones/Galpon)
:local VLAN_ACCESS_PVID "10" # PVID para el Puerto de Acceso

/system identity set name=$DEVICE_NAME
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
add name=BR-CAMPO vlan-filtering=yes protocol-mode=rstp mtu=1590 comment="L2 Station Trunk"

# Seguridad Inalámbrica (RNF-01)
/interface wireless security-profiles
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=ptmp-wds-campo wpa-pre-shared-key=Link.Agrotech.PtMP! wpa2-pre-shared-key=Link.Agrotech.PtMP!

# Wireless Configuration - PtMP Station (wlan1)
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz disabled=no mode=station-bridge name=wlan-ptmp-st security-profile=ptmp-wds-campo ssid="Agrotech-PtMP-2462" wds-default-bridge=BR-CAMPO wds-mode=dynamic wps-mode=disabled frequency=2462 country=argentina
/interface wireless set wlan-ptmp-st wireless-protocol=nv2

# Puertos
/interface bridge port
# wlan1: PtMP Link
add bridge=BR-CAMPO interface=wlan-ptmp-st comment="WDS Link to AP"
# ether3: Gestion Local
add bridge=BR-CAMPO interface=ether3 pvid=999 comment="Local Mgmt Access (Untagged)"
# Puerto de Acceso Principal (VLAN 10/20)
add bridge=BR-CAMPO interface=$VLAN_ACCESS_PORT pvid=$VLAN_ACCESS_PVID comment="Local Access (VLAN XX Untagged)"
# Puertos restantes (ether2, ether5) - Se dejan fuera del bridge o como PVID 999 para control.

# REGLAS DE VLAN FILTERING
/interface bridge vlan
# C-VLANs (10, 20, 90, 96) - Tags para wlan-ptmp-st
add bridge=BR-CAMPO vlan-ids=10 tagged=wlan-ptmp-st untagged=$VLAN_ACCESS_PORT comment="VLAN 10 - Trunk/Local Access"
add bridge=BR-CAMPO vlan-ids=20 tagged=wlan-ptmp-st comment="VLAN 20 - Trunk/Local Access"
add bridge=BR-CAMPO vlan-ids=90 tagged=wlan-ptmp-st comment="VLAN 90 - Trunk"
add bridge=BR-CAMPO vlan-ids=96 tagged=wlan-ptmp-st comment="VLAN 96 - Trunk"
# VLAN 999 - Gestion Local
add bridge=BR-CAMPO vlan-ids=999 untagged=ether3 comment="VLAN 999 - Gestion Local (Untagged on ether3)"

# 2. IP ADDRESSING Y RUTAS
/ip address
add address=$DEVICE_IP interface=ether3 comment="IP de Gestion PtMP Station"
/ip route
add distance=1 gateway=10.200.1.1 comment="Ruta por defecto a MK01"

# 3. FIREWALL (RNF-02)
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input protocol=icmp
add action=accept chain=input src-address=10.200.1.0/24 comment="Allow Mgmt from Link/WAN"
add action=accept chain=input src-address=192.168.0.0/16 comment="Allow Mgmt from Local LANs"
add action=drop chain=input comment="Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=drop chain=forward src-address=192.168.96.0/24 dst-address=192.168.0.0/16 comment="Guest Isolation (Drop to Corp LANs)"
add action=drop chain=forward comment="Drop all other forward traffic (L2 only)"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

# 4. MONITOREO Y GESTION (RNF-03)
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/snmp set enabled=yes contact="laboratorio@universidad.edu" location=$DEVICE_LOC

# 5. DESHABILITAR SERVICIOS NO USADOS
/ip service disable ftp,telnet,www-ssl,api,api-ssl
/tool mac-server set [find] disabled=yes
/tool mac-server mac-winbox set [find] disabled=yes