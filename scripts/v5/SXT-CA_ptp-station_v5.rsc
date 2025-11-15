# ============================================================================
# AGROTECH NETWORK - LABORATORIO DE RADIOENLACES
# ============================================================================
# Dispositivo: SXT-CA - sxt-ca (SXTG-2HnD)
# Versión: 5.0 - Optimizado RouterOS 6.44.x
# Fecha: 15/Nov/2025
# Autores: Rodriguez Emanuel (19288) / Del Vecchio Guillermo (27224)
# ============================================================================
# ROL: Station del enlace PtP Campo-Magdalena (8 km)
#      - Station del radioenlace punto a punto
#      - WDS Static para transporte L2 transparente
#      - Bridge transparente de VLANs corporativas (10,20,90,96,201,999)
#      - Protocolo NV2 sincronizado con SXT-MG
# ============================================================================
# CONFIGURACIÓN DE GESTIÓN: 
#      - IP: 10.200.1.51/24 en VLAN 999
#      - Acceso: ether1 (Tagged VLAN 999)
#      - Upstream: SXT-MG via RF en wlan1
#      - Downstream: MK04 via ether1
# ============================================================================

# ----------------------------------------------------------------------------
# FASE 0: CONFIGURACIÓN INICIAL
# ----------------------------------------------------------------------------

/system identity set name="SXT-CA-PTP-Station"
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# Usuarios
/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------------------------------------------
# FASE 1: LIMPIEZA
# ----------------------------------------------------------------------------

:log info "SXT-CA: Iniciando limpieza..."

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

:log info "SXT-CA: Limpieza completada."

# ----------------------------------------------------------------------------
# FASE 2: CONFIGURACIÓN DE MTU
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando MTU..."

/interface ethernet
set [ find default-name=ether1 ] \
    name=ether1-trunk \
    l2mtu=1600 \
    mtu=1590 \
    comment="Trunk to MK04"

:log info "SXT-CA: MTU configurado."

# ----------------------------------------------------------------------------
# FASE 3: BRIDGE PARA TRANSPORTE L2
# ----------------------------------------------------------------------------

:log info "SXT-CA: Creando bridge..."

/interface bridge
add name=BR-PTP \
    vlan-filtering=yes \
    protocol-mode=none \
    frame-types=admit-all \
    comment="Bridge L2 transparente para PtP"

:log info "SXT-CA: Bridge creado."

# ----------------------------------------------------------------------------
# FASE 4: SEGURIDAD INALÁMBRICA Y CONFIGURACIÓN RF
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando wireless..."

# Perfil de seguridad (MISMO que SXT-MG)
/interface wireless security-profiles
add name=ptp-secure \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="PtP.Magdalena.Campo.2025!Secure" \
    comment="PtP Link Security - 8km"

:log info "SXT-CA: Perfil wireless creado."

# Configuración del wireless como STATION
/interface wireless
set [ find default-name=wlan1 ] \
    disabled=no \
    mode=station-bridge \
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
    comment="PtP Station to SXT-MG (8km)"

# NV2 protocol
/interface wireless set wlan1 wireless-protocol=nv2

# Parámetros NV2 (sincronizados con AP)
/interface wireless nv2 set wlan1 \
    qos=frame-priority \
    tdma-period-size=2

:log info "SXT-CA: Wireless configurado como Station NV2."

# ----------------------------------------------------------------------------
# FASE 5: PUERTOS DEL BRIDGE Y VLAN FILTERING
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando puertos del bridge..."

/interface bridge port
# ether1: Trunk hacia MK04 (todas las VLANs tagged)
add bridge=BR-PTP interface=ether1-trunk \
    frame-types=admit-all \
    comment="Trunk to MK04 - All VLANs"

# wlan1: RF link (todas las VLANs tagged via WDS)
add bridge=BR-PTP interface=wlan1 \
    frame-types=admit-all \
    comment="PtP RF Link - All VLANs"

# Bridge en sí mismo
add bridge=BR-PTP interface=BR-PTP

:log info "SXT-CA: Puertos configurados."

# VLAN Filtering - Idéntico a SXT-MG
/interface bridge vlan
add bridge=BR-PTP vlan-ids=10 \
    tagged=BR-PTP,ether1-trunk,wlan1

add bridge=BR-PTP vlan-ids=20 \
    tagged=BR-PTP,ether1-trunk,wlan1

add bridge=BR-PTP vlan-ids=90 \
    tagged=BR-PTP,ether1-trunk,wlan1

add bridge=BR-PTP vlan-ids=96 \
    tagged=BR-PTP,ether1-trunk,wlan1

add bridge=BR-PTP vlan-ids=201 \
    tagged=BR-PTP,ether1-trunk,wlan1

add bridge=BR-PTP vlan-ids=999 \
    tagged=BR-PTP,ether1-trunk,wlan1

:log info "SXT-CA: VLAN filtering configurado."

# ----------------------------------------------------------------------------
# FASE 6: INTERFAZ DE GESTIÓN Y DIRECCIONAMIENTO
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando gestión..."

# VLAN 999 para gestión
/interface vlan
add name=vlan999-mgmt interface=BR-PTP vlan-id=999 \
    comment="Management VLAN"

