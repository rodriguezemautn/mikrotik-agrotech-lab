# ============================================================================
# MK02 - AGROTECH MAGDALENA AP - CONFIGURACIÓN CORREGIDA
# ============================================================================
# Fecha: 28/11/2025
# Modelo: MikroTik RB951Ui-2HnD
# Función: Hub Desencapsulador Q-in-Q
# Ubicación: Magdalena Ciudad
# 
# CORRECCIONES APLICADAS:
# - Removida vlan999-extracted del bridge port (CRÍTICO)
# - Corregido VLAN filtering para VLAN 999
# - Limpiadas rutas duplicadas
# - Optimizadas configuraciones
# ============================================================================

# --- RESET (OPCIONAL - COMENTADO POR SEGURIDAD) ---
# /system reset-configuration no-defaults=yes skip-backup=yes

# --- INTERFACES ---
/interface bridge
add comment="Bridge L2 para transporte transparente de VLANs" \
    name=BR-TRANSPORT \
    vlan-filtering=yes \
    protocol-mode=rstp \
    admin-mac=D4:CA:6D:FC:52:98 \
    auto-mac=no

/interface ethernet
set [ find default-name=ether1 ] \
    comment="Trunk to SXT-MG via CABLE" \
    name=ether1-to-sxt \
    l2mtu=1600 \
    mtu=1590

set [ find default-name=ether2 ] \
    comment="ISP Q-in-Q Trunk from MK01" \
    name=ether2-isp \
    l2mtu=1600 \
    mtu=1590

set [ find default-name=ether3 ] \
    comment="Management Access" \
    name=ether3-mgmt \
    l2mtu=1600

set [ find default-name=ether4 ] \
    comment="Local Trunk opcional" \
    name=ether4-local \
    l2mtu=1600

set [ find default-name=ether5 ] \
    comment="Local Trunk opcional" \
    name=ether5-local \
    l2mtu=1600

/interface wireless
set [ find default-name=wlan1 ] \
    comment="Disponible para AP local futuro" \
    ssid=MikroTik \
    disabled=yes

/interface wireless manual-tx-power-table
set wlan1 comment="Disponible para AP local futuro"

/interface wireless nstreme
set wlan1 comment="Disponible para AP local futuro"

# --- VLAN INTERFACES ---
/interface vlan
add comment="S-VLAN 4000 - Recepcion desde ISP (Service Tag)" \
    interface=ether2-isp \
    name=s-vlan-4000-in \
    vlan-id=4000 \
    mtu=1590

add comment="C-VLAN 10 - Extraida de Q-in-Q" \
    interface=s-vlan-4000-in \
    name=vlan10-extracted \
    vlan-id=10 \
    mtu=1580

add comment="C-VLAN 20 - Extraida de Q-in-Q" \
    interface=s-vlan-4000-in \
    name=vlan20-extracted \
    vlan-id=20 \
    mtu=1580

add comment="C-VLAN 90 - Extraida de Q-in-Q" \
    interface=s-vlan-4000-in \
    name=vlan90-extracted \
    vlan-id=90 \
    mtu=1580

add comment="C-VLAN 96 - Extraida de Q-in-Q" \
    interface=s-vlan-4000-in \
    name=vlan96-extracted \
    vlan-id=96 \
    mtu=1580

add comment="C-VLAN 201 - Extraida de Q-in-Q" \
    interface=s-vlan-4000-in \
    name=vlan201-extracted \
    vlan-id=201 \
    mtu=1580

add comment="C-VLAN 999 - Extraida de Q-in-Q - Management" \
    interface=s-vlan-4000-in \
    name=vlan999-extracted \
    vlan-id=999 \
    mtu=1580

# --- INTERFACE LISTS ---
/interface list
add comment="Management interfaces" name=MGMT

/interface list member
add interface=ether3-mgmt list=MGMT
add interface=vlan999-extracted list=MGMT

# --- WIRELESS SECURITY PROFILES ---
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik

# --- BRIDGE PORTS ---
# IMPORTANTE: vlan999-extracted NO está aquí (CORREGIDO)
/interface bridge port
add bridge=BR-TRANSPORT \
    comment="C-VLAN 10 desencapsulada" \
    interface=vlan10-extracted

add bridge=BR-TRANSPORT \
    comment="C-VLAN 20 desencapsulada" \
    interface=vlan20-extracted

add bridge=BR-TRANSPORT \
    comment="C-VLAN 90 desencapsulada" \
    interface=vlan90-extracted

add bridge=BR-TRANSPORT \
    comment="C-VLAN 96 desencapsulada" \
    interface=vlan96-extracted

add bridge=BR-TRANSPORT \
    comment="C-VLAN 201 desencapsulada" \
    interface=vlan201-extracted

