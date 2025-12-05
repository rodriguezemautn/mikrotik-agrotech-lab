# ============================================================================
# MK01 - AJUSTES PARA CABLE DIRECTO (Sin Q-in-Q)
# ============================================================================
#
# EJECUTAR EN MK01 PARA CAMBIAR DE Q-in-Q A TRUNK DIRECTO
#
# ANTES: MK01 --[Q-in-Q S-VLAN 4000]--> Switch ISP --> MK02
# AHORA: MK01 --[Trunk VLANs directo]--> MK02
#
# ============================================================================

# ============================================================================
# OPCIÓN 1: COMANDOS PARA MODIFICAR MK01 EXISTENTE
# ============================================================================

# Paso 1: Remover configuración Q-in-Q existente
/interface vlan remove [find where name~"qinq"]
/interface vlan remove [find where name="s-vlan-4000"]

# Paso 2: Agregar ether2 al bridge local como trunk
/interface bridge port add bridge=BR-LOCAL interface=ether2-isp comment="Trunk directo a MK02"

# Paso 3: Agregar ether2 a la tabla de VLANs del bridge
/interface bridge vlan
set [find vlan-ids=10 bridge=BR-LOCAL] tagged=BR-LOCAL,ether2-isp
set [find vlan-ids=20 bridge=BR-LOCAL] tagged=BR-LOCAL,ether2-isp
set [find vlan-ids=90 bridge=BR-LOCAL] tagged=BR-LOCAL,ether2-isp
set [find vlan-ids=96 bridge=BR-LOCAL] tagged=BR-LOCAL,ether2-isp
set [find vlan-ids=201 bridge=BR-LOCAL] tagged=BR-LOCAL,ether2-isp
set [find vlan-ids=999 bridge=BR-LOCAL] tagged=BR-LOCAL,ether2-isp

# Paso 4: Verificar
/interface bridge port print where interface=ether2-isp
/interface bridge vlan print where bridge=BR-LOCAL


# ============================================================================
# OPCIÓN 2: SI PREFIERES CONFIGURACIÓN COMPLETA LIMPIA DE MK01
# ============================================================================
# Ejecutar reset y luego importar esta configuración completa:

# /system reset-configuration no-defaults=yes skip-backup=yes
# (esperar reinicio)
# /import file=MK01-trunk-directo.rsc


# ============================================================================
# CONFIGURACIÓN COMPLETA MK01 (Para reset limpio)
# ============================================================================

/system identity set name=MK01-agrotech-lp-gw

# --- INTERFACES ---
/interface ethernet
set [ find default-name=ether1 ] name=ether1-wan comment="WAN Internet"
set [ find default-name=ether2 ] name=ether2-trunk comment="Trunk a MK02 (directo)"
set [ find default-name=ether3 ] name=ether3-mgmt comment="Management"
set [ find default-name=ether4 ] name=ether4-local comment="VLAN 10 Servers"
set [ find default-name=ether5 ] name=ether5-local comment="VLAN 201 CCTV"

# --- BRIDGE CON VLAN FILTERING ---
/interface bridge
add name=BR-LOCAL vlan-filtering=yes comment="Bridge principal con VLANs"

# --- BRIDGE PORTS ---
/interface bridge port
add bridge=BR-LOCAL interface=ether2-trunk comment="Trunk a MK02"
add bridge=BR-LOCAL interface=ether3-mgmt pvid=999 frame-types=admit-only-untagged-and-priority-tagged comment="MGMT untagged"
add bridge=BR-LOCAL interface=ether4-local pvid=10 frame-types=admit-only-untagged-and-priority-tagged comment="VLAN 10 untagged"
add bridge=BR-LOCAL interface=ether5-local pvid=201 frame-types=admit-only-untagged-and-priority-tagged comment="VLAN 201 untagged"

