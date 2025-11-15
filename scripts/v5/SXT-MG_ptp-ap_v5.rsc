# ============================================================================
# AGROTECH NETWORK - LABORATORIO DE RADIOENLACES
# ============================================================================
# Dispositivo: SXT-MG - sxt-mg (SXTG-2HnD)
# Versión: 5.0 - Optimizado RouterOS 6.49
# Fecha: 15/Nov/2025
# Autores: Rodriguez Emanuel (19288) / Del Vecchio Guillermo (27224)
# ============================================================================
# ROL: Access Point del enlace PtP Magdalena-Campo (8 km)
#      - AP del radioenlace punto a punto
#      - WDS Static para transporte L2 transparente
#      - Bridge transparente de VLANs corporativas (10,20,90,96,201,999)
#      - Protocolo NV2 para máximo throughput
# ============================================================================
# CONFIGURACIÓN DE GESTIÓN: 
#      - IP: 10.200.1.50/24 en VLAN 999
#      - Acceso: ether1 (Tagged VLAN 999)
#      - Upstream: MK02 via WDS en wlan1
#      - Downstream: SXT-CA via RF en wlan1
# ============================================================================

# ----------------------------------------------------------------------------
# FASE 0: CONFIGURACIÓN INICIAL
# ----------------------------------------------------------------------------

/system identity set name="SXT-MG-PTP-AP"
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# Usuarios
/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------------------------------------------
# FASE 1: LIMPIEZA
# ----------------------------------------------------------------------------

:log info "SXT-MG: Iniciando limpieza..."

/ip address remove [find where !dynamic]
/ip route remove [find where !dynamic]
/ip firewall filter remove [find]
/ip firewall mangle remove [find]
/interface bridge port remove [find]
/interface bridge vlan remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find where name!="default"]
/interface wireless reset-configuration wlan1

:log info "SXT-MG: Limpieza completada."

# ----------------------------------------------------------------------------
# FASE 2: CONFIGURACIÓN DE MTU
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando MTU..."

# SXTG-2HnD solo tiene ether1
/interface ethernet
set [ find default-name=ether1 ] \
    name=ether1-trunk \
    l2mtu=1600 \
    mtu=1590 \
    comment="Trunk to MK02"

:log info "SXT-MG: MTU configurado."

# ----------------------------------------------------------------------------
# FASE 3: BRIDGE PARA TRANSPORTE L2
# ----------------------------------------------------------------------------

:log info "SXT-MG: Creando bridge..."

/interface bridge
add name=BR-PTP \
    vlan-filtering=yes \
    protocol-mode=none \
    frame-types=admit-all \
    comment="Bridge L2 transparente para PtP"

:log info "SXT-MG: Bridge creado."

# ----------------------------------------------------------------------------
# FASE 4: SEGURIDAD INALÁMBRICA Y CONFIGURACIÓN RF
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando wireless..."

# Perfil de seguridad para PtP
/interface wireless security-profiles
add name=ptp-secure \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="PtP.Magdalena.Campo.2025!Secure" \
    comment="PtP Link Security - 8km"

:log info "SXT-MG: Perfil wireless creado."

# Configuración del wireless como AP
/interface wireless
set [ find default-name=wlan1 ] \
    disabled=no \
    mode=ap-bridge \
    band=2ghz-b/g/n \
    channel-width=20mhz \
    frequency=2437 \
    ssid="Agrotech-PTP-MG-CA" \
    security-profile=ptp-secure \
    wds-mode=static \
    wds-default-bridge=BR-PTP \
    wps-mode=disabled \
    country=argentina \
    distance=8000 \
    adaptive-noise-immunity=ap-and-client-mode \
    hw-retries=7 \
    frame-lifetime=0 \
    comment="PtP AP to SXT-CA (8km)"

# Configurar protocolo NV2 para mejor performance
/interface wireless set wlan1 wireless-protocol=nv2

# Parámetros NV2 optimizados para PtP
/interface wireless nv2 set wlan1 \
    qos=frame-priority \
    tdma-period-size=2

:log info "SXT-MG: Wireless configurado como AP NV2."