add bridge=BR-TRANSPORT \
    comment="Trunk to SXT-MG via CABLE - All VLANs" \
    interface=ether1-to-sxt \
    frame-types=admit-all

add bridge=BR-TRANSPORT \
    comment="Management Access - VLAN 999 Untagged" \
    interface=ether3-mgmt \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    pvid=999

add bridge=BR-TRANSPORT \
    comment="Local Trunk opcional - All VLANs" \
    interface=ether4-local \
    frame-types=admit-all

add bridge=BR-TRANSPORT \
    comment="Local Trunk opcional - All VLANs" \
    interface=ether5-local \
    frame-types=admit-all

# NOTA CRÍTICA: vlan999-extracted NO está como bridge port
# Esto permite que la interfaz funcione correctamente para routing

# --- BRIDGE VLAN FILTERING ---
/interface bridge vlan
add bridge=BR-TRANSPORT \
    vlan-ids=10 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

add bridge=BR-TRANSPORT \
    vlan-ids=20 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

add bridge=BR-TRANSPORT \
    vlan-ids=90 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

add bridge=BR-TRANSPORT \
    vlan-ids=96 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

add bridge=BR-TRANSPORT \
    vlan-ids=201 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

add bridge=BR-TRANSPORT \
    vlan-ids=999 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local \
    untagged=ether3-mgmt

# NOTA: vlan999-extracted NO está en tagged (CORREGIDO)

# --- IP ADDRESSING ---
/ip address
add address=10.200.1.10/24 \
    comment="Management IP - VLAN 999 via Q-in-Q" \
    interface=vlan999-extracted \
    network=10.200.1.0

# --- DNS ---
/ip dns
set servers=10.200.1.1 \
    allow-remote-requests=yes \
    cache-size=2048KiB

# --- FIREWALL FILTER ---
/ip firewall filter
add action=accept \
    chain=input \
    comment="01-INPUT: Accept established/related" \
    connection-state=established,related

add action=accept \
    chain=input \
    comment="02-INPUT: Accept ICMP" \
    protocol=icmp \
    icmp-options=8:0

add action=accept \
    chain=input \
    comment="03-INPUT: Accept from Management VLAN 999" \
    src-address=10.200.1.0/24

add action=accept \
    chain=input \
    comment="04-INPUT: Accept from Corporate VLANs" \
    src-address=192.168.0.0/16

add action=log \
    chain=input \
    comment="05-INPUT: Log dropped input" \
    log-prefix="DROP-INPUT-MK02: "

add action=drop \
    chain=input \
    comment="06-INPUT: Drop all other input"

add action=accept \
    chain=forward \
    comment="01-FORWARD: Accept established/related" \
    connection-state=established,related

add action=drop \
    chain=forward \
    comment="02-FORWARD: Drop invalid" \
    connection-state=invalid

add action=accept \
    chain=forward \
    comment="03-FORWARD: Accept all (L2 bridge)"

# --- FIREWALL MANGLE ---
/ip firewall mangle
add action=change-mss \
    chain=forward \
    comment="MSS Clamp for Q-in-Q MTU 1590" \
    new-mss=clamp-to-pmtu \
    passthrough=yes \
    protocol=tcp \
    tcp-flags=syn

# --- IP ROUTES ---
/ip route
add comment="Default route to MK01" \
    distance=1 \
    dst-address=0.0.0.0/0 \
    gateway=10.200.1.1

add comment="Corporate VLANs via MK01" \
    distance=1 \
    dst-address=192.168.0.0/16 \
    gateway=10.200.1.1

# NOTA: La ruta a 10.200.1.0/24 es CONNECTED automáticamente
# porque vlan999-extracted tiene la IP 10.200.1.10/24

# --- IP SERVICES ---
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no
set ssh disabled=no port=22
set www-ssl disabled=yes
set api disabled=yes
set winbox disabled=no port=8291
set api-ssl disabled=yes

# --- SNMP ---
/snmp
set enabled=yes \
    contact=protocolosinlambrica@gmail.com \
    location="Magdalena - Hub Desencapsulador Q-in-Q" \
    trap-version=2 \
    trap-community=public

# --- SYSTEM SETTINGS ---
/system clock
set time-zone-name=America/Argentina/Buenos_Aires

/system identity
set name=MK02-agrotech-mg-ap

/system logging
add prefix=MK02 topics=error,critical,warning

/system ntp client
set enabled=yes \
    primary-ntp=10.200.1.1 \
    secondary-ntp=200.23.1.7

# --- SCHEDULER ---
/system scheduler
add comment="Backup diario automatico a las 3:15 AM" \
    interval=1d \
    name=auto-backup \
    on-event="/system backup save name=(\"MK02-auto-\" . \
        [:pick [/system clock get date] 7 11] . \
        [:pick [/system clock get date] 0 3] . \
        [:pick [/system clock get date] 4 6])" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 \
    start-time=03:15:00

