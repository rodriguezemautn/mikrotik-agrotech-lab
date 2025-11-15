# ============================================================================
# AGROTECH NETWORK - LABORATORIO DE RADIOENLACES
# ============================================================================
# Dispositivo: MK01 - agrotech-lp-gw (RB951ui-2HnD)
# Versión: 5.0- Optimizado RouterOS 6.49.x
# Fecha: 15/Nov/2025
# Autores: Rodriguez Emanuel (19288) / Del Vecchio Guillermo (27224)
# ============================================================================
# ROL: Gateway Central La Plata
#      - Encapsulación Q-in-Q (S-VLAN 4000 con C-VLANs 10,20,90,96,201)
#      - Servidor DHCP/DNS centralizado
#      - NAT y Firewall corporativo
#      - Gateway L3 para todas las VLANs
# ============================================================================
# CONFIGURACIÓN DE GESTIÓN: 
#      - IP: 10.200.1.1/24 en VLAN 999
#      - Acceso: ether3 (Untagged VLAN 999)
#      - Winbox: Puerto 8291
#      - SSH: Puerto 22
# ============================================================================

# ----------------------------------------------------------------------------
# FASE 0: CONFIGURACIÓN INICIAL DEL SISTEMA
# ----------------------------------------------------------------------------

/system identity set name="MK01-agrotech-lp-gw"
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# Usuarios y contraseñas
/user set [find name=admin] password="Lab2025!" comment="Usuario administrador principal"
/user add name=laboratorio group=full password="Lab2025!" \
    comment="Usuario para configuracion de laboratorio"

# ----------------------------------------------------------------------------
# FASE 1: LIMPIEZA COMPLETA (RESET DE CONFIGURACION)
# ----------------------------------------------------------------------------

:log info "MK01: Iniciando limpieza de configuracion previa..."

/ip dhcp-server remove [find]
/ip dhcp-server network remove [find]
/ip pool remove [find]
/ip address remove [find where !dynamic]
/ip route remove [find where !dynamic]
/ip firewall filter remove [find]
/ip firewall nat remove [find]
/ip firewall mangle remove [find]
/interface bridge port remove [find]
/interface bridge vlan remove [find]
/interface bridge remove [find]
/interface vlan remove [find]
/interface wireless security-profiles remove [find where name!="default"]
/interface wireless reset-configuration wlan1

:log info "MK01: Limpieza completada."

# ----------------------------------------------------------------------------
# FASE 2: CONFIGURACIÓN DE HARDWARE Y MTU
# ----------------------------------------------------------------------------

:log info "MK01: Configurando MTU y L2MTU para soporte Q-in-Q..."

# Configurar L2MTU en todas las interfaces físicas para soportar doble tagging
# L2MTU 1600 = 1500 (payload) + 18 (headers) + 8 (doble VLAN tag) + 4 (FCS)
/interface ethernet
set [ find default-name=ether1 ] name=ether1-wan l2mtu=1600 mtu=1500 comment="WAN - Internet"
set [ find default-name=ether2 ] name=ether2-isp l2mtu=1600 mtu=1590 comment="ISP Trunk - Q-in-Q Transport"
set [ find default-name=ether3 ] name=ether3-mgmt l2mtu=1600 mtu=1500 comment="Management Access"
set [ find default-name=ether4 ] name=ether4-local l2mtu=1600 mtu=1500 comment="Local Desktop/Servers"
set [ find default-name=ether5 ] name=ether5-local l2mtu=1600 mtu=1500 comment="Local CCTV/IoT"

:log info "MK01: MTU configurado correctamente."

# ----------------------------------------------------------------------------
# FASE 3: BRIDGE PRINCIPAL Y SEGURIDAD INALÁMBRICA
# ----------------------------------------------------------------------------

:log info "MK01: Creando bridge principal y perfiles wireless..."

# Bridge principal para VLANs locales (NO para Q-in-Q)
/interface bridge
add name=BR-LOCAL vlan-filtering=yes protocol-mode=rstp \
    frame-types=admit-all comment="Bridge local para VLANs corporativas"

# Perfiles de seguridad inalámbrica (WPA2-PSK con AES-CCMP)
/interface wireless security-profiles
add name=agrotech-private \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="AgroTech.Secure.Private.2025!" \
    comment="VLAN 90 - Red corporativa privada"

