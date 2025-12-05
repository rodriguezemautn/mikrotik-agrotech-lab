# ============================================================================
# MK02-agrotech-mg-ap - CONFIGURACIÓN SIMPLIFICADA v2.1
# ============================================================================
# 
# DISPOSITIVO: MikroTik RB951Ui-2HnD  |  RouterOS 6.49.x
# FUNCIÓN: Hub de transporte L2 transparente - Desencapsulador Q-in-Q
# UBICACIÓN: Magdalena Ciudad - Oficina
# IP GESTIÓN: 10.200.1.10/24
# 
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                        DIAGRAMA DE FLUJO                                │
# │                                                                         │
# │   MK01 (La Plata)                                                       │
# │        │                                                                │
# │        │ Q-in-Q: S-VLAN 4000 contiene C-VLANs (10,20,90,96,201,999)     │
# │        ▼                                                                │
# │   [ether2-isp]                                                          │
# │        │                                                                │
# │        ▼                                                                │
# │   [s-vlan-4000]  ◄── Remueve S-tag, C-VLANs quedan intactas            │
# │        │                                                                │
# │        ▼                                                                │
# │   [BR-TRANSPORT] ◄── Bridge SIN vlan-filtering (transparente)          │
# │        │                                                                │
# │        ├──────────────────────────────────────────┐                     │
# │        │                                          │                     │
# │        ▼                                          ▼                     │
# │   [ether1-to-sxt]                          [vlan999-mgmt]               │
# │        │                                     10.200.1.10                │
# │        │                                          ▲                     │
# │        ▼                                          │                     │
# │   SXT-MG ──► Campo                         [ether3-mgmt]                │
# │                                            (acceso untagged)            │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ============================================================================
# PASO 1: IDENTIDAD DEL SISTEMA
# ============================================================================
/system identity set name=MK02-agrotech-mg-ap

# ============================================================================
# PASO 2: INTERFACES ETHERNET
# ============================================================================
/interface ethernet
set [ find default-name=ether1 ] name=ether1-to-sxt l2mtu=1600 mtu=1590 \
    comment="Trunk hacia SXT-MG (PTP 8km)"
set [ find default-name=ether2 ] name=ether2-isp l2mtu=1600 mtu=1590 \
    comment="Q-in-Q desde MK01 (ISP)"
set [ find default-name=ether3 ] name=ether3-mgmt l2mtu=1600 \
    comment="Acceso Gestion VLAN 999 untagged"
set [ find default-name=ether4 ] name=ether4-local l2mtu=1600 \
    comment="Puerto local opcional"
set [ find default-name=ether5 ] name=ether5-local l2mtu=1600 \
    comment="Puerto local opcional"

# Deshabilitar wireless (no usado)
/interface wireless set [ find default-name=wlan1 ] disabled=yes \
    comment="Reservado futuro"

# ============================================================================
# PASO 3: S-VLAN 4000 (Desencapsulación Q-in-Q)
# ============================================================================
# Esta VLAN remueve el Service Tag (4000) del ISP
# El contenido son frames con C-VLANs intactas

/interface vlan
add name=s-vlan-4000 interface=ether2-isp vlan-id=4000 mtu=1590 \
    comment="S-VLAN 4000 - Desencapsula Q-in-Q del ISP"

# ============================================================================
# PASO 4: BRIDGE DE TRANSPORTE TRANSPARENTE
# ============================================================================
# CRÍTICO: vlan-filtering=no para que las C-VLANs pasen sin modificación

/interface bridge
add name=BR-TRANSPORT vlan-filtering=no protocol-mode=none \
    comment="Transporte L2 transparente - C-VLANs pasan intactas"

# ============================================================================
# PASO 5: PUERTOS DEL BRIDGE DE TRANSPORTE
# ============================================================================
/interface bridge port
add bridge=BR-TRANSPORT interface=s-vlan-4000 \
    comment="Entrada: contenido Q-in-Q (C-VLANs)"
add bridge=BR-TRANSPORT interface=ether1-to-sxt \
    comment="Salida: trunk hacia SXT-MG"

# ============================================================================
# PASO 6: VLAN 999 PARA GESTIÓN
# ============================================================================
# Extraemos VLAN 999 del bridge de transporte

/interface vlan
add name=vlan999-mgmt interface=BR-TRANSPORT vlan-id=999 \
    comment="VLAN 999 Gestion - extraida del transporte"

# ============================================================================
# PASO 7: BRIDGE PARA ACCESO LOCAL (ether3 untagged)
# ============================================================================
# Bridge con vlan-filtering para dar acceso untagged a VLAN 999

