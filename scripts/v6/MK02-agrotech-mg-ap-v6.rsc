# ============================================================================
# MK02-agrotech-mg-ap - CONFIGURACIÓN CORREGIDA v2.0
# ============================================================================
# 
# DISPOSITIVO: MikroTik RB951Ui-2HnD
# FUNCIÓN: Hub de transporte L2 transparente - Desencapsulador Q-in-Q
# UBICACIÓN: Magdalena Ciudad - Oficina
# 
# TOPOLOGÍA:
#   MK01 (La Plata) ──[Q-in-Q VLAN 4000]──> MK02 ──[Trunk]──> SXT-MG ──[PTP]──> Campo
#
# PROBLEMA ORIGINAL:
#   - Se creaban VLANs sobre s-vlan-4000-in y se agregaban al bridge
#   - Esto desencapsulaba las C-VLANs antes de entrar al bridge
#   - El bridge con vlan-filtering=yes no encontraba los tags esperados
#   - Resultado: tráfico descartado, sin conectividad hacia el campo
#
# SOLUCIÓN:
#   - Bridge de transporte SIN vlan-filtering
#   - Bridgear directamente s-vlan-4000-in con ether1-to-sxt
#   - Las C-VLANs (10, 20, 90, 96, 201, 999) pasan INTACTAS
#   - Gestión local via VLAN 999 extraída del bridge de transporte
#
# FECHA: Diciembre 2025
# VERSIÓN: 6.0 - Corrección completa
# ============================================================================

# ============================================================================
# SECCIÓN 1: RESET Y PREPARACIÓN INICIAL
# ============================================================================
# ADVERTENCIA: Ejecutar este script RESETEARÁ la configuración del equipo
# Asegúrese de tener acceso físico o por consola serial antes de ejecutar

/system identity set name=MK02-agrotech-mg-ap

# ============================================================================
# SECCIÓN 2: CONFIGURACIÓN DE INTERFACES ETHERNET
# ============================================================================

/interface ethernet
set [ find default-name=ether1 ] \
    name=ether1-to-sxt \
    comment="Trunk to SXT-MG (enlace PTP 8km) - Transporta C-VLANs tagged" \
    l2mtu=1600 \
    mtu=1590

set [ find default-name=ether2 ] \
    name=ether2-isp \
    comment="ISP Q-in-Q Trunk from MK01 - Recibe S-VLAN 4000" \
    l2mtu=1600 \
    mtu=1590

set [ find default-name=ether3 ] \
    name=ether3-mgmt \
    comment="Management Access - VLAN 999 Untagged" \
    l2mtu=1600

set [ find default-name=ether4 ] \
    name=ether4-local \
    comment="Puerto local opcional - Trunk VLANs" \
    l2mtu=1600

set [ find default-name=ether5 ] \
    name=ether5-local \
    comment="Puerto local opcional - Trunk VLANs" \
    l2mtu=1600

# ============================================================================
# SECCIÓN 3: CONFIGURACIÓN WIRELESS (Deshabilitado - reservado para futuro)
# ============================================================================

/interface wireless
set [ find default-name=wlan1 ] \
    disabled=yes \
    comment="Reservado para AP local futuro" \
    ssid=MK02-Reserved

# ============================================================================
# SECCIÓN 4: INTERFAZ S-VLAN 4000 (Desencapsulación Q-in-Q)
# ============================================================================
# Esta VLAN extrae el Service Tag (4000) del ISP
# El contenido son las C-VLANs (10, 20, 90, 96, 201, 999) con sus tags intactos

/interface vlan
add name=s-vlan-4000-transport \
    interface=ether2-isp \
    vlan-id=4000 \
    mtu=1590 \
    comment="S-VLAN 4000 - Desencapsula Q-in-Q, C-VLANs pasan intactas"

# ============================================================================
# SECCIÓN 5: BRIDGE DE TRANSPORTE L2 (SIN VLAN FILTERING)
# ============================================================================
# CRÍTICO: vlan-filtering=no permite que las C-VLANs pasen transparentemente
# protocol-mode=none evita STP que podría causar problemas en la topología

/interface bridge
add name=BR-TRANSPORT \
    comment="Bridge L2 Transporte Transparente - C-VLANs pasan intactas" \
    vlan-filtering=no \
    protocol-mode=none \
    admin-mac=auto \
    auto-mac=yes \
    fast-forward=yes