# ----------------------------------------------------------------------------
# FASE 5: PUERTOS DEL BRIDGE Y VLAN FILTERING
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando puertos del bridge..."

/interface bridge port
# ether1: Trunk hacia MK02 (todas las VLANs tagged)
add bridge=BR-PTP interface=ether1-trunk \
    frame-types=admit-all \
    comment="Trunk to MK02 - All VLANs"

# wlan1: RF link (todas las VLANs tagged via WDS)
add bridge=BR-PTP interface=wlan1 \
    frame-types=admit-all \
    comment="PtP RF Link - All VLANs"

# Bridge en sí mismo
add bridge=BR-PTP interface=BR-PTP

:log info "SXT-MG: Puertos configurados."

# VLAN Filtering - Permitir paso de todas las C-VLANs
/interface bridge vlan
# VLAN 10 - Servers
add bridge=BR-PTP vlan-ids=10 \
    tagged=BR-PTP,ether1-trunk,wlan1

# VLAN 20 - Desktop
add bridge=BR-PTP vlan-ids=20 \
    tagged=BR-PTP,ether1-trunk,wlan1

# VLAN 90 - Private WiFi
add bridge=BR-PTP vlan-ids=90 \
    tagged=BR-PTP,ether1-trunk,wlan1

# VLAN 96 - Guest WiFi
add bridge=BR-PTP vlan-ids=96 \
    tagged=BR-PTP,ether1-trunk,wlan1

# VLAN 201 - CCTV
add bridge=BR-PTP vlan-ids=201 \
    tagged=BR-PTP,ether1-trunk,wlan1

# VLAN 999 - Management
add bridge=BR-PTP vlan-ids=999 \
    tagged=BR-PTP,ether1-trunk,wlan1

:log info "SXT-MG: VLAN filtering configurado."

# ----------------------------------------------------------------------------
# FASE 6: INTERFAZ DE GESTIÓN Y DIRECCIONAMIENTO
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando gestión..."

# Crear VLAN 999 para gestión
/interface vlan
add name=vlan999-mgmt interface=BR-PTP vlan-id=999 \
    comment="Management VLAN"

# IP de gestión
/ip address
add address=10.200.1.50/24 interface=vlan999-mgmt \
    comment="Management IP"

# Rutas
/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 distance=1 \
    comment="Default route to MK01"

add dst-address=192.168.0.0/16 gateway=10.200.1.1 distance=1 \
    comment="Corporate networks via MK01"

:log info "SXT-MG: IP y enrutamiento configurado."

# DNS
/ip dns
set allow-remote-requests=no \
    servers=10.200.1.1

# ----------------------------------------------------------------------------
# FASE 7: FIREWALL
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando firewall..."

/ip firewall filter
# INPUT
add chain=input connection-state=established,related \
    action=accept \
    comment="Accept established/related"

add chain=input protocol=icmp icmp-options=8:0 \
    action=accept \
    comment="Accept ICMP"

add chain=input src-address=10.200.1.0/24 \
    action=accept \
    comment="Accept from Management VLAN"

add chain=input \
    action=log \
    log-prefix="DROP-SXT-MG: "

add chain=input \
    action=drop \
    comment="Drop all other input"

# FORWARD - L2 bridge transparente
add chain=forward connection-state=established,related \
    action=accept

add chain=forward connection-state=invalid \
    action=drop

add chain=forward \
    action=accept \
    comment="Accept all forward (L2 bridge)"

:log info "SXT-MG: Firewall configurado."

# MSS Clamping
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu \
    passthrough=yes \
    comment="MSS Clamp for PtP link"

# ----------------------------------------------------------------------------
# FASE 8: MONITOREO
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando monitoreo..."

/system ntp client
set enabled=yes \
    primary-ntp=10.200.1.1 \
    secondary-ntp=200.23.1.7

/snmp
set enabled=yes \
    contact="laboratorio@agrotech.local" \
    location="Magdalena - PtP AP (8km to Campo)" \
    trap-community=public

/system logging
add topics=wireless,error,critical \
    action=memory \
    prefix="SXT-MG"

:log info "SXT-MG: Monitoreo configurado."