/interface bridge
add name=BR-MGMT-ACCESS vlan-filtering=yes protocol-mode=none \
    comment="Bridge acceso gestion local"

/interface bridge port
add bridge=BR-MGMT-ACCESS interface=ether3-mgmt pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes \
    comment="ether3 acceso VLAN 999 untagged"

/interface bridge vlan
add bridge=BR-MGMT-ACCESS vlan-ids=999 untagged=ether3-mgmt tagged=BR-MGMT-ACCESS

# VLAN 999 sobre el bridge de acceso
/interface vlan
add name=vlan999-access interface=BR-MGMT-ACCESS vlan-id=999 \
    comment="VLAN 999 desde acceso local"

# ============================================================================
# PASO 8: UNIR AMBAS VLAN 999 (transporte + acceso local)
# ============================================================================
/interface bridge
add name=BR-MGMT-UNION vlan-filtering=no protocol-mode=none \
    comment="Une VLAN 999 transporte con acceso local"

/interface bridge port
add bridge=BR-MGMT-UNION interface=vlan999-mgmt comment="VLAN 999 transporte"
add bridge=BR-MGMT-UNION interface=vlan999-access comment="VLAN 999 acceso"

# ============================================================================
# PASO 9: INTERFACE LISTS
# ============================================================================
/interface list
add name=MGMT comment="Interfaces de gestion"
add name=TRANSPORT comment="Interfaces de transporte"

/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-mgmt list=MGMT
add interface=BR-MGMT-UNION list=MGMT
add interface=ether1-to-sxt list=TRANSPORT
add interface=ether2-isp list=TRANSPORT
add interface=BR-TRANSPORT list=TRANSPORT

# ============================================================================
# PASO 10: DIRECCIONAMIENTO IP
# ============================================================================
/ip address
add address=10.200.1.10/24 interface=BR-MGMT-UNION network=10.200.1.0 \
    comment="IP Gestion MK02"

# ============================================================================
# PASO 11: DNS Y RUTAS
# ============================================================================
/ip dns
set servers=10.200.1.1,8.8.8.8 allow-remote-requests=no

/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 distance=1 comment="Default via MK01"
add dst-address=192.168.10.0/24 gateway=10.200.1.1 distance=1 comment="VLAN 10 Servers"
add dst-address=192.168.20.0/24 gateway=10.200.1.1 distance=1 comment="VLAN 20 Desktop"
add dst-address=192.168.90.0/24 gateway=10.200.1.1 distance=1 comment="VLAN 90 Private"
add dst-address=192.168.96.0/24 gateway=10.200.1.1 distance=1 comment="VLAN 96 Guest"
add dst-address=192.168.201.0/24 gateway=10.200.1.1 distance=1 comment="VLAN 201 CCTV"

# ============================================================================
# PASO 12: FIREWALL
# ============================================================================
/ip firewall filter
# INPUT
add chain=input action=accept connection-state=established,related \
    comment="INPUT: established/related"
add chain=input action=drop connection-state=invalid comment="INPUT: drop invalid"
add chain=input action=accept protocol=icmp icmp-options=8:0 comment="INPUT: ICMP"
add chain=input action=accept src-address=10.200.1.0/24 comment="INPUT: desde MGMT"
add chain=input action=accept src-address=192.168.0.0/16 comment="INPUT: desde VLANs corp"
add chain=input action=log log-prefix="MK02-DROP: " comment="INPUT: log drop"
add chain=input action=drop comment="INPUT: drop all"

# FORWARD
add chain=forward action=accept connection-state=established,related \
    comment="FWD: established/related"
add chain=forward action=drop connection-state=invalid comment="FWD: drop invalid"
add chain=forward action=accept comment="FWD: accept all (L2 bridge)"

# ============================================================================
# PASO 13: MANGLE - MSS CLAMPING
# ============================================================================
/ip firewall mangle
add chain=forward action=change-mss new-mss=clamp-to-pmtu protocol=tcp \
    tcp-flags=syn passthrough=yes comment="MSS Clamp Q-in-Q"

# ============================================================================
# PASO 14: SERVICIOS Y SEGURIDAD
# ============================================================================
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set www disabled=no
set ssh disabled=no
set winbox disabled=no

/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/tool mac-server ping set enabled=yes

# ============================================================================
# PASO 15: SNMP Y LOGGING
# ============================================================================
/snmp
set enabled=yes contact=protocolosinlambrica@gmail.com \
    location="Magdalena Ciudad - Hub Q-in-Q" trap-version=2

/system logging
add topics=error,critical,warning prefix=MK02
add topics=bridge prefix=MK02-BR

# ============================================================================
# PASO 16: RELOJ Y NTP
# ============================================================================
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7