# ============================================================================
# SECCIÓN 6: PUERTOS DEL BRIDGE DE TRANSPORTE
# ============================================================================
# Solo dos puertos: entrada Q-in-Q desencapsulada y salida hacia SXT-MG

/interface bridge port
add bridge=BR-TRANSPORT \
    interface=s-vlan-4000-transport \
    comment="Entrada: C-VLANs desde Q-in-Q (S-VLAN 4000 removida)" \
    hw=yes

add bridge=BR-TRANSPORT \
    interface=ether1-to-sxt \
    comment="Salida: Trunk hacia SXT-MG con C-VLANs tagged" \
    hw=yes

# ============================================================================
# SECCIÓN 7: VLAN DE GESTIÓN (999)
# ============================================================================
# Extraemos VLAN 999 del bridge de transporte para gestión local
# Esto permite acceder al equipo desde la red de management

/interface vlan
add name=vlan999-mgmt \
    interface=BR-TRANSPORT \
    vlan-id=999 \
    comment="VLAN 999 - Gestión extraída del transporte"

# ============================================================================
# SECCIÓN 8: BRIDGE DE ACCESO LOCAL (Para ether3-mgmt)
# ============================================================================
# Bridge separado para acceso de gestión local con VLAN filtering
# Permite conectar notebook en ether3 sin tag y acceder a VLAN 999

/interface bridge
add name=BR-MGMT-ACCESS \
    comment="Bridge acceso gestión local - ether3 untagged VLAN 999" \
    vlan-filtering=yes \
    protocol-mode=none

/interface bridge port
add bridge=BR-MGMT-ACCESS \
    interface=ether3-mgmt \
    pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Puerto gestión - VLAN 999 untagged"

/interface bridge vlan
add bridge=BR-MGMT-ACCESS \
    vlan-ids=999 \
    untagged=ether3-mgmt \
    tagged=BR-MGMT-ACCESS

# VLAN 999 sobre el bridge de acceso para conectar con la de transporte
/interface vlan
add name=vlan999-access \
    interface=BR-MGMT-ACCESS \
    vlan-id=999 \
    comment="VLAN 999 desde bridge de acceso local"

# ============================================================================
# SECCIÓN 9: BRIDGE PARA UNIR AMBAS VLAN 999
# ============================================================================
# Unimos las dos interfaces VLAN 999 para que el tráfico fluya

/interface bridge
add name=BR-MGMT-UNION \
    comment="Une VLAN 999 transporte con VLAN 999 acceso local" \
    vlan-filtering=no \
    protocol-mode=none

/interface bridge port
add bridge=BR-MGMT-UNION \
    interface=vlan999-mgmt \
    comment="VLAN 999 desde transporte Q-in-Q"

add bridge=BR-MGMT-UNION \
    interface=vlan999-access \
    comment="VLAN 999 desde acceso local ether3"

# ============================================================================
# SECCIÓN 10: PUERTOS LOCALES OPCIONALES (ether4, ether5)
# ============================================================================
# Configuración para puertos locales que pueden usarse como trunk o acceso

/interface bridge
add name=BR-LOCAL-OPTIONAL \
    comment="Bridge para puertos locales opcionales" \
    vlan-filtering=yes \
    protocol-mode=none

/interface bridge port
add bridge=BR-LOCAL-OPTIONAL \
    interface=ether4-local \
    comment="Puerto local 4 - Trunk todas las VLANs" \
    hw=yes

add bridge=BR-LOCAL-OPTIONAL \
    interface=ether5-local \
    comment="Puerto local 5 - Trunk todas las VLANs" \
    hw=yes

# Tabla de VLANs para puertos locales
/interface bridge vlan
add bridge=BR-LOCAL-OPTIONAL vlan-ids=10 tagged=BR-LOCAL-OPTIONAL,ether4-local,ether5-local
add bridge=BR-LOCAL-OPTIONAL vlan-ids=20 tagged=BR-LOCAL-OPTIONAL,ether4-local,ether5-local
add bridge=BR-LOCAL-OPTIONAL vlan-ids=90 tagged=BR-LOCAL-OPTIONAL,ether4-local,ether5-local
add bridge=BR-LOCAL-OPTIONAL vlan-ids=96 tagged=BR-LOCAL-OPTIONAL,ether4-local,ether5-local
add bridge=BR-LOCAL-OPTIONAL vlan-ids=201 tagged=BR-LOCAL-OPTIONAL,ether4-local,ether5-local
add bridge=BR-LOCAL-OPTIONAL vlan-ids=999 tagged=BR-LOCAL-OPTIONAL,ether4-local,ether5-local

