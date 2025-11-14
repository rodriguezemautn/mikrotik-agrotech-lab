# nov/14/2025 - Rev. 3 - MK01: Gateway La Plata - Q-in-Q ENCAPSULADOR
# ====================================================================
# Dispositivo: agrotech-lp-gw (MK01 - RB951ui-2HnD)
# Rol: Gateway, Servidor DHCP/DNS, NAT, Frontera L3, Encapsulador S-VLAN 201.
# Configuracion de Gestion: 10.200.1.1/24 en ether3.
# ====================================================================

/system identity set name=agrotech-lp-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/user set admin password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# 0. LIMPIEZA INICIAL
/interface bridge port remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find !default=yes]

# 1. INTERFACES Y BRIDGES
# BR-TRUNK: Bridge central para transporte L2 Q-in-Q y VLANs locales
/interface bridge
add name=BR-TRUNK vlan-filtering=yes protocol-mode=rstp mtu=1590 ether-type=0x88a8 comment="Core Trunk for Q-in-Q (S-VLAN 201)"

# Seguridad Inalámbrica (RNF-01)
/interface wireless security-profiles
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=agrotech-vlan90 ssid-prefix="" supplicant-identity="" wpa-pre-shared-key=Agrotech.2025! wpa2-pre-shared-key=Agrotech.2025!
add authentication-types=wpa2-psk,wpa3-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=agrotech-vlan96 ssid-prefix="" supplicant-identity="" wpa-pre-shared-key=Agrotech.Guest.2025! wpa2-pre-shared-key=Agrotech.Guest.2025!

# Configuración de AP Local (wlan1)
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-ht-below disabled=no mode=ap-bridge name=ap-office-lp security-profile=agrotech-vlan90 ssid="Agrotech-Office-LP" wps-mode=disabled

# 2. PUERTOS Y VLAN FILTERING (Q-in-Q ENCAPSULACION)
/interface bridge port
# ether1: WAN (No en Bridge, L3)
# ether2: ISP Trunk Q-in-Q - PVID 201 (S-VLAN de transito)
add bridge=BR-TRUNK interface=ether2 pvid=201 frame-types=admit-only-vlan-tagged ingress-filtering=yes comment="ISP Q-in-Q Trunk"
# ether3: Gestion Local (Untagged)
add bridge=BR-TRUNK interface=ether3 pvid=999 comment="Local Mgmt Access (Untagged)"
# wlan1: AP Local (Tagged C-VLANs)
add bridge=BR-TRUNK interface=ap-office-lp
# ether4 (Desktop/Server access - e.g. VLAN 10/20 Untagged)
add bridge=BR-TRUNK interface=ether4 pvid=10 comment="Desktop Access (VLAN 10 Untagged)"
# ether5 (CCTV/Server access - e.g. VLAN 20 Untagged)
add bridge=BR-TRUNK interface=ether5 pvid=20 comment="CCTV/Server Access (VLAN 20 Untagged)"

# REGLAS DE VLAN FILTERING (802.1Q/802.1AD)
/interface bridge vlan
# S-VLAN 201 - El core L2 (BR-TRUNK) DEBE llevar el tag 201 y apilar las C-VLANs en ether2
add bridge=BR-TRUNK tagged=BR-TRUNK,ether2 vlan-ids=201 tag-stacking=no comment="S-VLAN 201 - Transito del Bridge"

# C-VLANs (10, 20, 90, 96) - Apilamiento/Encapsulación Q-in-Q
# Puerto ether2 (ISP) debe tener el tag S-VLAN 201 (PVID 201 ya lo hace)
add bridge=BR-TRUNK vlan-ids=10 tagged=BR-TRUNK,ether2 untagged=ether4 tag-stacking=yes comment="VLAN 10 - Desktop (Q-in-Q Encapsulate)"
add bridge=BR-TRUNK vlan-ids=20 tagged=BR-TRUNK,ether2 untagged=ether5 tag-stacking=yes comment="VLAN 20 - CCTV (Q-in-Q Encapsulate)"
add bridge=BR-TRUNK vlan-ids=90 tagged=BR-TRUNK,ether2,ap-office-lp tag-stacking=yes comment="VLAN 90 - Private WiFi (Q-in-Q Encapsulate)"
add bridge=BR-TRUNK vlan-ids=96 tagged=BR-TRUNK,ether2,ap-office-lp tag-stacking=yes comment="VLAN 96 - Guest WiFi (Q-in-Q Encapsulate)"
# VLAN 999 - Gestion Local
add bridge=BR-TRUNK vlan-ids=999 untagged=ether3 comment="VLAN 999 - Gestion Local (Untagged on ether3)"