add comment="Verificacion de conectividad cada hora" \
    interval=1h \
    name=hourly-connectivity-check \
    on-event="/system script run ping-test-topology" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 \
    start-time=00:05:00

# --- SCRIPTS ---
/system script
add comment="Verificar desencapsulacion Q-in-Q" \
    dont-require-permissions=no \
    name=check-qinq-decap \
    owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source={
        :log info "=== Q-in-Q Decapsulation Status ==="
        :log info "S-VLAN 4000 Input:"
        /interface print stats where name="s-vlan-4000-in"
        :log info "Extracted C-VLANs:"
        /interface print stats where name~"extracted"
        :log info "=== End Check ==="
    }

add comment="Verificar trunk por cable a SXT-MG" \
    dont-require-permissions=no \
    name=check-trunk-sxt \
    owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source={
        :log info "=== Trunk to SXT-MG Status ==="
        :log info "ether1-to-sxt stats:"
        /interface print stats where name="ether1-to-sxt"
        :log info "Bridge VLAN stats:"
        /interface bridge vlan print where bridge=BR-TRANSPORT
        :log info "=== End Check ==="
    }

add comment="Verificar bridge y VLANs" \
    dont-require-permissions=no \
    name=check-bridge \
    owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source={
        :log info "=== Bridge Status ==="
        /interface bridge print
        /interface bridge port print
        /interface bridge vlan print
        :log info "=== End Check ==="
    }

add comment="Test conectividad a toda la topologia" \
    dont-require-permissions=no \
    name=ping-test-topology \
    owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source={
        :log info "=== Connectivity Test ==="
        :local targets {"10.200.1.1";"10.200.1.50";"10.200.1.51";"10.200.1.20"}
        :local names {"MK01";"SXT-MG";"SXT-CA";"MK03"}
        :local i 0
        :foreach t in=$targets do={
            :local name [:pick $names $i]
            :log info ("Testing " . $name . " (" . $t . ")")
            :if ([/ping $t count=3] > 0) do={
                :log info ("  " . $name . " - ONLINE")
            } else={
                :log error ("  " . $name . " - OFFLINE")
            }
            :set i ($i + 1)
        }
        :log info "=== End Test ==="
    }

add comment="Diagnostico completo de MK02" \
    dont-require-permissions=no \
    name=full-diagnostic \
    owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source={
        :log info "=== MK02 FULL DIAGNOSTIC ==="
        
        :log info "1. INTERFACES:"
        /interface print stats where name~"ether" or name~"vlan"
        
        :log info "2. BRIDGE STATUS:"
        /interface bridge print
        
        :log info "3. BRIDGE PORTS (vlan999-extracted NO debe estar aqui):"
        /interface bridge port print where bridge=BR-TRANSPORT
        
        :log info "4. VLAN FILTERING:"
        /interface bridge vlan print where bridge=BR-TRANSPORT
        
        :log info "5. IP ADDRESSES:"
        /ip address print
        
        :log info "6. ROUTES:"
        /ip route print
        
        :log info "7. ARP TABLE:"
        /ip arp print where address~"10.200.1"
        
        :log info "8. CONNECTIVITY TESTS:"
        :log info "Ping to MK01:"
        /ping 10.200.1.1 count=3
        :log info "Ping to SXT-MG:"
        /ping 10.200.1.50 count=3
        
        :log info "=== END DIAGNOSTIC ==="
    }

# --- TOOL SETTINGS ---
/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

/tool mac-server ping
set enabled=yes

# --- BANDWIDTH SERVER ---
/tool bandwidth-server
set enabled=yes \
    authenticate=yes \
    allocate-udp-ports-from=2000

# --- EMAIL (OPCIONAL) ---
# /tool e-mail
# set address=smtp.gmail.com \
#     from=protocolosinlambrica@gmail.com \
#     password=your_password_here \
#     port=587 \
#     start-tls=yes \
#     user=protocolosinlambrica@gmail.com

# ============================================================================
# FIN DE CONFIGURACIÓN MK02
# ============================================================================
# 
# VERIFICACIÓN POST-APLICACIÓN:
# 
# 1. Verificar que vlan999-extracted NO está en bridge port:
#    /interface bridge port print where interface=vlan999-extracted
#    (NO debe aparecer nada)
#
# 2. Verificar IP management:
#    /ip address print where interface=vlan999-extracted
#    (Debe mostrar: 10.200.1.10/24)
#
# 3. Verificar conectividad a MK01:
#    /ping 10.200.1.1 count=10
#    (Debe tener 0% packet loss)
#
# 4. Verificar conectividad a SXT-MG:
#    /ping 10.200.1.50 count=10
#    (Debe tener 0% packet loss)
#
# 5. Ejecutar diagnóstico completo:
#    /system script run full-diagnostic
#
# ============================================================================