# Conectar puertos locales al transporte principal
# Crear VLANs sobre BR-LOCAL-OPTIONAL y bridgearlas con el transporte
/interface vlan
add name=vlan10-local interface=BR-LOCAL-OPTIONAL vlan-id=10 comment="VLAN 10 local"
add name=vlan20-local interface=BR-LOCAL-OPTIONAL vlan-id=20 comment="VLAN 20 local"
add name=vlan90-local interface=BR-LOCAL-OPTIONAL vlan-id=90 comment="VLAN 90 local"
add name=vlan96-local interface=BR-LOCAL-OPTIONAL vlan-id=96 comment="VLAN 96 local"
add name=vlan201-local interface=BR-LOCAL-OPTIONAL vlan-id=201 comment="VLAN 201 local"
add name=vlan999-local interface=BR-LOCAL-OPTIONAL vlan-id=999 comment="VLAN 999 local"

# VLANs sobre el transporte para conectar con locales
/interface vlan
add name=vlan10-transport interface=BR-TRANSPORT vlan-id=10 comment="VLAN 10 transporte"
add name=vlan20-transport interface=BR-TRANSPORT vlan-id=20 comment="VLAN 20 transporte"
add name=vlan90-transport interface=BR-TRANSPORT vlan-id=90 comment="VLAN 90 transporte"
add name=vlan96-transport interface=BR-TRANSPORT vlan-id=96 comment="VLAN 96 transporte"
add name=vlan201-transport interface=BR-TRANSPORT vlan-id=201 comment="VLAN 201 transporte"

# Bridges para unir cada VLAN local con transporte
/interface bridge
add name=BR-VLAN10-UNION vlan-filtering=no protocol-mode=none comment="Une VLAN 10"
add name=BR-VLAN20-UNION vlan-filtering=no protocol-mode=none comment="Une VLAN 20"
add name=BR-VLAN90-UNION vlan-filtering=no protocol-mode=none comment="Une VLAN 90"
add name=BR-VLAN96-UNION vlan-filtering=no protocol-mode=none comment="Une VLAN 96"
add name=BR-VLAN201-UNION vlan-filtering=no protocol-mode=none comment="Une VLAN 201"

/interface bridge port
add bridge=BR-VLAN10-UNION interface=vlan10-local
add bridge=BR-VLAN10-UNION interface=vlan10-transport
add bridge=BR-VLAN20-UNION interface=vlan20-local
add bridge=BR-VLAN20-UNION interface=vlan20-transport
add bridge=BR-VLAN90-UNION interface=vlan90-local
add bridge=BR-VLAN90-UNION interface=vlan90-transport
add bridge=BR-VLAN96-UNION interface=vlan96-local
add bridge=BR-VLAN96-UNION interface=vlan96-transport
add bridge=BR-VLAN201-UNION interface=vlan201-local
add bridge=BR-VLAN201-UNION interface=vlan201-transport

# Agregar vlan999-local al bridge de unión de gestión
/interface bridge port
add bridge=BR-MGMT-UNION interface=vlan999-local comment="VLAN 999 desde puertos locales"

# ============================================================================
# SECCIÓN 11: INTERFACE LISTS
# ============================================================================

/interface list
add name=MGMT comment="Interfaces de gestión"
add name=LAN comment="Interfaces LAN"
add name=WAN comment="Interfaces WAN/Uplink"

/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-mgmt list=MGMT
add interface=BR-MGMT-UNION list=MGMT
add interface=ether1-to-sxt list=WAN
add interface=ether2-isp list=WAN

# ============================================================================
# SECCIÓN 12: DIRECCIONAMIENTO IP
# ============================================================================

/ip address
add address=10.200.1.10/24 \
    interface=BR-MGMT-UNION \
    network=10.200.1.0 \
    comment="IP de Gestión MK02 - VLAN 999"

# ============================================================================
# SECCIÓN 13: CONFIGURACIÓN DNS
# ============================================================================

/ip dns
set servers=10.200.1.1,8.8.8.8 \
    allow-remote-requests=no \
    cache-size=2048KiB

