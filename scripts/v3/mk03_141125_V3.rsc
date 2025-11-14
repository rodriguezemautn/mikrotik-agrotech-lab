# nov/14/2025 - Rev. 4 - MK03: Gateway Campo A - AP PtMP
# ====================================================================
# Dispositivo: agrotech-ca-gw
# Rol: Gateway L3 para el Campo, AP del PtMP (wlan1).
# Configuracion de Gestion: 10.200.1.20/24 en ether3.
# ====================================================================

/system identity set name=agrotech-ca-gw
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
add name=BR-TRUNK vlan-filtering=yes protocol-mode=rstp mtu=1590 comment="Core Trunk for L2 Transit and PtMP"

# Seguridad Inalámbrica (RNF-01)
/interface wireless security-profiles
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=ptmp-wds-campo wpa-pre-shared-key=Link.Agrotech.PtMP! wpa2-pre-shared-key=Link.Agrotech.PtMP!

# Wireless Configuration - PtMP AP (wlan1)
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz disabled=no mode=ap-bridge name=wlan-ptmp-ap security-profile=ptmp-wds-campo ssid="Agrotech-PtMP-2462" wds-default-bridge=BR-TRUNK wds-mode=dynamic wps-mode=disabled frequency=2462 country=argentina
/interface wireless set wlan-ptmp-ap wireless-protocol=nv2

# Puertos
/interface bridge port
# ether1: Trunk L2 from SXT-CA
add bridge=BR-TRUNK interface=ether1 comment="Trunk from SXT-CA"
# ether3: Gestion Local
add bridge=BR-TRUNK interface=ether3 pvid=999 comment="Local Mgmt Access (Untagged)"
# ether4/5: Local Access (e.g. VLAN 10/20 Untagged)
add bridge=BR-TRUNK interface=ether4 pvid=10 comment="Desktop Access (VLAN 10 Untagged)"
add bridge=BR-TRUNK interface=ether5 pvid=20 comment="CCTV/Server Access (VLAN 20 Untagged)"
# wlan1: PtMP Link
add bridge=BR-TRUNK interface=wlan-ptmp-ap comment="WDS Link to Stations"

# REGLAS DE VLAN FILTERING
/interface bridge vlan
# C-VLANs (10, 20, 90, 96) - Tags para ether1/wlan-ptmp-ap
add bridge=BR-TRUNK vlan-ids=10 tagged=ether1,wlan-ptmp-ap untagged=ether4 comment="VLAN 10 - Trunk/Local Access"
add bridge=BR-TRUNK vlan-ids=20 tagged=ether1,wlan-ptmp-ap untagged=ether5 comment="VLAN 20 - Trunk/Local Access"
add bridge=BR-TRUNK vlan-ids=90 tagged=ether1,wlan-ptmp-ap comment="VLAN 90 - Trunk"
add bridge=BR-TRUNK vlan-ids=96 tagged=ether1,wlan-ptmp-ap comment="VLAN 96 - Trunk"
# VLAN 999 - Gestion Local
add bridge=BR-TRUNK vlan-ids=999 untagged=ether3 comment="VLAN 999 - Gestion Local (Untagged on ether3)"

# 2. IP ADDRESSING Y RUTAS
/ip address
add address=10.200.1.20/24 interface=ether3 comment="IP de Gestion PtMP AP"
/ip route
add distance=1 gateway=10.200.1.1 comment="Ruta por defecto a MK01"

# 3. FIREWALL (RNF-02)
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input protocol=icmp
add action=accept chain=input src-address=10.200.1.0/24 comment="Allow Mgmt (10.200.1.0/24)"
add action=accept chain=input src-address=192.168.0.0/16 comment="Allow Mgmt from local LANs"
add action=drop chain=input comment="Drop all other input"

add action=accept chain=forward connection-state=established,related
add action=drop chain=forward src-address=192.168.96.0/24 dst-address=192.168.0.0/16 comment="Guest Isolation (Drop to Corp LANs)"
add action=drop chain=forward comment="Drop all other forward traffic (L2 only)"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn

# 4. MONITOREO Y GESTION (RNF-03)
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/snmp set enabled=yes contact="laboratorio@universidad.edu" location="CA - PtMP AP Gateway"

# Configuracion de Logging por email
/tool e-mail set address="smtp.gmail.com" port=587 start-tls=yes from="protocolosinlambrica@gmail.com" user="protocolosinlambrica@gmail.com" password="protocolos.25"
/system logging action add name=email-alert target=email email-to=emanuelrodriguez644@gmail.com
/system logging add topics=error,critical action=email-alert prefix="MK03-ALERT"

# 5. DESHABILITAR SERVICIOS NO USADOS
/ip service disable ftp,telnet,www-ssl,api,api-ssl
/tool mac-server set [find] disabled=yes
/tool mac-server mac-winbox set [find] disabled=yes