# ============================================================================
# PASO 17: BACKUP AUTOMÁTICO
# ============================================================================
/system scheduler
add name=daily-backup interval=1d start-time=03:15:00 on-event=\
    "/system backup save name=(\"MK02-\" . [:pick [/system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4 6]); /export file=(\"MK02-export-\" . [:pick [/system clock get date] 7 11])" \
    comment="Backup diario 03:15"

# ============================================================================
# PASO 18: SCRIPTS DE DIAGNÓSTICO
# ============================================================================

/system script

add name=test-conectividad owner=admin comment="Test ping a toda la topologia" source={
:log info "=== TEST CONECTIVIDAD MK02 ==="
:local ok 0
:local fail 0

:foreach t in={"10.200.1.1";"10.200.1.50";"10.200.1.51";"10.200.1.20";"10.200.1.21";"10.200.1.22";"10.200.1.25"} do={
    :if ([/ping $t count=2] > 0) do={
        :put ("OK: $t")
        :set ok ($ok + 1)
    } else={
        :put ("FAIL: $t")
        :set fail ($fail + 1)
    }
}
:put ""
:put ("Resultado: $ok OK, $fail FAIL")
:log info "=== FIN TEST ==="
}

add name=ver-transporte owner=admin comment="Ver estado transporte Q-in-Q" source={
:put "=== ESTADO TRANSPORTE ==="
:put ""
:put ">>> Interfaces:"
/interface print stats where name~"ether1|ether2|s-vlan|BR-TRANSPORT"
:put ""
:put ">>> Bridge ports:"
/interface bridge port print where bridge=BR-TRANSPORT
:put ""
:put ">>> MACs aprendidas:"
/interface bridge host print where bridge=BR-TRANSPORT
:put "=== FIN ==="
}

add name=diag-rapido owner=admin comment="Diagnostico rapido" source={
:put "=== DIAG RAPIDO MK02 ==="
:put ("Uptime: " . [/system resource get uptime])
:put ("CPU: " . [/system resource get cpu-load] . "%")
:put ("Mem libre: " . ([/system resource get free-memory]/1048576) . "MB")
:put ""
:put "Ping MK01: " . [:pick "FAILOK" ([/ping 10.200.1.1 count=1]*2) (([/ping 10.200.1.1 count=1]*2)+2)]
:put "Ping SXT-MG: " . [:pick "FAILOK" ([/ping 10.200.1.50 count=1]*2) (([/ping 10.200.1.50 count=1]*2)+2)]
:put "Ping MK03: " . [:pick "FAILOK" ([/ping 10.200.1.20 count=1]*2) (([/ping 10.200.1.20 count=1]*2)+2)]
:put "=== FIN ==="
}

# ============================================================================
# PASO 19: GRAPHING
# ============================================================================
/tool graphing interface
add interface=ether1-to-sxt
add interface=ether2-isp
add interface=BR-TRANSPORT

/tool graphing resource
add

# ============================================================================
# PASO 20: BANDWIDTH TEST SERVER
# ============================================================================
/tool bandwidth-server set enabled=yes authenticate=yes max-sessions=5

# ============================================================================
# FIN CONFIGURACIÓN - INSTRUCCIONES
# ============================================================================
#
# APLICAR CONFIGURACIÓN:
# ----------------------
# 
# Método 1 - Reset completo (RECOMENDADO):
#   1. Conectar cable a ether3
#   2. Acceder por Winbox/SSH
#   3. /system reset-configuration no-defaults=yes skip-backup=yes
#   4. Esperar reinicio (2-3 min)
#   5. Conectar nuevamente, IP default: 192.168.88.1
#   6. /import file=MK02-agrotech-mg-ap-v2.1.rsc
#
# Método 2 - Sobre configuración existente:
#   1. Backup: /system backup save name=MK02-antes
#   2. Limpiar bridges existentes manualmente
#   3. Importar secciones una por una
#
# VERIFICACIÓN POST-INSTALACIÓN:
# ------------------------------
#   /system script run diag-rapido
#   /system script run test-conectividad
#   /system script run ver-transporte
#
# Si todo OK, deberías ver:
#   - Ping OK a MK01 (10.200.1.1)
#   - Ping OK a SXT-MG (10.200.1.50)  
#   - Ping OK a MK03 (10.200.1.20)
#   - MACs aprendidas en BR-TRANSPORT de ambos lados
#
# TROUBLESHOOTING:
# ----------------
#   - No hay ping a MK01: Verificar ether2-isp y s-vlan-4000
#   - No hay ping a SXT-MG: Verificar ether1-to-sxt y cable
#   - No hay MACs: El bridge no está pasando tráfico
#
# ============================================================================