# ============================================================================
# SECCIÓN 14: RUTAS ESTÁTICAS
# ============================================================================

/ip route
add dst-address=0.0.0.0/0 \
    gateway=10.200.1.1 \
    distance=1 \
    comment="Default route via MK01"

add dst-address=192.168.10.0/24 \
    gateway=10.200.1.1 \
    distance=1 \
    comment="VLAN 10 - Servers via MK01"

add dst-address=192.168.20.0/24 \
    gateway=10.200.1.1 \
    distance=1 \
    comment="VLAN 20 - Desktop via MK01"

add dst-address=192.168.90.0/24 \
    gateway=10.200.1.1 \
    distance=1 \
    comment="VLAN 90 - Private WiFi via MK01"

add dst-address=192.168.96.0/24 \
    gateway=10.200.1.1 \
    distance=1 \
    comment="VLAN 96 - Guest WiFi via MK01"

add dst-address=192.168.201.0/24 \
    gateway=10.200.1.1 \
    distance=1 \
    comment="VLAN 201 - CCTV via MK01"

# ============================================================================
# SECCIÓN 15: FIREWALL - INPUT CHAIN
# ============================================================================

/ip firewall filter

# Regla 1: Aceptar conexiones establecidas/relacionadas
add chain=input \
    action=accept \
    connection-state=established,related \
    comment="01-INPUT: Accept established/related"

# Regla 2: Drop conexiones inválidas
add chain=input \
    action=drop \
    connection-state=invalid \
    comment="02-INPUT: Drop invalid"

# Regla 3: Aceptar ICMP (ping)
add chain=input \
    action=accept \
    protocol=icmp \
    icmp-options=8:0 \
    comment="03-INPUT: Accept ICMP Echo Request"

# Regla 4: Aceptar desde red de gestión
add chain=input \
    action=accept \
    src-address=10.200.1.0/24 \
    comment="04-INPUT: Accept from Management VLAN 999"

# Regla 5: Aceptar desde VLANs corporativas (para diagnóstico)
add chain=input \
    action=accept \
    src-address=192.168.0.0/16 \
    comment="05-INPUT: Accept from Corporate VLANs"

# Regla 6: Log tráfico dropeado
add chain=input \
    action=log \
    log-prefix="DROP-INPUT-MK02: " \
    comment="06-INPUT: Log dropped packets"

# Regla 7: Drop todo lo demás
add chain=input \
    action=drop \
    comment="07-INPUT: Drop all other"

# ============================================================================
# SECCIÓN 16: FIREWALL - FORWARD CHAIN
# ============================================================================

# Regla 1: Aceptar establecidas/relacionadas
add chain=forward \
    action=accept \
    connection-state=established,related \
    comment="01-FORWARD: Accept established/related"

# Regla 2: Drop inválidas
add chain=forward \
    action=drop \
    connection-state=invalid \
    comment="02-FORWARD: Drop invalid"

# Regla 3: Aceptar todo el forward (bridge L2 transparente)
add chain=forward \
    action=accept \
    comment="03-FORWARD: Accept all (L2 transparent bridge)"

# ============================================================================
# SECCIÓN 17: FIREWALL MANGLE - MSS CLAMPING
# ============================================================================

/ip firewall mangle
add chain=forward \
    action=change-mss \
    new-mss=clamp-to-pmtu \
    protocol=tcp \
    tcp-flags=syn \
    passthrough=yes \
    comment="MSS Clamp for Q-in-Q MTU (1590)"

add chain=postrouting \
    action=change-mss \
    new-mss=clamp-to-pmtu \
    protocol=tcp \
    tcp-flags=syn \
    passthrough=yes \
    comment="MSS Clamp postrouting"

# ============================================================================
# SECCIÓN 18: SERVICIOS - SEGURIDAD
# ============================================================================

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no port=80
set ssh disabled=no port=22
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox disabled=no port=8291

# ============================================================================
# SECCIÓN 19: MAC SERVER - SEGURIDAD
# ============================================================================

/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

/tool mac-server ping
set enabled=yes

# ============================================================================
# SECCIÓN 20: SNMP
# ============================================================================

/snmp
set enabled=yes \
    contact=protocolosinlambrica@gmail.com \
    location="Magdalena Ciudad - Hub Q-in-Q Desencapsulador" \
    trap-version=2

