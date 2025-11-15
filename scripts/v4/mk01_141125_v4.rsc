# nov/14/2025 - Rev. 4 - OPTIMIZADO PARA ROS 6.49.19 LTS
# ========================================
# MK01: Gateway La Plata (RB951Ui-2HnD)
# IP: 10.200.1.1/24 (VLAN 99)
# Encapsulación Q-in-Q: S-VLAN 4000 en ether2
# ========================================

/system identity set name=agrotech-lp-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/user set admin password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------
# 0. LIMPIEZA INICIAL
# ----------------------------------------
/interface bridge port remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find where default=no]
/ip address remove [find]
/ip route remove [find]
/ip dhcp-client remove [find]
/ip service disable ftp,telnet,www-ssl,api,api-ssl
/ip dhcp-server remove [find]
/ip pool remove [find]
/ip firewall nat remove [find]
/ip firewall mangle remove [find]
/ip firewall filter remove [find]

# ----------------------------------------
# 1. INTERFACES FISICAS, WIRELESS y BRIDGES
# ----------------------------------------
# MTU C-VLANs = 1500. L2MTU WAN = 1522 para doble tag.
/interface ethernet
set ether1 mtu=1500 l2mtu=1522 comment="WAN L3 a ISP Minorista"
set ether2 mtu=1500 l2mtu=1522 comment="Q-in-Q Trunk a Switch L2"
set ether3 mtu=1500 l2mtu=1522
set ether4 mtu=1500 l2mtu=1522
set ether5 mtu=1500 l2mtu=1522

/interface bridge
add name=BR-CORE vlan-filtering=yes protocol-mode=rstp mtu=1500 l2mtu=1522

/interface wireless security-profiles
add name=wpa2-psk mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm \
    wpa2-pre-shared-key="ClaveSegura2024!AgroTech"
set [ find default=yes ] supplicant-identity=MikroTik

/interface wireless
set wlan1 ssid=AP-LP-Priv-Agrotech security-profile=wpa2-psk mode=ap-bridge \
    channel-width=20/40mhz-xx band=2ghz-b/g/n disabled=no

# ----------------------------------------
# 2. Q-in-Q ENCAPSULACION (S-VLAN 4000)
# ----------------------------------------
/interface vlan
# S-VLAN 4000 en ether2 (WAN)
add name=vlan4000-qinq interface=ether2 vlan-id=4000 use-service-tag=yes
# C-VLANs encapsuladas dentro de la S-VLAN 4000
add name=vlan10-qinq interface=vlan4000-qinq vlan-id=10
add name=vlan20-qinq interface=vlan4000-qinq vlan-id=20
add name=vlan90-qinq interface=vlan4000-qinq vlan-id=90
add name=vlan96-qinq interface=vlan4000-qinq vlan-id=96
add name=vlan201-qinq interface=vlan4000-qinq vlan-id=201

# ----------------------------------------
# 3. PUERTOS DEL BRIDGE y VLAN FILTERING
# ----------------------------------------
/interface bridge port
add bridge=BR-CORE interface=ether1 comment="WAN L3 a ISP Minorista (no en bridge)"
add bridge=BR-CORE interface=wlan1 comment="WiFi Local (Tagged VLAN 90, 96)"
add bridge=BR-CORE interface=ether3 comment="Acceso local/Servidores"
add bridge=BR-CORE interface=ether4
add bridge=BR-CORE interface=ether5
# Interfaces Q-in-Q para routing local y DHCP server/relay
add bridge=BR-CORE interface=vlan10-qinq
add bridge=BR-CORE interface=vlan20-qinq
add bridge=BR-CORE interface=vlan90-qinq
add bridge=BR-CORE interface=vlan96-qinq
add bridge=BR-CORE interface=vlan201-qinq

/interface bridge vlan
# VLANs de datos (10, 20, 90, 96, 201) pasan etiquetadas por Q-in-Q y WiFi local
add bridge=BR-CORE vlan-ids=10,20,90,96,201 tagged=vlan10-qinq,vlan20-qinq,vlan90-qinq,vlan96-qinq,vlan201-qinq,wlan1,BR-CORE
# VLAN de GESTION 99
add bridge=BR-CORE vlan-ids=99 tagged=vlan10-qinq,vlan20-qinq,vlan90-qinq,vlan96-qinq,vlan201-qinq,wlan1,BR-CORE
# PVID (Puerto Untagged) para Acceso Local
add bridge=BR-CORE vlan-ids=90 untagged=ether3 pvid=90
add bridge=BR-CORE vlan-ids=96 untagged=ether4 pvid=96
add bridge=BR-CORE vlan-ids=99 untagged=ether5 pvid=99

# ----------------------------------------
# 4. DIRECCIONAMIENTO L3 y DHCP SERVER
# ----------------------------------------
/interface vlan
add name=vlan99-mgmt interface=BR-CORE vlan-id=99

/ip address
add address=10.200.1.1/24 interface=vlan99-mgmt comment="IP de Gestion MK01"
add address=192.168.1.254/24 interface=ether1 comment="WAN L3 ISP MINORISTA"
add address=192.168.10.1/24 interface=vlan10-qinq comment="Red Servidores"
add address=192.168.20.1/24 interface=vlan20-qinq comment="Red IoT"
add address=192.168.90.1/24 interface=vlan90-qinq comment="Red Agrotech Privada"
add address=192.168.96.1/24 interface=vlan96-qinq comment="Red Guest"
add address=192.168.201.1/24 interface=vlan201-qinq comment="Red CCTV"

/ip route
add distance=1 gateway=192.168.1.1 comment="Default Gateway WAN L3"

/ip pool
add name=pool-90 ranges=192.168.90.100-192.168.90.250
add name=pool-96 ranges=192.168.96.100-192.168.96.250
/ip dhcp-server
add address-pool=pool-90 interface=vlan90-qinq name=dhcp-90 disabled=no
add address-pool=pool-96 interface=vlan96-qinq name=dhcp-96 disabled=no
/ip dhcp-server network
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=192.168.10.1
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=8.8.8.8

# ----------------------------------------
# 5. SEGURIDAD Y OPTIMIZACION
# ----------------------------------------
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn action=change-mss new-mss=clamp-to-pmtu \
    comment="MSS Clamp (Critico para L2MTU 1522)"

/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1 comment="NAT for WAN access"

# ----------------------------------------
# 6. MONITOREO Y SERVICIOS
# ----------------------------------------
/system ntp client set enabled=yes primary-ntp=200.23.1.7 secondary-ntp=200.23.1.1
/snmp set enabled=yes contact="laboratorio@universidad.edu" location="Lab - La Plata Gateway"