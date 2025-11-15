# ============================================================================
# AGROTECH NETWORK - LABORATORIO DE RADIOENLACES
# ============================================================================
# Dispositivo: MK03 - agrotech-ca-gw (RB951ui-2HnD)
# Versión: 5.0 - Optimizado RouterOS 6.49.x
# Fecha: 15/Nov/2025
# Autores: Rodriguez Emanuel (19288) / Del Vecchio Guillermo (27224)
# ============================================================================
# ROL: Gateway Campo A - AP del PTMP
#      - Recepción del enlace PtP desde SXT-CA
#      - Access Point del PTMP (Master) hacia MK04, MK05, MK06
#      - Bridge L2 transparente de VLANs
#      - Acceso local a VLANs 10 y 20
# ============================================================================
# CONFIGURACIÓN DE GESTIÓN: 
#      - IP: 10.200.1.20/24 en VLAN 999
#      - Acceso: ether3 (Untagged VLAN 999)
#      - Upstream: SXT-CA via ether1 (VLAN trunk)
#      - PTMP: wlan1 (AP Master NV2)
#      - Local access: ether4 (VLAN 10), ether5 (VLAN 20)
# ============================================================================

# ----------------------------------------------------------------------------
# FASE 0: CONFIGURACIÓN INICIAL
# ----------------------------------------------------------------------------

/system identity set name="MK03-agrotech-ca-gw"
/system clock set time-zone-name=America/Argentina/Buenos_Aires

/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------------------------------------------
# FASE 1: LIMPIEZA
# ----------------------------------------------------------------------------

:log info "MK03: Iniciando limpieza..."

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

:log info "MK03: Limpieza completada."

# ----------------------------------------------------------------------------
# FASE 2: CONFIGURACIÓN DE MTU
# ----------------------------------------------------------------------------

:log info "MK03: Configurando MTU..."

/interface ethernet
set [ find default-name=ether1 ] name=ether1-ptp l2mtu=1600 mtu=1590 \
    comment="Trunk from SXT-CA"
set [ find default-name=ether2 ] name=ether2-spare l2mtu=1600 mtu=1500 \
    comment="Spare port"
set [ find default-name=ether3 ] name=ether3-mgmt l2mtu=1600 mtu=1500 \
    comment="Management"
set [ find default-name=ether4 ] name=ether4-servers l2mtu=1600 mtu=1500 \
    comment="Local VLAN 10 - Servers"
set [ find default-name=ether5 ] name=ether5-desktop l2mtu=1600 mtu=1500 \
    comment="Local VLAN 20 - Desktop"

:log info "MK03: MTU configurado."

# ----------------------------------------------------------------------------
# FASE 3: BRIDGE Y SEGURIDAD WIRELESS
# ----------------------------------------------------------------------------

:log info "MK03: Creando bridge y perfiles wireless..."

/interface bridge
add name=BR-CAMPO \
    vlan-filtering=yes \
    protocol-mode=rstp \
    frame-types=admit-all \
    comment="Bridge Campo - L2 Transport + PTMP"

# Perfil para PTMP (hacia MK04, MK05, MK06)
/interface wireless security-profiles
add name=ptmp-campo \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="PtMP.Campo.AgroTech.2025!Secure" \
    comment="PTMP Campo security"

:log info "MK03: Perfiles creados."

# Configuración PTMP AP (wlan1)
/interface wireless
set [ find default-name=wlan1 ] \
    disabled=no \
    mode=ap-bridge \
    band=2ghz-b/g/n \
    channel-width=20mhz \
    frequency=2462 \
    ssid="Agrotech-PTMP-Campo" \
    security-profile=ptmp-campo \
    wds-mode=dynamic \
    wds-default-bridge=BR-CAMPO \
    wps-mode=disabled \
    country=argentina \
    distance=indoors \
    comment="PTMP AP Master"

# NV2 protocol
/interface wireless set wlan1 wireless-protocol=nv2

# Parámetros NV2 para PTMP
/interface wireless nv2 set wlan1 \
    qos=frame-priority \
    tdma-period-size=2

:log info "MK03: PTMP AP configurado."