# ----------------------------------------------------------------------------
# FASE 9: SERVICIOS Y SEGURIDAD
# ----------------------------------------------------------------------------

:log info "SXT-MG: Configurando servicios..."

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no
set ssh disabled=no
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox disabled=no

/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=none

# Permitir MAC Winbox solo en gestión
/interface list
add name=MGMT
/interface list member
add list=MGMT interface=vlan999-mgmt

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

:log info "SXT-MG: Servicios configurados."

# ----------------------------------------------------------------------------
# FASE 10: SCRIPTS DE DIAGNÓSTICO
# ----------------------------------------------------------------------------

:log info "SXT-MG: Creando scripts..."

/system script
add name=check-ptp-status \
    source={
        :log info "=== PtP Link Status ==="
        /interface wireless print
        :log info "Registration Table:"
        /interface wireless registration-table print detail
        :log info "Link Stats:"
        /interface wireless monitor wlan1 once
        :log info "=== End Check ==="
    } \
    comment="Verificar estado del enlace PtP"

add name=check-signal \
    source={
        :log info "=== Signal Check ==="
        :local reg [/interface wireless registration-table find]
        :if ([:len $reg] > 0) do={
            :foreach i in=$reg do={
                :local mac [/interface wireless registration-table get $i mac-address]
                :local signal [/interface wireless registration-table get $i signal-strength]
                :local txrate [/interface wireless registration-table get $i tx-rate]
                :local rxrate [/interface wireless registration-table get $i rx-rate]
                :log info ("Client: " . $mac)
                :log info ("Signal: " . $signal . " dBm")
                :log info ("TX Rate: " . $txrate . " Mbps")
                :log info ("RX Rate: " . $rxrate . " Mbps")
            }
        } else={
            :log warning "No clients registered!"
        }
        :log info "=== End Check ==="
    } \
    comment="Verificar señal y velocidad"

add name=check-throughput \
    source={
        :log info "=== Throughput Test ==="
        :log info "Running bandwidth test to SXT-CA..."
        :log info "IP: 10.200.1.51"
        # Descomentar cuando SXT-CA esté operativo
        # /tool bandwidth-test 10.200.1.51 duration=10s protocol=tcp
        :log info "=== End Test ==="
    } \
    comment="Test de throughput al SXT-CA"

:log info "SXT-MG: Scripts creados."

# ----------------------------------------------------------------------------
# FASE 11: OPTIMIZACIONES DE RF
# ----------------------------------------------------------------------------

:log info "SXT-MG: Aplicando optimizaciones RF..."

# Ajustes para enlace de 8km
/interface wireless
set wlan1 \
    tx-power-mode=all-rates-fixed \
    default-forwarding=no \
    hide-ssid=yes

# Scan list mínimo (reducir interferencia)
/interface wireless set wlan1 scan-list=2437

:log info "SXT-MG: Optimizaciones RF aplicadas."

# ----------------------------------------------------------------------------
# CONFIGURACIÓN COMPLETA
# ----------------------------------------------------------------------------

:log warning "============================================"
:log warning "SXT-MG - CONFIGURACION COMPLETADA"
:log warning "============================================"
:log warning "PtP Access Point - Magdalena to Campo (8km)"
:log warning "Management IP: 10.200.1.50/24"
:log warning "Frequency: 2437 MHz (Channel 6)"
:log warning "Mode: AP-Bridge with NV2"
:log warning "WDS: Static (agregar peer SXT-CA manualmente)"
:log warning "============================================"
:log warning "PASOS SIGUIENTES:"
:log warning "1. Alinear antena hacia Campo (azimuth correcto)"
:log warning "2. Conectar al MK02 via ether1"
:log warning "3. Cuando SXT-CA se registre, verificar:"
:log warning "   /system script run check-ptp-status"
:log warning "4. Verificar señal:"
:log warning "   /system script run check-signal"
:log warning "5. Test de throughput:"
:log warning "   /system script run check-throughput"
:log warning "============================================"
:log warning "OBJETIVO: Signal > -70dBm, TX/RX > 50Mbps"
:log warning "============================================"

# FIN DEL SCRIPT