add name=agrotech-guest \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="AgroTech.Guest.2025!" \
    comment="VLAN 96 - Red invitados"

# Configuración del AP local (wlan1)
/interface wireless
set [ find default-name=wlan1 ] \
    disabled=no \
    mode=ap-bridge \
    band=2ghz-b/g/n \
    channel-width=20mhz \
    frequency=auto \
    ssid="Agrotech-Office-LP" \
    security-profile=agrotech-private \
    wps-mode=disabled \
    country=argentina \
    comment="AP Local Oficina La Plata"

:log info "MK01: Bridge y wireless configurados."

# ----------------------------------------------------------------------------
# FASE 4: Q-IN-Q ENCAPSULATION - ARQUITECTURA CON VLANs ANIDADAS
# ----------------------------------------------------------------------------

:log info "MK01: Configurando encapsulacion Q-in-Q con S-VLAN 4000..."

# Paso 1: Crear S-VLAN 4000 sobre ether2-isp (Service VLAN de transporte)
/interface vlan
add name=s-vlan-4000 interface=ether2-isp vlan-id=4000 \
    mtu=1590 arp=enabled \
    comment="S-VLAN 4000 - Transporte ISP (Service Tag)"

# Paso 2: Crear C-VLANs anidadas sobre S-VLAN 4000 (Customer VLANs)
# Estas VLANs encapsulan el tráfico corporativo dentro del túnel Q-in-Q

add name=qinq-vlan10 interface=s-vlan-4000 vlan-id=10 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 10 - Servers (encapsulada en S-VLAN 4000)"

add name=qinq-vlan20 interface=s-vlan-4000 vlan-id=20 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 20 - Desktop (encapsulada en S-VLAN 4000)"

add name=qinq-vlan90 interface=s-vlan-4000 vlan-id=90 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 90 - Private WiFi (encapsulada en S-VLAN 4000)"

add name=qinq-vlan96 interface=s-vlan-4000 vlan-id=96 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 96 - Guest WiFi (encapsulada en S-VLAN 4000)"

add name=qinq-vlan201 interface=s-vlan-4000 vlan-id=201 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 201 - CCTV (encapsulada en S-VLAN 4000)"

:log info "MK01: Q-in-Q VLANs anidadas creadas exitosamente."

# ----------------------------------------------------------------------------
# FASE 5: VLANs LOCALES EN BRIDGE (SIN Q-in-Q)
# ----------------------------------------------------------------------------

:log info "MK01: Creando VLANs locales en bridge..."

# VLANs locales que NO atraviesan Q-in-Q (tráfico local de La Plata)
/interface vlan
add name=vlan10-local interface=BR-LOCAL vlan-id=10 \
    comment="VLAN 10 - Servers (Local La Plata)"

add name=vlan20-local interface=BR-LOCAL vlan-id=20 \
    comment="VLAN 20 - Desktop (Local La Plata)"

add name=vlan90-local interface=BR-LOCAL vlan-id=90 \
    comment="VLAN 90 - Private WiFi (Local La Plata)"

add name=vlan96-local interface=BR-LOCAL vlan-id=96 \
    comment="VLAN 96 - Guest WiFi (Local La Plata)"

add name=vlan201-local interface=BR-LOCAL vlan-id=201 \
    comment="VLAN 201 - CCTV (Local La Plata)"

add name=vlan999-mgmt interface=BR-LOCAL vlan-id=999 \
    comment="VLAN 999 - Management Network"

:log info "MK01: VLANs locales creadas."

# ----------------------------------------------------------------------------
# FASE 6: PUERTOS DEL BRIDGE Y VLAN FILTERING
# ----------------------------------------------------------------------------

:log info "MK01: Configurando puertos del bridge..."

/interface bridge port
# ether3: Management untagged (VLAN 999)
add bridge=BR-LOCAL interface=ether3-mgmt pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Management Access - VLAN 999 Untagged"

# ether4: Desktop/Servers untagged (VLAN 10)
add bridge=BR-LOCAL interface=ether4-local pvid=10 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Local Access - VLAN 10 Untagged"