# ----------------------------------------------------------------------------
# FASE 4: PUERTOS DEL BRIDGE Y VLAN FILTERING
# ----------------------------------------------------------------------------

:log info "MK03: Configurando puertos del bridge..."

/interface bridge port
# ether1: Trunk desde SXT-CA (todas las VLANs)
add bridge=BR-CAMPO interface=ether1-ptp \
    frame-types=admit-all \
    comment="Trunk from SXT-CA"

# ether3: Management (VLAN 999 untagged)
add bridge=BR-CAMPO interface=ether3-mgmt pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Management - VLAN 999"

# ether4: Servers (VLAN 10 untagged)
add bridge=BR-CAMPO interface=ether4-servers pvid=10 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Servers - VLAN 10 Untagged"

# ether5: Desktop (VLAN 20 untagged)
add bridge=BR-CAMPO interface=ether5-desktop pvid=20 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Desktop - VLAN 20 Untagged"

# wlan1: PTMP AP (todas las VLANs)
add bridge=BR-CAMPO interface=wlan1 \
    frame-types=admit-all \
    comment="PTMP Link"

# Bridge itself
add bridge=BR-CAMPO interface=BR-CAMPO

:log info "MK03: Puertos configurados."

# VLAN Filtering
/interface bridge vlan
# VLAN 10 - Servers
add bridge=BR-CAMPO vlan-ids=10 \
    tagged=BR-CAMPO,ether1-ptp,wlan1 \
    untagged=ether4-servers

# VLAN 20 - Desktop
add bridge=BR-CAMPO vlan-ids=20 \
    tagged=BR-CAMPO,ether1-ptp,wlan1 \
    untagged=ether5-desktop

# VLAN 90 - Private WiFi
add bridge=BR-CAMPO vlan-ids=90 \
    tagged=BR-CAMPO,ether1-ptp,wlan1

# VLAN 96 - Guest WiFi
add bridge=BR-CAMPO vlan-ids=96 \
    tagged=BR-CAMPO,ether1-ptp,wlan1

# VLAN 201 - CCTV
add bridge=BR-CAMPO vlan-ids=201 \
    tagged=BR-CAMPO,ether1-ptp,wlan1

# VLAN 999 - Management
add bridge=BR-CAMPO vlan-ids=999 \
    tagged=BR-CAMPO,ether1-ptp,wlan1 \
    untagged=ether3-mgmt

:log info "MK03: VLAN filtering configurado."

# ----------------------------------------------------------------------------
# FASE 5: DIRECCIONAMIENTO IP
# ----------------------------------------------------------------------------

:log info "MK03: Configurando IP..."

# VLAN 999 para gestión
/interface vlan
add name=vlan999-mgmt interface=BR-CAMPO vlan-id=999 \
    comment="Management VLAN"

# IP de gestión
/ip address
add address=10.200.1.20/24 interface=vlan999-mgmt \
    comment="Management IP"

# Rutas
/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 distance=1 \
    comment="Default to MK01"

add dst-address=192.168.0.0/16 gateway=10.200.1.1 distance=1 \
    comment="Corporate VLANs via MK01"

:log info "MK03: IP configurado."

# DNS
/ip dns
set allow-remote-requests=no \
    servers=10.200.1.1

# ----------------------------------------------------------------------------
# FASE 6: FIREWALL
# ----------------------------------------------------------------------------

:log info "MK03: Configurando firewall..."

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
    comment="Accept from Management"

add chain=input src-address=192.168.0.0/16 \
    action=accept \
    comment="Accept from Corporate VLANs"

add chain=input \
    action=log \
    log-prefix="DROP-MK03: "

add chain=input \
    action=drop

# FORWARD
add chain=forward connection-state=established,related \
    action=accept

add chain=forward connection-state=invalid \
    action=drop

# Guest isolation
add chain=forward \
    src-address=192.168.96.0/24 \
    dst-address=192.168.0.0/16 \
    action=drop \
    comment="Guest isolation"

# Allow inter-VLAN corporate
add chain=forward \
    src-address=192.168.0.0/16 \
    dst-address=192.168.0.0/16 \
    action=accept

