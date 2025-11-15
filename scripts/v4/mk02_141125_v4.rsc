# nov/14/2025 - SCRIPT FINAL - OPTIMIZADO PARA ROS 6.49.19 LTS
# ========================================
# MK02: ISP Magdalena (RB951Ui-2HnD)
# IP: 10.200.1.10/24 (VLAN 99)
# Desencapsulación Q-in-Q: S-VLAN 4000 en ether2
# ========================================

/system identity set name=agrotech-mg-ap
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
/ip address remove [find]
/ip route remove [find]
/ip dhcp-client remove [find]
/ip dhcp-relay remove [find]
/ip firewall mangle remove [find]
/ip service disable ftp,telnet,www-ssl,api,api-ssl

# ----------------------------------------
# 1. INTERFACES FISICAS, WIRELESS y BRIDGES
# ----------------------------------------
/interface ethernet
set ether1 mtu=1500 l2mtu=1522 comment="Link L2 a SXT-MG (PTP AP)"
set ether2 mtu=1500 l2mtu=1522 comment="Q-in-Q Trunk desde Switch L2"

/interface bridge
add name=BR-MAIN vlan-filtering=yes protocol-mode=rstp mtu=1500 l2mtu=1522

/interface wireless security-profiles
add name=wpa2-psk mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm \
    wpa2-pre-shared-key="ClaveSegura2024!AgroTech"

/interface wireless
set wlan1 ssid=AP-MG-Priv-Agrotech security-profile=wpa2-psk mode=ap-bridge \
    channel-width=20/40mhz-xx band=2ghz-b/g/n disabled=no

# ----------------------------------------
# 2. Q-in-Q DESENCAPSULACION (S-VLAN 4000)
# ----------------------------------------
/interface vlan
# S-VLAN 4000 en ether2 (WAN)
add name=vlan4000-qinq interface=ether2 vlan-id=4000 use-service-tag=yes
# C-VLANs desencapsuladas
add name=vlan10-mg interface=vlan4000-qinq vlan-id=10
add name=vlan20-mg interface=vlan4000-qinq vlan-id=20
add name=vlan90-mg interface=vlan4000-qinq vlan-id=90
add name=vlan96-mg interface=vlan4000-qinq vlan-id=96
add name=vlan201-mg interface=vlan4000-qinq vlan-id=201

# ----------------------------------------
# 3. PUERTOS DEL BRIDGE y VLAN FILTERING
# ----------------------------------------
/interface bridge port
# Puertos Desencapsulados (L2)
add bridge=BR-MAIN interface=vlan10-mg
add bridge=BR-MAIN interface=vlan20-mg
add bridge=BR-MAIN interface=vlan90-mg
add bridge=BR-MAIN interface=vlan96-mg
add bridge=BR-MAIN interface=vlan201-mg
# Link al SXT-MG (PTP) y WiFi Local
add bridge=BR-MAIN interface=ether1 comment="Trunk a SXT-MG"
add bridge=BR-MAIN interface=wlan1 comment="WiFi Local"
add bridge=BR-MAIN interface=ether3 comment="Puerto Acceso"

/interface bridge vlan
# VLANs de datos y gestión (10, 20, 90, 96, 201, 99) pasan etiquetadas por ether1 (al PTP) y wlan1 (WiFi local)
add bridge=BR-MAIN vlan-ids=10,20,90,96,201,99 tagged=ether1,wlan1,BR-MAIN
# PVID (Puerto Untagged) para Acceso Local
add bridge=BR-MAIN vlan-ids=90 untagged=ether3 pvid=90

# ----------------------------------------
# 4. DIRECCIONAMIENTO L3 y DHCP RELAY
# ----------------------------------------
/interface vlan
add name=vlan99-mgmt interface=BR-MAIN vlan-id=99

/ip address
add address=10.200.1.10/24 interface=vlan99-mgmt comment="IP de Gestion MK02"

/ip route
add distance=1 gateway=10.200.1.1 comment="Default Gateway a MK01"

/ip dhcp-relay
add name=dhcp-10-relay interface=vlan10-mg dhcp-server=192.168.10.1
add name=dhcp-20-relay interface=vlan20-mg dhcp-server=192.168.20.1
add name=dhcp-90-relay interface=vlan90-mg dhcp-server=192.168.90.1
add name=dhcp-96-relay interface=vlan96-mg dhcp-server=192.168.96.1
add name=dhcp-201-relay interface=vlan201-mg dhcp-server=192.168.201.1

# ----------------------------------------
# 5. SEGURIDAD Y OPTIMIZACION
# ----------------------------------------
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn action=change-mss new-mss=clamp-to-pmtu \
    comment="MSS Clamp (Critico para L2MTU 1522)"