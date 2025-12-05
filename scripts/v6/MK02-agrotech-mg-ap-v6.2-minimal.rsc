# ============================================================================
# MK02-agrotech-mg-ap - CONFIGURACIÓN MINIMALISTA v2.2
# ============================================================================
# 
# DISPOSITIVO: MikroTik RB951Ui-2HnD  |  RouterOS 6.49.x
# FUNCIÓN: Transporte L2 transparente Q-in-Q
# IP GESTIÓN: 10.200.1.10/24
#
# DISEÑO: Un solo bridge con vlan-filtering para máxima simplicidad
# 
# ============================================================================

/system identity set name=MK02-agrotech-mg-ap

# --- INTERFACES ---
/interface ethernet
set [ find default-name=ether1 ] name=ether1-to-sxt l2mtu=1600 mtu=1590 comment="Trunk a SXT-MG"
set [ find default-name=ether2 ] name=ether2-isp l2mtu=1600 mtu=1590 comment="Q-in-Q desde MK01"
set [ find default-name=ether3 ] name=ether3-mgmt l2mtu=1600 comment="Gestion VLAN 999"
set [ find default-name=ether4 ] name=ether4-local l2mtu=1600 comment="Local opcional"
set [ find default-name=ether5 ] name=ether5-local l2mtu=1600 comment="Local opcional"

/interface wireless set [ find default-name=wlan1 ] disabled=yes

# --- S-VLAN 4000 ---
/interface vlan
add name=s-vlan-4000 interface=ether2-isp vlan-id=4000 mtu=1590 comment="Desencapsula Q-in-Q"

# --- BRIDGE ÚNICO CON VLAN FILTERING ---
/interface bridge
add name=BR-CORE vlan-filtering=yes protocol-mode=none comment="Bridge principal"

# --- BRIDGE PORTS ---
# s-vlan-4000 y ether1-to-sxt como trunk (todas las VLANs tagged)
# ether3-mgmt como acceso VLAN 999 untagged

/interface bridge port
add bridge=BR-CORE interface=s-vlan-4000 comment="Trunk Q-in-Q"
add bridge=BR-CORE interface=ether1-to-sxt comment="Trunk a SXT-MG"
add bridge=BR-CORE interface=ether3-mgmt pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes \
    comment="Acceso VLAN 999"

# --- BRIDGE VLAN TABLE ---
# Todas las C-VLANs pasan tagged por los trunks

/interface bridge vlan
add bridge=BR-CORE vlan-ids=10 tagged=BR-CORE,s-vlan-4000,ether1-to-sxt
add bridge=BR-CORE vlan-ids=20 tagged=BR-CORE,s-vlan-4000,ether1-to-sxt
add bridge=BR-CORE vlan-ids=90 tagged=BR-CORE,s-vlan-4000,ether1-to-sxt
add bridge=BR-CORE vlan-ids=96 tagged=BR-CORE,s-vlan-4000,ether1-to-sxt
add bridge=BR-CORE vlan-ids=201 tagged=BR-CORE,s-vlan-4000,ether1-to-sxt
add bridge=BR-CORE vlan-ids=999 tagged=BR-CORE,s-vlan-4000,ether1-to-sxt untagged=ether3-mgmt

# --- VLAN 999 PARA IP DE GESTIÓN ---
/interface vlan
add name=vlan999-mgmt interface=BR-CORE vlan-id=999 comment="Gestion"

# --- INTERFACE LISTS ---
/interface list
add name=MGMT comment="Gestion"
/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-mgmt list=MGMT

# --- IP ---
/ip address
add address=10.200.1.10/24 interface=vlan999-mgmt network=10.200.1.0 comment="IP Gestion"

# --- DNS Y RUTAS ---
/ip dns set servers=10.200.1.1,8.8.8.8
/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 comment="Default"
add dst-address=192.168.0.0/16 gateway=10.200.1.1 comment="VLANs corporativas"

# --- FIREWALL ---
/ip firewall filter
add chain=input action=accept connection-state=established,related
add chain=input action=drop connection-state=invalid
add chain=input action=accept protocol=icmp
add chain=input action=accept src-address=10.200.1.0/24
add chain=input action=accept src-address=192.168.0.0/16
add chain=input action=log log-prefix="MK02-DROP:"
add chain=input action=drop
add chain=forward action=accept connection-state=established,related
add chain=forward action=drop connection-state=invalid
add chain=forward action=accept

# --- MANGLE ---
/ip firewall mangle
add chain=forward action=change-mss new-mss=clamp-to-pmtu protocol=tcp tcp-flags=syn

# --- SERVICIOS ---
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes

/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=MGMT

# --- SNMP Y SISTEMA ---
/snmp set enabled=yes contact=protocolosinlambrica@gmail.com location="Magdalena"
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=10.200.1.1
/system logging add topics=error,critical,warning prefix=MK02

# --- BACKUP ---
/system scheduler
add name=backup interval=1d start-time=03:15:00 on-event="/system backup save name=MK02-auto"

# --- SCRIPTS ---
/system script
add name=test owner=admin source={
:foreach t in={"10.200.1.1";"10.200.1.50";"10.200.1.20"} do={
:put ("$t: " . [:pick "FAILOK" ([/ping $t count=1]*2) (([/ping $t count=1]*2)+2)])
}
}

add name=ver owner=admin source={
/interface bridge vlan print where bridge=BR-CORE
/interface bridge host print where bridge=BR-CORE
}

# --- GRAPHING ---
/tool graphing interface add interface=ether1-to-sxt
/tool graphing interface add interface=s-vlan-4000
/tool graphing resource add

# ============================================================================
# VERIFICACIÓN: /system script run test
# VER CONFIG: /system script run ver
# ============================================================================
