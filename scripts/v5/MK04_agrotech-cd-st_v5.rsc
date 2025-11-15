# ============================================================================
# AGROTECH NETWORK - LABORATORIO DE RADIOENLACES
# ============================================================================
# Dispositivo: MK04 - agrotech-cd-st (RB951ui-2HnD)
# Versión: 5.0  - Optimizado RouterOS 6.49
# Fecha: 15/Nov/2025
# Autores: Rodriguez Emanuel (19288) / Del Vecchio Guillermo (27224)
# ============================================================================
# ROL: Station PTMP - Centro de Datos/Drones
#      - Station del PTMP (conecta a MK03)
#      - Bridge L2 transparente de VLANs
#      - Acceso local VLAN 10 (Servers) y 90/96 (WiFi)
# ============================================================================
# CONFIGURACIÓN DE GESTIÓN: 
#      - IP: 10.200.1.21/24 en VLAN 999
#      - Acceso: ether3 (Untagged VLAN 999)
#      - PTMP: wlan1 (Station hacia MK03)
#      - Local: ether4 (VLAN 10), ether5 (VLAN 201)
# ============================================================================

# ----------------------------------------------------------------------------
# FASE 0: CONFIGURACIÓN INICIAL
# ----------------------------------------------------------------------------

/system identity set name="MK04-agrotech-cd-st"
/system clock set time-zone-name=America/Argentina/Buenos_Aires

/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# ----------------------------------------------------------------------------
# FASE 1: LIMPIEZA
# ----------------------------------------------------------------------------

:log info "MK04: Iniciando limpieza..."

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

:log info "MK04: Limpieza completada."

# ----------------------------------------------------------------------------
# FASE 2: CONFIGURACIÓN DE MTU
# ----------------------------------------------------------------------------

:log info "MK04: Configurando MTU..."

/interface ethernet
set [ find default-name=ether1 ] name=ether1-spare l2mtu=1600 mtu=1500
set [ find default-name=ether2 ] name=ether2-spare l2mtu=1600 mtu=1500
set [ find default-name=ether3 ] name=ether3-mgmt l2mtu=1600 mtu=1500 \
    comment="Management"
set [ find default-name=ether4 ] name=ether4-servers l2mtu=1600 mtu=1500 \
    comment="Servers - VLAN 10"
set [ find default-name=ether5 ] name=ether5-cctv l2mtu=1600 mtu=1500 \
    comment="CCTV - VLAN 201"

:log info "MK04: MTU configurado."

# ----------------------------------------------------------------------------
# FASE 3: BRIDGE Y WIRELESS
# ----------------------------------------------------------------------------

:log info "MK04: Creando bridge y perfil wireless..."

/interface bridge
add name=BR-CAMPO \
    vlan-filtering=yes \
    protocol-mode=rstp \
    frame-types=admit-all \
    comment="Bridge Station PTMP"

# Perfil PTMP (mismo que MK03)
/interface wireless security-profiles
add name=ptmp-campo \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="PtMP.Campo.AgroTech.2025!Secure" \
    comment="PTMP Campo security"

# Configuración PTMP Station
/interface wireless
set [ find default-name=wlan1 ] \
    disabled=no \
    mode=station-bridge \
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
    comment="PTMP Station to MK03"

# NV2
/interface wireless set wlan1 wireless-protocol=nv2

/interface wireless nv2 set wlan1 \
    qos=frame-priority \
    tdma-period-size=2

:log info "MK04: Wireless configurado."

# ----------------------------------------------------------------------------
# FASE 4: PUERTOS DEL BRIDGE
# ----------------------------------------------------------------------------

:log info "MK04: Configurando puertos..."

/interface bridge port
# wlan1: PTMP Link
add bridge=BR-CAMPO interface=wlan1 \
    frame-types=admit-all \
    comment="PTMP Link to MK03"

# ether3: Management (VLAN 999 untagged)
add bridge=BR-CAMPO interface=ether3-mgmt pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Management"

# ether4: Servers (VLAN 10 untagged)
add bridge=BR-CAMPO interface=ether4-servers pvid=10 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Servers - VLAN 10"

# ether5: CCTV (VLAN 201 untagged)
add bridge=BR-CAMPO interface=ether5-cctv pvid=201 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="CCTV - VLAN 201"

# Bridge itself
add bridge=BR-CAMPO interface=BR-CAMPO

:log info "MK04: Puertos configurados."

# VLAN Filtering
/interface bridge vlan
# VLAN 10 - Servers
add bridge=BR-CAMPO vlan-ids=10 \
    tagged=BR-CAMPO,wlan1 \
    untagged=ether4-servers

