# nov/14/2025 - Rev. 4 - MK02: ISP Magdalena - Q-in-Q DECAPSULADOR y WDS Hub
# =======================================================================
# Dispositivo: agrotech-mg-ap (MK02 - RB951ui-2HnD)
# Rol: Desencapsulador S-VLAN 201, Hub WDS, AP Local.
# Configuracion de Gestion: 10.200.1.10/24 en ether3.
# =======================================================================

/system identity set name=agrotech-mg-ap
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/user set admin password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# 0. LIMPIEZA INICIAL
/interface bridge port remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find !default=yes]

# 1. INTERFACES Y BRIDGES
/interface bridge
add name=BR-TRUNK vlan-filtering=yes protocol-mode=rstp mtu=1590 ether-type=0x88a8 comment="Core Trunk for Q-in-Q Decap and WDS"

# Seguridad Inalámbrica (RNF-01)
/interface wireless security-profiles
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=ptp-wds-sxt wpa-pre-shared-key=Link.Agrotech.SXT! wpa2-pre-shared-key=Link.Agrotech.SXT!
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=agrotech-vlan90 wpa-pre-shared-key=Agrotech.2025! wpa2-pre-shared-key=Agrotech.2025!
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=agrotech-vlan96 wpa-pre-shared-key=Agrotech.Guest.2025! wpa2-pre-shared-key=Agrotech.Guest.2025!

# Configuración de AP WDS (wlan1) - a SXT-MG
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-ht-below disabled=no mode=ap-bridge name=wlan-ptp-hub security-profile=ptp-wds-sxt ssid="Agrotech-PtP-WDS-Hub" wds-default-bridge=BR-TRUNK wds-mode=dynamic wps-mode=disabled

# 2. PUERTOS Y VLAN FILTERING (Q-in-Q DECAPSULACION)
/interface bridge port
# ether2: ISP Trunk Q-in-Q (Inbound)
add bridge=BR-TRUNK interface=ether2 pvid=201 frame-types=admit-only-vlan-tagged ingress-filtering=yes comment="ISP Q-in-Q Trunk - S-VLAN 201"
# ether3: Gestion Local
add bridge=BR-TRUNK interface=ether3 pvid=999 comment="Local Mgmt Access (Untagged)"
# ether4/5 y wlan-ptp-hub (WDS link) son troncales C-VLAN

# REGLAS DE VLAN FILTERING (Q-in-Q DECAPSULACION)
/interface bridge vlan
# S-VLAN 201 - Sólo existe para Decapsular en ether2.
add bridge=BR-TRUNK tagged=BR-TRUNK vlan-ids=201 comment="S-VLAN 201 - Transito Decapsulacion"

# C-VLANs (10, 20, 90, 96) - Tags pasan a WDS y Local
# Puerto ether2 (ISP) DEBE tener el tag 201 (PVID 201 lo maneja)
# Puerto wlan-ptp-hub y ether4/5 (Local) SÓLO deben llevar C-VLAN tags (10, 20, 90, 96)
add bridge=BR-TRUNK vlan-ids=10 tagged=wlan-ptp-hub,ether4,ether5,BR-TRUNK tag-stacking=no comment="VLAN 10 - Trunk (Decapsulate)"
add bridge=BR-TRUNK vlan-ids=20 tagged=wlan-ptp-hub,ether4,ether5,BR-TRUNK tag-stacking=no comment="VLAN 20 - Trunk (Decapsulate)"
add bridge=BR-TRUNK vlan-ids=90 tagged=wlan-ptp-hub,ether4,ether5,BR-TRUNK tag-stacking=no comment="VLAN 90 - Trunk (Decapsulate)"
add bridge=BR-TRUNK vlan-ids=96 tagged=wlan-ptp-hub,ether4,ether5,BR-TRUNK tag-stacking=no comment="VLAN 96 - Trunk (Decapsulate)"
# VLAN 999 - Gestion Local
add bridge=BR-TRUNK vlan-ids=999 untagged=ether3 comment="VLAN 999 - Gestion Local (Untagged on ether3)"

# 3. IP ADDRESSING Y RUTAS
/ip address
add address=10.200.1.10/24 interface=ether3 comment="IP Gestion Local"
/ip route
add distance=1 gateway=10.200.1.1 comment="Ruta por defecto a MK01 (via Q-in-Q link)"

# 4. FIREWALL (RNF-02)
/ip firewall filter
add action=accept chain=input connection-state=established,related comment="1. Allow Established/Related"
add action=accept chain=input protocol=icmp comment="2. Allow ICMP/Ping"
add action=accept chain=input src-address=10.200.1.0/24 comment="3. Allow Mgmt (10.200.1.0/24)"
add action=drop chain=input comment="4. Drop all other input"

add action=accept chain=forward connection-state=established,related comment="1. Allow Established/Related Forward"
add action=drop chain=forward dst-address=!10.200.1.0/24 comment="2. Drop Transit (only L2 traffic allowed)"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn comment="Clamp MSS for MTU 1590 (RNF-04)"

# 5. MONITOREO Y GESTION (RNF-03)
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/snmp set enabled=yes contact="laboratorio@universidad.edu" location="MG - ISP Decapsulator Hub"

# Configuracion de Logging por email
/tool e-mail set address="smtp.gmail.com" port=587 start-tls=yes from="protocolosinlambrica@gmail.com" user="protocolosinlambrica@gmail.com" password="protocolos.25"
/system logging action add name=email-alert target=email email-to=emanuelrodriguez644@gmail.com
/system logging add topics=error,critical action=email-alert prefix="MK02-ALERT"

# 6. DESHABILITAR SERVICIOS NO USADOS
/ip service disable ftp,telnet,www-ssl,api,api-ssl
/tool mac-server set [find] disabled=yes
/tool mac-server mac-winbox set [find] disabled=yes