# IP de gestión
/ip address
add address=10.200.1.51/24 interface=vlan999-mgmt \
    comment="Management IP"

# Rutas
/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 distance=1 \
    comment="Default route to MK01"

add dst-address=192.168.0.0/16 gateway=10.200.1.1 distance=1 \
    comment="Corporate networks via MK01"

:log info "SXT-CA: IP y enrutamiento configurado."

# DNS
/ip dns
set allow-remote-requests=no \
    servers=10.200.1.1

# ----------------------------------------------------------------------------
# FASE 7: FIREWALL
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando firewall..."

/ip firewall filter
add chain=input connection-state=established,related \
    action=accept

add chain=input protocol=icmp icmp-options=8:0 \
    action=accept

add chain=input src-address=10.200.1.0/24 \
    action=accept

add chain=input \
    action=log \
    log-prefix="DROP-SXT-CA: "

add chain=input \
    action=drop

# FORWARD
add chain=forward connection-state=established,related \
    action=accept

add chain=forward connection-state=invalid \
    action=drop

add chain=forward \
    action=accept \
    comment="Accept all forward (L2 bridge)"

:log info "SXT-CA: Firewall configurado."

# MSS Clamping
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu \
    passthrough=yes

# ----------------------------------------------------------------------------
# FASE 8: MONITOREO
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando monitoreo..."

/system ntp client
set enabled=yes \
    primary-ntp=10.200.1.1 \
    secondary-ntp=200.23.1.7

/snmp
set enabled=yes \
    contact="laboratorio@agrotech.local" \
    location="Campo - PtP Station (8km from Magdalena)"

/system logging
add topics=wireless,error,critical \
    action=memory \
    prefix="SXT-CA"

:log info "SXT-CA: Monitoreo configurado."

# ----------------------------------------------------------------------------
# FASE 9: SERVICIOS
# ----------------------------------------------------------------------------

:log info "SXT-CA: Configurando servicios..."

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no
set ssh disabled=no
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox disabled=no

/interface list
add name=MGMT
/interface list member
add list=MGMT interface=vlan999-mgmt

/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

:log info "SXT-CA: Servicios configurados."

# ----------------------------------------------------------------------------
# FASE 10: SCRIPTS DE DIAGNÓSTICO
# ----------------------------------------------------------------------------

:log info "SXT-CA: Creando scripts..."

/system script
add name=check-connection-status \
    source={
        :log info "=== Connection Status to SXT-MG ==="
        /interface wireless print
        :log info "Monitor:"
        /interface wireless monitor wlan1 once
        :log info "=== End Check ==="
    }

add name=check-signal \
    source={
        :log info "=== Signal Quality ==="
        :local sig [/interface wireless monitor wlan1 once as-value]
        :log info ("SSID: " . ($sig->"ssid"))
        :log info ("Frequency: " . ($sig->"frequency"))
        :log info ("Signal Strength: " . ($sig->"signal-strength") . " dBm")
        :log info ("TX CCQ: " . ($sig->"tx-ccq") . "%")
        :log info ("Noise Floor: " . ($sig->"noise-floor") . " dBm")
        :log info ("TX Rate: " . ($sig->"tx-rate"))
        :log info ("RX Rate: " . ($sig->"rx-rate"))
        :log info "=== End Check ==="
    }

add name=bw-test-to-mg \
    source={
        :log info "=== Bandwidth Test to SXT-MG ==="
        :log info "Testing to 10.200.1.50..."
        /tool bandwidth-test 10.200.1.50 duration=10s protocol=tcp
        :log info "=== End Test ==="
    }

:log info "SXT-CA: Scripts creados."

# ----------------------------------------------------------------------------
# FASE 11: OPTIMIZACIONES RF STATION
# ----------------------------------------------------------------------------

:log info "SXT-CA: Aplicando optimizaciones RF..."

/interface wireless
set wlan1 \
    tx-power-mode=all-rates-fixed \
    default-forwarding=no

# Scan list mínimo
/interface wireless set wlan1 scan-list=2437

:log info "SXT-CA: Optimizaciones RF aplicadas."

# ----------------------------------------------------------------------------
# CONFIGURACIÓN COMPLETA
# ----------------------------------------------------------------------------

:log warning "============================================"
:log warning "SXT-CA - CONFIGURACION COMPLETADA"
:log warning "============================================"
:log warning "PtP Station - Campo to Magdalena (8km)"
:log warning "Management IP: 10.200.1.51/24"
:log warning "Frequency: 2437 MHz (Channel 6)"
:log warning "Mode: Station-Bridge with NV2"
:log warning "Connects to: Agrotech-PTP-MG-CA"
:log warning "============================================"
:log warning "PASOS SIGUIENTES:"
:log warning "1. Alinear antena hacia Magdalena"
:log warning "2. Conectar al MK04 via ether1"
:log warning "3. Verificar conexión:"
:log warning "   /system script run check-connection-status"
:log warning "4. Verificar señal:"
:log warning "   /system script run check-signal"
:log warning "5. Test de ancho de banda:"
:log warning "   /system script run bw-test-to-mg"
:log warning "============================================"
:log warning "OBJETIVO: Signal > -70dBm, CCQ > 80%"
:log warning "============================================"

# FIN DEL SCRIPT