# --- BRIDGE VLAN TABLE ---
/interface bridge vlan
add bridge=BR-LOCAL vlan-ids=10 tagged=BR-LOCAL,ether2-trunk untagged=ether4-local
add bridge=BR-LOCAL vlan-ids=20 tagged=BR-LOCAL,ether2-trunk
add bridge=BR-LOCAL vlan-ids=90 tagged=BR-LOCAL,ether2-trunk
add bridge=BR-LOCAL vlan-ids=96 tagged=BR-LOCAL,ether2-trunk
add bridge=BR-LOCAL vlan-ids=201 tagged=BR-LOCAL,ether2-trunk untagged=ether5-local
add bridge=BR-LOCAL vlan-ids=999 tagged=BR-LOCAL,ether2-trunk untagged=ether3-mgmt

# --- VLANs PARA IPs ---
/interface vlan
add name=vlan10 interface=BR-LOCAL vlan-id=10 comment="Servers"
add name=vlan20 interface=BR-LOCAL vlan-id=20 comment="Desktop"
add name=vlan90 interface=BR-LOCAL vlan-id=90 comment="Private WiFi"
add name=vlan96 interface=BR-LOCAL vlan-id=96 comment="Guest"
add name=vlan201 interface=BR-LOCAL vlan-id=201 comment="CCTV"
add name=vlan999 interface=BR-LOCAL vlan-id=999 comment="Management"

# --- IPs ---
/ip address
add address=192.168.10.1/24 interface=vlan10 comment="Gateway VLAN 10"
add address=192.168.20.1/24 interface=vlan20 comment="Gateway VLAN 20"
add address=192.168.90.1/24 interface=vlan90 comment="Gateway VLAN 90"
add address=192.168.96.1/24 interface=vlan96 comment="Gateway VLAN 96"
add address=192.168.201.1/24 interface=vlan201 comment="Gateway VLAN 201"
add address=10.200.1.1/24 interface=vlan999 comment="Gateway Management"

# --- DHCP POOLS ---
/ip pool
add name=pool-vlan10 ranges=192.168.10.100-192.168.10.250
add name=pool-vlan20 ranges=192.168.20.100-192.168.20.250
add name=pool-vlan90 ranges=192.168.90.100-192.168.90.250
add name=pool-vlan96 ranges=192.168.96.100-192.168.96.250
add name=pool-vlan201 ranges=192.168.201.100-192.168.201.250

# --- DHCP SERVERS ---
/ip dhcp-server
add name=dhcp-vlan10 interface=vlan10 address-pool=pool-vlan10 disabled=no
add name=dhcp-vlan20 interface=vlan20 address-pool=pool-vlan20 disabled=no
add name=dhcp-vlan90 interface=vlan90 address-pool=pool-vlan90 disabled=no
add name=dhcp-vlan96 interface=vlan96 address-pool=pool-vlan96 disabled=no
add name=dhcp-vlan201 interface=vlan201 address-pool=pool-vlan201 disabled=no

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=192.168.90.1
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=192.168.96.1
add address=192.168.201.0/24 gateway=192.168.201.1 dns-server=192.168.201.1

# --- DHCP CLIENT WAN ---
/ip dhcp-client
add interface=ether1-wan disabled=no

# --- DNS ---
/ip dns
set servers=8.8.8.8,1.1.1.1 allow-remote-requests=yes

# --- NAT ---
/ip firewall nat
add chain=srcnat out-interface=ether1-wan action=masquerade comment="NAT Internet"

# --- FIREWALL BÁSICO ---
/ip firewall filter
add chain=input action=accept connection-state=established,related
add chain=input action=drop connection-state=invalid
add chain=input action=accept protocol=icmp
add chain=input action=accept src-address=10.200.1.0/24
add chain=input action=accept src-address=192.168.0.0/16
add chain=input action=drop

add chain=forward action=accept connection-state=established,related
add chain=forward action=drop connection-state=invalid
add chain=forward action=drop src-address=192.168.96.0/24 dst-address=192.168.0.0/16 comment="Guest isolation"
add chain=forward action=accept

# --- SERVICIOS ---
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes

# --- SISTEMA ---
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=200.23.1.7

# ============================================================================
# VERIFICACIÓN:
# /ping 10.200.1.10  (debe responder MK02)
# /interface bridge host print  (debe mostrar MACs de MK02)
# ============================================================================