# Allow all forward (L2 bridge)
add chain=forward \
    action=accept

:log info "MK03: Firewall configurado."

# MSS Clamping
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu \
    passthrough=yes

# ----------------------------------------------------------------------------
# FASE 7: MONITOREO
# ----------------------------------------------------------------------------

:log info "MK03: Configurando monitoreo..."

/system ntp client
set enabled=yes \
    primary-ntp=10.200.1.1 \
    secondary-ntp=200.23.1.7

/snmp
set enabled=yes \
    contact="laboratorio@agrotech.local" \
    location="Campo A - PTMP AP Gateway"

/system logging
add topics=wireless,error,critical \
    action=memory \
    prefix="MK03"

# Email alerts
/tool e-mail
set address=smtp.gmail.com \
    port=587 \
    start-tls=yes \
    from="agrotech-alerts@gmail.com" \
    user="agrotech-alerts@gmail.com" \
    password="password_here"

/system logging action
add name=email-alert target=email \
    email-to="admin@agrotech.local"

/system logging
add topics=error,critical \
    action=email-alert \
    prefix="CRITICAL-MK03"

:log info "MK03: Monitoreo configurado."

# ----------------------------------------------------------------------------
# FASE 8: SERVICIOS
# ----------------------------------------------------------------------------

:log info "MK03: Configurando servicios..."

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
add list=MGMT interface=ether3-mgmt
add list=MGMT interface=vlan999-mgmt

/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

:log info "MK03: Servicios configurados."

# ----------------------------------------------------------------------------
# FASE 9: SCRIPTS DE DIAGNÓSTICO
# ----------------------------------------------------------------------------

:log info "MK03: Creando scripts..."

/system script
add name=check-ptmp-clients \
    source={
        :log info "=== PTMP Clients ==="
        /interface wireless registration-table print
        :log info "=== WDS Interfaces ==="
        /interface wireless wds print
        :log info "=== End Check ==="
    }

add name=check-vlans \
    source={
        :log info "=== VLAN Status ==="
        /interface bridge vlan print
        /interface bridge port print
        :log info "=== End Check ==="
    }

add name=ping-test-all \
    source={
        :log info "=== Connectivity Test ==="
        :local targets {"10.200.1.1";"10.200.1.10";"10.200.1.50";"10.200.1.51"}
        :foreach t in=$targets do={
            :log info ("Testing " . $t)
            /ping $t count=3
        }
        :log info "=== End Test ==="
    }

:log info "MK03: Scripts creados."

# ----------------------------------------------------------------------------
# FASE 10: BACKUP
# ----------------------------------------------------------------------------

/system scheduler
add name=auto-backup \
    interval=1d \
    start-time=03:30:00 \
    on-event="/system backup save name=(\"MK03-auto-\" . \
        [:pick [/system clock get date] 7 11] . \
        [:pick [/system clock get date] 0 3] . \
        [:pick [/system clock get date] 4 6])"

:log info "MK03: Backup configurado."

# ----------------------------------------------------------------------------
# CONFIGURACIÓN COMPLETA
# ----------------------------------------------------------------------------

:log warning "============================================"
:log warning "MK03 - CONFIGURACION COMPLETADA"
:log warning "============================================"
:log warning "Gateway Campo A - PTMP AP Master"
:log warning "Management IP: 10.200.1.20/24"
:log warning "PTMP: 2462 MHz (Channel 11)"
:log warning "WDS: Dynamic mode"
:log warning "============================================"
:log warning "TOPOLOGIA:"
:log warning "  ether1: Trunk from SXT-CA"
:log warning "  ether3: Management"
:log warning "  ether4: Servers (VLAN 10)"
:log warning "  ether5: Desktop (VLAN 20)"
:log warning "  wlan1: PTMP to MK04/MK05/MK06"
:log warning "============================================"
:log warning "VERIFICAR:"
:log warning "1. /system script run check-ptmp-clients"
:log warning "2. /system script run check-vlans"
:log warning "3. /system script run ping-test-all"
:log warning "============================================"

# FIN DEL SCRIPT