/snmp community
set [ find default=yes ] name=agrotech-snmp addresses=10.200.1.0/24

# ============================================================================
# SECCIÓN 21: CONFIGURACIÓN DE SISTEMA
# ============================================================================

/system clock
set time-zone-name=America/Argentina/Buenos_Aires

/system ntp client
set enabled=yes \
    primary-ntp=10.200.1.1 \
    secondary-ntp=200.23.1.7

# ============================================================================
# SECCIÓN 22: LOGGING
# ============================================================================

/system logging
add topics=error,critical,warning prefix=MK02
add topics=interface prefix=MK02-IF
add topics=bridge prefix=MK02-BR

# ============================================================================
# SECCIÓN 23: USUARIOS (Cambiar contraseñas en producción)
# ============================================================================

/user
set [ find name=admin ] password=Admin.Agrotech.2025!

# Usuario adicional para monitoreo
/user
add name=monitor password=Monitor.2025! group=read comment="Usuario solo lectura"

# ============================================================================
# SECCIÓN 24: BACKUP AUTOMÁTICO
# ============================================================================

/system scheduler
add name=auto-backup \
    interval=1d \
    start-time=03:15:00 \
    on-event="/system backup save name=(\"MK02-auto-\" . [:pick [/system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4 6])" \
    comment="Backup diario automático a las 03:15"

add name=export-backup \
    interval=1d \
    start-time=03:20:00 \
    on-event="/export file=(\"MK02-export-\" . [:pick [/system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4 6])" \
    comment="Export diario automático a las 03:20"

# ============================================================================
# SECCIÓN 25: SCRIPTS DE DIAGNÓSTICO
# ============================================================================

/system script

# Script 1: Verificar estado del transporte Q-in-Q
add name=check-qinq-transport \
    owner=admin \
    comment="Verificar estado de transporte Q-in-Q" \
    source={
:log info "=========================================="
:log info "=== MK02 Q-in-Q TRANSPORT STATUS CHECK ==="
:log info "=========================================="

:log info ""
:log info ">>> 1. Estado de interfaces fisicas:"
:local eth1 [/interface ethernet get ether1-to-sxt]
:local eth2 [/interface ethernet get ether2-isp]
:log info ("ether1-to-sxt running: " . [/interface get ether1-to-sxt running])
:log info ("ether2-isp running: " . [/interface get ether2-isp running])

:log info ""
:log info ">>> 2. Estado S-VLAN 4000:"
:log info ("s-vlan-4000-transport running: " . [/interface get s-vlan-4000-transport running])

:log info ""
:log info ">>> 3. Estadisticas de interfaces:"
/interface print stats where name~"ether1|ether2|s-vlan-4000|BR-TRANSPORT"

:log info ""
:log info ">>> 4. Bridge ports:"
/interface bridge port print where bridge=BR-TRANSPORT

:log info ""
:log info ">>> 5. MAC addresses en bridge:"
/interface bridge host print where bridge=BR-TRANSPORT

:log info ""
:log info "=== FIN CHECK ==="
}

# Script 2: Test de conectividad completo
add name=ping-topology-test \
    owner=admin \
    comment="Test de conectividad a toda la topología" \
    source={
:log info "=========================================="
:log info "=== MK02 TOPOLOGY CONNECTIVITY TEST ==="
:log info "=========================================="

:local targets {
    "10.200.1.1"="MK01-Gateway";
    "10.200.1.50"="SXT-MG-PTP-AP";
    "10.200.1.51"="SXT-CA-PTP-Station";
    "10.200.1.20"="MK03-Campo-GW";
    "10.200.1.21"="MK04-Centro-Datos";
    "10.200.1.22"="MK05-Galpon";
    "10.200.1.25"="MK06-AP-Extra"
}

:foreach ip,name in=$targets do={
    :local result [/ping $ip count=3]
    :if ($result > 0) do={
        :log info ("OK   - $name ($ip) - $result/3 respuestas")
    } else={
        :log error ("FAIL - $name ($ip) - Sin respuesta")
    }
}

:log info ""
:log info "=== FIN TEST ==="
}