# ether5: CCTV/IoT untagged (VLAN 201)
add bridge=BR-LOCAL interface=ether5-local pvid=201 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Local Access - VLAN 201 Untagged"

# wlan1: AP local (VLANs 90 y 96 tagged)
add bridge=BR-LOCAL interface=wlan1 \
    frame-types=admit-all \
    comment="AP Local - VLANs 90/96 Tagged"

# Bridge debe permitir el paso de VLANs tagged en sí mismo
add bridge=BR-LOCAL interface=BR-LOCAL

:log info "MK01: Puertos del bridge configurados."

# Reglas de VLAN filtering en el bridge
/interface bridge vlan
# VLAN 10 - Servers
add bridge=BR-LOCAL vlan-ids=10 \
    tagged=BR-LOCAL \
    untagged=ether4-local

# VLAN 20 - Desktop
add bridge=BR-LOCAL vlan-ids=20 \
    tagged=BR-LOCAL

# VLAN 90 - Private WiFi
add bridge=BR-LOCAL vlan-ids=90 \
    tagged=BR-LOCAL,wlan1

# VLAN 96 - Guest WiFi
add bridge=BR-LOCAL vlan-ids=96 \
    tagged=BR-LOCAL,wlan1

# VLAN 201 - CCTV
add bridge=BR-LOCAL vlan-ids=201 \
    tagged=BR-LOCAL \
    untagged=ether5-local

# VLAN 999 - Management
add bridge=BR-LOCAL vlan-ids=999 \
    tagged=BR-LOCAL \
    untagged=ether3-mgmt

:log info "MK01: VLAN filtering configurado."

# ----------------------------------------------------------------------------
# FASE 7: DIRECCIONAMIENTO IP
# ----------------------------------------------------------------------------

:log info "MK01: Configurando direccionamiento IP..."

# IP de gestión (VLAN 999)
/ip address
add address=10.200.1.1/24 interface=vlan999-mgmt \
    comment="Management IP - VLAN 999"

# IPs de gateway para VLANs corporativas (locales)
add address=192.168.10.1/24 interface=vlan10-local \
    comment="Gateway VLAN 10 - Servers"

add address=192.168.20.1/24 interface=vlan20-local \
    comment="Gateway VLAN 20 - Desktop"

add address=192.168.90.1/24 interface=vlan90-local \
    comment="Gateway VLAN 90 - Private WiFi"

add address=192.168.96.1/24 interface=vlan96-local \
    comment="Gateway VLAN 96 - Guest WiFi"

add address=192.168.201.1/24 interface=vlan201-local \
    comment="Gateway VLAN 201 - CCTV"

# IPs de gateway para VLANs Q-in-Q (remotas via ISP)
add address=192.168.10.1/24 interface=qinq-vlan10 \
    comment="Gateway remoto VLAN 10 via Q-in-Q"

add address=192.168.20.1/24 interface=qinq-vlan20 \
    comment="Gateway remoto VLAN 20 via Q-in-Q"

add address=192.168.90.1/24 interface=qinq-vlan90 \
    comment="Gateway remoto VLAN 90 via Q-in-Q"

add address=192.168.96.1/24 interface=qinq-vlan96 \
    comment="Gateway remoto VLAN 96 via Q-in-Q"

add address=192.168.201.1/24 interface=qinq-vlan201 \
    comment="Gateway remoto VLAN 201 via Q-in-Q"

# IP WAN simulada (laboratorio)
add address=10.10.10.2/30 interface=ether1-wan \
    comment="WAN IP - Simulacion laboratorio"

:log info "MK01: IPs configuradas."

# Rutas
/ip route
add dst-address=0.0.0.0/0 gateway=10.10.10.1 distance=1 \
    comment="Default route to Internet"

:log info "MK01: Enrutamiento configurado."

# ----------------------------------------------------------------------------
# FASE 8: DHCP SERVER Y POOLS
# ----------------------------------------------------------------------------

:log info "MK01: Configurando servidor DHCP..."

# Pools de direcciones IP
/ip pool
add name=pool-vlan10 ranges=192.168.10.100-192.168.10.250 \
    comment="Pool VLAN 10 - Servers"