# VLAN 20 - Desktop
add bridge=BR-CAMPO vlan-ids=20 \
    tagged=BR-CAMPO,wlan1

# VLAN 90 - Private WiFi
add bridge=BR-CAMPO vlan-ids=90 \
    tagged=BR-CAMPO,wlan1

# VLAN 96 - Guest WiFi
add bridge=BR-CAMPO vlan-ids=96 \
    tagged=BR-CAMPO,wlan1

# VLAN 201 - CCTV
add bridge=BR-CAMPO vlan-ids=201 \
    tagged=BR-CAMPO,wlan1 \
    untagged=ether5-cctv

# VLAN 999 - Management
add bridge=BR-CAMPO vlan-ids=999 \
    tagged=BR-CAMPO,wlan1 \
    untagged=ether3-mgmt

:log info "MK04: VLAN filtering configurado."

# ----------------------------------------------------------------------------
# FASE 5: IP Y ENRUTAMIENTO
# ----------------------------------------------------------------------------

:log info "MK04: Configurando IP..."

/interface vlan
add name=vlan999-mgmt interface=BR-CAMPO vlan-id=999

/ip address
add address=10.200.1.21/24 interface=vlan999-mgmt \
    comment="Management IP"

/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 distance=1
add dst-address=192.168.0.0/16 gateway=10.200.1.1 distance=1

/ip dns
set allow-remote-requests=no servers=10.200.1.1

:log info "MK04: IP configurado."

# ----------------------------------------------------------------------------
# FASE 6: FIREWALL
# ----------------------------------------------------------------------------

:log info "MK04: Configurando firewall..."

/ip firewall filter
# INPUT
add chain=input connection-state=established,related action=accept
add chain=input protocol=icmp icmp-options=8:0 action=accept
add chain=input src-address=10.200.1.0/24 action=accept
add chain=input src-address=192.168.0.0/16 action=accept
add chain=input action=log log-prefix="DROP-MK04: "
add chain=input action=drop

# FORWARD
add chain=forward connection-state=established,related action=accept
add chain=forward connection-state=invalid action=drop
add chain=forward src-address=192.168.96.0/24 dst-address=192.168.0.0/16 \
    action=drop comment="Guest isolation"
add chain=forward action=accept

:log info "MK04: Firewall configurado."

/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu passthrough=yes

# ----------------------------------------------------------------------------
# FASE 7: MONITOREO Y SERVICIOS
# ----------------------------------------------------------------------------

:log info "MK04: Configurando monitoreo..."

/system ntp client
set enabled=yes primary-ntp=10.200.1.1 secondary-ntp=200.23.1.7

/snmp
set enabled=yes \
    contact="protocolosinlambrica@gmail.com" \
    location="Campo - Centro de Datos/Drones"

/system logging
add topics=wireless,error,critical action=memory prefix="MK04"

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

/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=MGMT

:log info "MK04: Monitoreo y servicios configurados."

# ----------------------------------------------------------------------------
# FASE 8: SCRIPTS Y BACKUP
# ----------------------------------------------------------------------------

/system script
add name=check-connection \
    source={
        :log info "=== Connection Status ==="
        /interface wireless monitor wlan1 once
        :log info "=== Ping Test ==="
        /ping 10.200.1.20 count=5
        :log info "=== End Check ==="
    }

/system scheduler
add name=auto-backup interval=1d start-time=03:45:00 \
    on-event="/system backup save name=(\"MK04-auto-\" . \
        [:pick [/system clock get date] 7 11] . \
        [:pick [/system clock get date] 0 3] . \
        [:pick [/system clock get date] 4 6])"

:log info "MK04: Scripts y backup configurados."

# ----------------------------------------------------------------------------
# CONFIGURACIÓN COMPLETA
# ----------------------------------------------------------------------------

:log warning "============================================"
:log warning "MK04 - CONFIGURACION COMPLETADA"
:log warning "============================================"
:log warning "Station PTMP - Centro de Datos/Drones"
:log warning "Management IP: 10.200.1.21/24"
:log warning "Connects to: MK03 (2462 MHz)"
:log warning "============================================"
:log warning "TOPOLOGIA:"
:log warning "  ether3: Management"
:log warning "  ether4: Servers (VLAN 10 untagged)"
:log warning "  ether5: CCTV (VLAN 201 untagged)"
:log warning "  wlan1: PTMP to MK03"
:log warning "============================================"
:log warning "VERIFICAR:"
:log warning "  /system script run check-connection"
:log warning "============================================"

# FIN DEL SCRIPT
