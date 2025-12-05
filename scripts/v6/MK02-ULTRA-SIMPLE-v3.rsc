# ============================================================================
# MK02 - CONFIGURACIÓN ULTRA SIMPLE v3.0
# ============================================================================
# 
# OBJETIVO: Configuración mínima funcional para diagnosticar
# CONEXIÓN: Cable directo MK01-ether2 <---> MK02-ether2
#
# OPCIÓN A: Con Q-in-Q (S-VLAN 4000)
# OPCIÓN B: Sin Q-in-Q (trunk directo) - MÁS SIMPLE PARA PRUEBAS
#
# ============================================================================

/system identity set name=MK02-agrotech-mg-ap

# ============================================================================
# PASO 1: INTERFACES ETHERNET
# ============================================================================
/interface ethernet
set [ find default-name=ether1 ] name=ether1-to-sxt mtu=1500 comment="Trunk a SXT-MG"
set [ find default-name=ether2 ] name=ether2-uplink mtu=1500 comment="Uplink a MK01"
set [ find default-name=ether3 ] name=ether3-mgmt comment="Gestion"
set [ find default-name=ether4 ] name=ether4-local comment="Local"
set [ find default-name=ether5 ] name=ether5-local comment="Local"

/interface wireless set [ find default-name=wlan1 ] disabled=yes

# ============================================================================
# PASO 2: BRIDGE ÚNICO - TRANSPORTE TRANSPARENTE
# ============================================================================
# CRÍTICO: vlan-filtering=no para transporte L2 puro

/interface bridge
add name=BR-TRANSPORT vlan-filtering=no protocol-mode=none \
    comment="Bridge transporte L2 - VLANs pasan intactas"

# ============================================================================
# PASO 3: PUERTOS DEL BRIDGE
# ============================================================================
# Bridgeamos directamente ether2 con ether1
# Las VLANs tagged pasan transparentes

/interface bridge port
add bridge=BR-TRANSPORT interface=ether2-uplink comment="Uplink desde MK01"
add bridge=BR-TRANSPORT interface=ether1-to-sxt comment="Downlink a SXT-MG"

# ============================================================================
# PASO 4: VLAN 999 PARA GESTIÓN
# ============================================================================
/interface vlan
add name=vlan999 interface=BR-TRANSPORT vlan-id=999 comment="Gestion"

# ============================================================================
# PASO 5: IP DE GESTIÓN
# ============================================================================
/ip address
add address=10.200.1.10/24 interface=vlan999 comment="IP Gestion MK02"

# ============================================================================
# PASO 6: DNS Y RUTA
# ============================================================================
/ip dns set servers=10.200.1.1
/ip route add dst-address=0.0.0.0/0 gateway=10.200.1.1

# ============================================================================
# PASO 7: FIREWALL MÍNIMO
# ============================================================================
/ip firewall filter
add chain=input action=accept connection-state=established,related
add chain=input action=accept protocol=icmp
add chain=input action=accept src-address=10.200.1.0/24
add chain=input action=accept src-address=192.168.0.0/16
add chain=input action=drop
add chain=forward action=accept

# ============================================================================
# PASO 8: SERVICIOS
# ============================================================================
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes

# ============================================================================
# PASO 9: SISTEMA
# ============================================================================
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=10.200.1.1

# ============================================================================
# VERIFICACIÓN INMEDIATA - EJECUTAR DESPUÉS DE IMPORTAR:
# ============================================================================
#
# 1. Ver bridge ports (DEBE mostrar ether2-uplink y ether1-to-sxt):
#    /interface bridge port print
#
# 2. Test ping:
#    /ping 10.200.1.1
#    /ping 10.200.1.50
#
# 3. Ver MACs aprendidas:
#    /interface bridge host print
#
# ============================================================================