add name=pool-vlan20 ranges=192.168.20.100-192.168.20.250 \
    comment="Pool VLAN 20 - Desktop"

add name=pool-vlan90 ranges=192.168.90.100-192.168.90.250 \
    comment="Pool VLAN 90 - Private WiFi"

add name=pool-vlan96 ranges=192.168.96.100-192.168.96.250 \
    comment="Pool VLAN 96 - Guest WiFi"

add name=pool-vlan201 ranges=192.168.201.100-192.168.201.250 \
    comment="Pool VLAN 201 - CCTV"

# Servidores DHCP para VLANs locales
/ip dhcp-server
add name=dhcp-vlan10 interface=vlan10-local \
    address-pool=pool-vlan10 \
    lease-time=1h \
    disabled=no

add name=dhcp-vlan20 interface=vlan20-local \
    address-pool=pool-vlan20 \
    lease-time=1h \
    disabled=no

add name=dhcp-vlan90 interface=vlan90-local \
    address-pool=pool-vlan90 \
    lease-time=8h \
    disabled=no

add name=dhcp-vlan96 interface=vlan96-local \
    address-pool=pool-vlan96 \
    lease-time=1h \
    disabled=no

add name=dhcp-vlan201 interface=vlan201-local \
    address-pool=pool-vlan201 \
    lease-time=24h \
    disabled=no

# Servidores DHCP para VLANs remotas (Q-in-Q)
add name=dhcp-qinq-vlan10 interface=qinq-vlan10 \
    address-pool=pool-vlan10 \
    lease-time=1h \
    disabled=no

add name=dhcp-qinq-vlan20 interface=qinq-vlan20 \
    address-pool=pool-vlan20 \
    lease-time=1h \
    disabled=no

add name=dhcp-qinq-vlan90 interface=qinq-vlan90 \
    address-pool=pool-vlan90 \
    lease-time=8h \
    disabled=no

add name=dhcp-qinq-vlan96 interface=qinq-vlan96 \
    address-pool=pool-vlan96 \
    lease-time=1h \
    disabled=no

add name=dhcp-qinq-vlan201 interface=qinq-vlan201 \
    address-pool=pool-vlan201 \
    lease-time=24h \
    disabled=no

# Redes DHCP
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 \
    dns-server=192.168.10.1 \
    comment="VLAN 10 - Servers"

add address=192.168.20.0/24 gateway=192.168.20.1 \
    dns-server=192.168.20.1 \
    comment="VLAN 20 - Desktop"

add address=192.168.90.0/24 gateway=192.168.90.1 \
    dns-server=192.168.90.1 \
    comment="VLAN 90 - Private WiFi"

add address=192.168.96.0/24 gateway=192.168.96.1 \
    dns-server=192.168.96.1 \
    domain=guest.agrotech.local \
    comment="VLAN 96 - Guest WiFi"

add address=192.168.201.0/24 gateway=192.168.201.1 \
    dns-server=192.168.201.1 \
    comment="VLAN 201 - CCTV"

:log info "MK01: DHCP configurado."

# DNS Server
/ip dns
set allow-remote-requests=yes \
    servers=8.8.8.8,1.1.1.1 \
    cache-size=4096KiB

:log info "MK01: DNS configurado."

# ----------------------------------------------------------------------------
# FASE 9: FIREWALL Y NAT
# ----------------------------------------------------------------------------

:log info "MK01: Configurando firewall y NAT..."

# ============================================================================
# CHAIN INPUT - Protección del router
# ============================================================================
/ip firewall filter

# Aceptar established/related
add chain=input connection-state=established,related \
    action=accept \
    comment="01-INPUT: Accept established/related"

# Aceptar ICMP (ping)
add chain=input protocol=icmp icmp-options=8:0 \
    action=accept \
    comment="02-INPUT: Accept ICMP Echo Request"

# Aceptar desde red de gestión
add chain=input src-address=10.200.1.0/24 \
    action=accept \
    comment="03-INPUT: Accept from Management VLAN 999"

# Aceptar desde redes corporativas
add chain=input src-address=192.168.0.0/16 \
    action=accept \
    comment="04-INPUT: Accept from Corporate VLANs"