# 3. IP ADDRESSING Y RUTAS
/ip address
add address=10.200.1.1/24 interface=ether3 comment="IP Gestion Local"
add address=192.168.10.1/24 interface=BR-TRUNK vlan-id=10 comment="VLAN 10 - Escritorio GW"
add address=192.168.20.1/24 interface=BR-TRUNK vlan-id=20 comment="VLAN 20 - CCTV GW"
add address=192.168.90.1/24 interface=BR-TRUNK vlan-id=90 comment="VLAN 90 - Privada GW"
add address=192.168.96.1/24 interface=BR-TRUNK vlan-id=96 comment="VLAN 96 - Invitados GW"
add address=10.10.10.2/30 interface=ether1 comment="WAN Simulación Hogareña" # Asumimos IP WAN ficticia
/ip route
add distance=1 gateway=10.10.10.1 comment="Ruta por defecto a Internet"

# 4. DHCP & DNS (RF-04)
/ip pool
add name=pool-v10 ranges=192.168.10.100-192.168.10.254
add name=pool-v20 ranges=192.168.20.100-192.168.20.254
add name=pool-v90 ranges=192.168.90.100-192.168.90.254
add name=pool-v96 ranges=192.168.96.100-192.168.96.254

/ip dhcp-server
add address-pool=pool-v10 disabled=no interface=BR-TRUNK vlan-id=10 name=dhcp-v10
add address-pool=pool-v20 disabled=no interface=BR-TRUNK vlan-id=20 name=dhcp-v20
add address-pool=pool-v90 disabled=no interface=BR-TRUNK vlan-id=90 name=dhcp-v90
add address-pool=pool-v96 disabled=no interface=BR-TRUNK vlan-id=96 name=dhcp-v96

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1 comment="VLAN 10"
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1 comment="VLAN 20"
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=192.168.90.1 comment="VLAN 90"
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=192.168.96.1 comment="VLAN 96"

/ip dns set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1

# 5. FIREWALL Y NAT (RNF-02, RF-05)
/ip firewall filter
add action=accept chain=input connection-state=established,related comment="1. Allow Established/Related"
add action=accept chain=input protocol=icmp comment="2. Allow ICMP/Ping"
add action=accept chain=input src-address=10.200.1.0/24 comment="3. Allow Mgmt (10.200.1.0/24)"
add action=drop chain=input comment="4. Drop all other input"

add action=accept chain=forward connection-state=established,related comment="1. Allow Established/Related Forward"
add action=accept chain=forward src-address=192.168.20.0/24 dst-address=192.168.10.0/24 comment="2. Allow CCTV to Servers/Desktop (Explicit)"
add action=drop chain=forward src-address=192.168.96.0/24 dst-address=192.168.0.0/16 comment="3. Guest Isolation (Drop to Corp LANs)"
add action=drop chain=forward dst-address=!10.10.10.0/30 in-interface=BR-TRUNK comment="4. Drop Transit traffic not for WAN/LANs (RNF-02 - Security)"

/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1 comment="NAT for WAN access (RF-05)"

/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn comment="Clamp MSS for MTU 1590 (RNF-04)"

# 6. MONITOREO Y GESTION (RNF-03)
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/snmp set enabled=yes contact="laboratorio@universidad.edu" location="LP - Agrotech Gateway"

/tool e-mail set address="smtp.gmail.com" port=587 start-tls=yes from="protocolosinlambrica@gmail.com" user="protocolosinlambrica@gmail.com" password="protocolos.25"
/system logging action add name=email-alert target=email email-to=emanuelrodriguez644@gmail.com
/system logging add topics=error,critical action=email-alert prefix="MK01-ALERT"

# 7. DESHABILITAR SERVICIOS NO USADOS
/ip service disable ftp,telnet,www-ssl,api,api-ssl
/tool mac-server set [find] disabled=yes
/tool mac-server mac-winbox set [find] disabled=yes