# Script 3: Verificar bridge y VLANs
add name=check-bridges \
    owner=admin \
    comment="Verificar estado de todos los bridges" \
    source={
:log info "=========================================="
:log info "=== MK02 BRIDGE STATUS CHECK ==="
:log info "=========================================="

:log info ""
:log info ">>> 1. Lista de Bridges:"
/interface bridge print

:log info ""
:log info ">>> 2. Bridge Ports:"
/interface bridge port print

:log info ""
:log info ">>> 3. Interfaces VLAN:"
/interface vlan print

:log info ""
:log info ">>> 4. MACs aprendidas en BR-TRANSPORT:"
/interface bridge host print where bridge=BR-TRANSPORT

:log info ""
:log info "=== FIN CHECK ==="
}

# Script 4: Diagnóstico rápido
add name=quick-diag \
    owner=admin \
    comment="Diagnóstico rápido del equipo" \
    source={
:log info "=== QUICK DIAG MK02 ==="
:log info ("Uptime: " . [/system resource get uptime])
:log info ("CPU: " . [/system resource get cpu-load] . "%")
:log info ("Memory: " . ([/system resource get free-memory] / 1048576) . "MB free")

:local pingMK01 [/ping 10.200.1.1 count=1]
:local pingSXT [/ping 10.200.1.50 count=1]
:local pingMK03 [/ping 10.200.1.20 count=1]

:log info ("MK01: " . [:pick ("FAIL""OK  ") ($pingMK01 * 4) (($pingMK01 * 4) + 4)])
:log info ("SXT-MG: " . [:pick ("FAIL""OK  ") ($pingSXT * 4) (($pingSXT * 4) + 4)])
:log info ("MK03: " . [:pick ("FAIL""OK  ") ($pingMK03 * 4) (($pingMK03 * 4) + 4)])
:log info "=== END ==="
}

# Script 5: Monitoreo de tráfico en tiempo real
add name=traffic-monitor \
    owner=admin \
    comment="Muestra tráfico en interfaces principales" \
    source={
:log info "=== TRAFFIC MONITOR ==="
:log info ""

:local interfaces {"ether1-to-sxt";"ether2-isp";"s-vlan-4000-transport";"BR-TRANSPORT"}

:foreach iface in=$interfaces do={
    :local stats [/interface get $iface]
    :local rx [/interface get $iface rx-byte]
    :local tx [/interface get $iface tx-byte]
    :log info ("$iface: RX=" . ($rx / 1048576) . "MB TX=" . ($tx / 1048576) . "MB")
}

:log info ""
:log info "=== END ==="
}

# ============================================================================
# SECCIÓN 26: SCHEDULER PARA MONITOREO
# ============================================================================

/system scheduler
add name=hourly-connectivity-check \
    interval=1h \
    start-time=startup \
    on-event="/system script run ping-topology-test" \
    comment="Test de conectividad cada hora"

add name=daily-full-check \
    interval=1d \
    start-time=06:00:00 \
    on-event="/system script run check-bridges; /system script run check-qinq-transport" \
    comment="Verificación completa diaria a las 6 AM"

# ============================================================================
# SECCIÓN 27: GRAPHING (Opcional - para monitoreo gráfico)
# ============================================================================

/tool graphing interface
add interface=ether1-to-sxt
add interface=ether2-isp
add interface=s-vlan-4000-transport
add interface=BR-TRANSPORT

/tool graphing resource
add

# ============================================================================
# SECCIÓN 28: BANDWIDTH SERVER (Para tests de velocidad)
# ============================================================================

/tool bandwidth-server
set enabled=yes \
    authenticate=yes \
    max-sessions=5

# ============================================================================
# FIN DE CONFIGURACIÓN MK02
# ============================================================================
#
# INSTRUCCIONES DE APLICACIÓN:
# 
# OPCIÓN 1 - Reset completo (recomendado para instalación limpia):
#   1. Conectar por consola serial o cable directo a ether3
#   2. /system reset-configuration no-defaults=yes skip-backup=yes
#   3. Esperar reinicio
#   4. Importar: /import file=MK02-agrotech-mg-ap-v2.rsc
#
# OPCIÓN 2 - Migración desde configuración existente:
#   1. Hacer backup: /system backup save name=MK02-pre-migration
#   2. Exportar: /export file=MK02-pre-migration
#   3. Revisar y aplicar secciones manualmente
#   4. Probar conectividad después de cada cambio
#
# VERIFICACIÓN POST-INSTALACIÓN:
#   1. /system script run quick-diag
#   2. /system script run ping-topology-test
#   3. /system script run check-qinq-transport
#
# ============================================================================