# Log y drop todo lo demás
add chain=input \
    action=log \
    log-prefix="DROP-INPUT: " \
    comment="05-INPUT: Log dropped input"

add chain=input \
    action=drop \
    comment="06-INPUT: Drop all other input"

# ============================================================================
# CHAIN FORWARD - Control de tráfico entre VLANs
# ============================================================================

# Aceptar established/related
add chain=forward connection-state=established,related \
    action=accept \
    comment="01-FORWARD: Accept established/related"

# Aceptar invalid con log (troubleshooting)
add chain=forward connection-state=invalid \
    action=log \
    log-prefix="INVALID-FWD: " \
    comment="02-FORWARD: Log invalid connections"

add chain=forward connection-state=invalid \
    action=drop \
    comment="03-FORWARD: Drop invalid connections"

# Permitir CCTV (201) a Servers (10) - Acceso a grabadores NVR
add chain=forward \
    src-address=192.168.201.0/24 \
    dst-address=192.168.10.0/24 \
    action=accept \
    comment="04-FORWARD: Allow CCTV to Servers"

# Permitir Servers (10) a CCTV (201) - Gestión de cámaras
add chain=forward \
    src-address=192.168.10.0/24 \
    dst-address=192.168.201.0/24 \
    action=accept \
    comment="05-FORWARD: Allow Servers to CCTV"

# AISLAMIENTO DE RED GUEST (96)
# Bloquear Guest a todas las redes corporativas
add chain=forward \
    src-address=192.168.96.0/24 \
    dst-address=192.168.0.0/16 \
    action=drop \
    comment="06-FORWARD: Guest isolation - Block to corporate"

# Bloquear redes corporativas a Guest (paranoia)
add chain=forward \
    src-address=192.168.0.0/16 \
    dst-address=192.168.96.0/24 \
    action=drop \
    comment="07-FORWARD: Block corporate to Guest"

# Permitir Guest solo a Internet
add chain=forward \
    src-address=192.168.96.0/24 \
    out-interface=ether1-wan \
    action=accept \
    comment="08-FORWARD: Allow Guest to Internet only"

# PROTECCIÓN VLAN 201 (CCTV)
# Las cámaras NO deben iniciar conexiones a Internet
add chain=forward \
    src-address=192.168.201.0/24 \
    dst-address=!192.168.0.0/16 \
    action=drop \
    comment="09-FORWARD: Block CCTV to Internet"

# Aceptar tráfico entre VLANs corporativas (10, 20, 90)
add chain=forward \
    src-address=192.168.0.0/16 \
    dst-address=192.168.0.0/16 \
    action=accept \
    comment="10-FORWARD: Allow inter-VLAN corporate traffic"

# Aceptar hacia Internet desde corporativas
add chain=forward \
    src-address=192.168.0.0/16 \
    out-interface=ether1-wan \
    action=accept \
    comment="11-FORWARD: Allow corporate to Internet"

# Log y drop todo lo demás
add chain=forward \
    action=log \
    log-prefix="DROP-FORWARD: " \
    comment="12-FORWARD: Log dropped forward"

add chain=forward \
    action=drop \
    comment="13-FORWARD: Drop all other forward"

:log info "MK01: Firewall configurado."

# ============================================================================
# NAT - Masquerade para salida a Internet
# ============================================================================
/ip firewall nat
add chain=srcnat out-interface=ether1-wan \
    action=masquerade \
    comment="NAT - Masquerade to Internet"

:log info "MK01: NAT configurado."

# ============================================================================
# MANGLE - MSS Clamping para MTU Q-in-Q
# ============================================================================
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu \
    passthrough=yes \
    comment="MSS Clamp for Q-in-Q MTU 1590"

:log info "MK01: MSS Clamping configurado."

# ----------------------------------------------------------------------------
# FASE 10: MONITOREO Y GESTIÓN
# ----------------------------------------------------------------------------

:log info "MK01: Configurando monitoreo..."

# NTP Client
/system ntp client
set enabled=yes \
    primary-ntp=200.23.1.7 \
    secondary-ntp=200.23.1.1

# SNMP
/snmp
set enabled=yes \
    contact="laboratorio@agrotech.local" \
    location="La Plata - Gateway Central" \
    trap-community=public \
    trap-version=2

# Logging
/system logging
add topics=error,critical,warning \
    action=memory \
    prefix="MK01"

# Email alerts (configurar SMTP real)
/tool e-mail
set address=smtp.gmail.com \
    port=587 \
    start-tls=yes \
    from="protocolosinlambrica@gmail.com" \
    user="protocolosinlambrica@gmail.com" \
    password="protocolos.25"

/system logging action
add name=email-alert target=email \
    email-to="protocolosinlambrica@gmail.com"

/system logging
add topics=error,critical \
    action=email-alert \
    prefix="CRITICAL-MK01"

:log info "MK01: Monitoreo configurado."

# ----------------------------------------------------------------------------
# FASE 11: SEGURIDAD Y SERVICIOS
# ----------------------------------------------------------------------------

:log info "MK01: Configurando servicios y seguridad..."

# Deshabilitar servicios innecesarios
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no port=80
set ssh disabled=no port=22
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox disabled=no port=8291

# Deshabilitar MAC Server en interfaces públicas
/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=none

# Permitir MAC Winbox solo en gestión
/interface list
add name=MGMT comment="Management interfaces"
/interface list member
add list=MGMT interface=ether3-mgmt
add list=MGMT interface=vlan999-mgmt

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

# Bandwidth test server (para diagnóstico)
/tool bandwidth-server
set enabled=yes authenticate=yes

:log info "MK01: Servicios configurados."

# ----------------------------------------------------------------------------
# FASE 12: SCRIPTS DE DIAGNÓSTICO
# ----------------------------------------------------------------------------

:log info "MK01: Creando scripts de diagnostico..."

# Script para verificar Q-in-Q
/system script
add name=check-qinq \
    source={
        :log info "=== Q-in-Q Status Check ==="
        :log info "S-VLAN 4000 Status:"
        /interface print stats where name="s-vlan-4000"
        :log info "C-VLANs Status:"
        /interface print stats where name~"qinq-vlan"
        :log info "=== End Check ==="
    } \
    comment="Verificar estado de encapsulacion Q-in-Q"

# Script para verificar conectividad
add name=check-connectivity \
    source={
        :log info "=== Connectivity Check ==="
        :local gateways {"10.200.1.10";"10.200.1.20";"10.200.1.50";"10.200.1.51"}
        :foreach gw in=$gateways do={
            :log info ("Ping to " . $gw . ":")
            /ping $gw count=3
        }
        :log info "=== End Check ==="
    } \
    comment="Verificar conectividad a equipos remotos"

:log info "MK01: Scripts creados."

# ----------------------------------------------------------------------------
# FASE 13: BACKUP AUTOMÁTICO
# ----------------------------------------------------------------------------

# Scheduler para backup automático
/system scheduler
add name=auto-backup \
    interval=1d \
    start-time=03:00:00 \
    on-event="/system backup save name=(\"MK01-auto-\" . \
        [:pick [/system clock get date] 7 11] . \
        [:pick [/system clock get date] 0 3] . \
        [:pick [/system clock get date] 4 6])" \
    comment="Backup diario automatico a las 3 AM"

:log info "MK01: Backup automatico configurado."

# ----------------------------------------------------------------------------
# CONFIGURACIÓN COMPLETA
# ----------------------------------------------------------------------------

:log warning "============================================"
:log warning "MK01 - CONFIGURACION COMPLETADA EXITOSAMENTE"
:log warning "============================================"
:log warning "Gateway La Plata - Q-in-Q Encapsulator"
:log warning "Management IP: 10.200.1.1/24"
:log warning "Acceso: ether3-mgmt (VLAN 999 untagged)"
:log warning "Q-in-Q: S-VLAN 4000 en ether2-isp"
:log warning "C-VLANs: 10,20,90,96,201"
:log warning "============================================"
:log warning "VERIFICAR:"
:log warning "1. Conectar WAN en ether1-wan"
:log warning "2. Conectar ISP trunk en ether2-isp"
:log warning "3. Conectar laptop management en ether3-mgmt"
:log warning "4. Verificar Q-in-Q: /system script run check-qinq"
:log warning "5. Test conectividad: /system script run check-connectivity"
:log warning "============================================"

# FIN DEL SCRIPT
