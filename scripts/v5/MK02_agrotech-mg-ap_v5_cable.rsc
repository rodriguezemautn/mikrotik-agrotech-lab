# ============================================================================
# AGROTECH NETWORK - LABORATORIO DE RADIOENLACES
# ============================================================================
# Dispositivo: MK02 - agrotech-mg-ap (RB951ui-2HnD)
# Versión: 5.0 CORREGIDO - Optimizado RouterOS 6.49.x
# Fecha: 15/Nov/2025
# Autores: Rodriguez Emanuel (19288) / Del Vecchio Guillermo (27224)
# ============================================================================
# ROL: Hub Magdalena - Desencapsulador Q-in-Q
#      - Desencapsulación Q-in-Q (extrae C-VLANs de S-VLAN 4000)
#      - Trunk por CABLE a SXT-MG via ether1
#      - Bridge L2 transparente para VLANs corporativas
# ============================================================================
# CONFIGURACIÓN DE GESTIÓN: 
#      - IP: 10.200.1.10/24 en VLAN 999
#      - Acceso: ether3 (Untagged VLAN 999)
#      - Conexión upstream: ether2 (Q-in-Q trunk desde MK01)
#      - Conexión downstream: ether1 (Cable trunk a SXT-MG)
# ============================================================================
# CABLEADO CRÍTICO:
#      MK02-ether1 ──Cat5e──► SXT-MG-ether1
# ============================================================================

# ----------------------------------------------------------------------------
# FASE 0: CONFIGURACIÓN INICIAL DEL SISTEMA
# ----------------------------------------------------------------------------

/system identity set name="MK02-agrotech-mg-ap"
/system clock set time-zone-name=America/Argentina/Buenos_Aires

# Usuarios y contraseñas
/user set [find name=admin] password="Lab2025!" comment="Usuario administrador principal"
/user add name=laboratorio group=full password="Lab2025!" \
    comment="Usuario para configuracion de laboratorio"

# ----------------------------------------------------------------------------
# FASE 1: LIMPIEZA COMPLETA
# ----------------------------------------------------------------------------

:log info "MK02: Iniciando limpieza de configuracion previa..."

/ip dhcp-client remove [find]
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

:log info "MK02: Limpieza completada."

# ----------------------------------------------------------------------------
# FASE 2: CONFIGURACIÓN DE HARDWARE Y MTU
# ----------------------------------------------------------------------------

:log info "MK02: Configurando MTU y L2MTU..."

/interface ethernet
set [ find default-name=ether1 ] name=ether1-to-sxt l2mtu=1600 mtu=1590 \
    comment="Trunk to SXT-MG via CABLE"
set [ find default-name=ether2 ] name=ether2-isp l2mtu=1600 mtu=1590 \
    comment="ISP Q-in-Q Trunk from MK01"
set [ find default-name=ether3 ] name=ether3-mgmt l2mtu=1600 mtu=1500 \
    comment="Management Access"
set [ find default-name=ether4 ] name=ether4-local l2mtu=1600 mtu=1500 \
    comment="Local Trunk opcional"
set [ find default-name=ether5 ] name=ether5-local l2mtu=1600 mtu=1500 \
    comment="Local Trunk opcional"

:log info "MK02: MTU configurado."

# ----------------------------------------------------------------------------
# FASE 3: BRIDGE PRINCIPAL PARA L2 TRANSPORT
# ----------------------------------------------------------------------------

:log info "MK02: Creando bridge principal..."

/interface bridge
add name=BR-TRANSPORT vlan-filtering=yes protocol-mode=rstp \
    frame-types=admit-all \
    comment="Bridge L2 para transporte transparente de VLANs"

:log info "MK02: Bridge creado."

# ----------------------------------------------------------------------------
# FASE 4: Q-IN-Q DECAPSULATION - EXTRACCIÓN DE C-VLANs
# ----------------------------------------------------------------------------

:log info "MK02: Configurando desencapsulacion Q-in-Q..."

# Paso 1: Crear interfaz para S-VLAN 4000 (recepción desde MK01)
/interface vlan
add name=s-vlan-4000-in interface=ether2-isp vlan-id=4000 \
    mtu=1590 arp=enabled \
    comment="S-VLAN 4000 - Recepcion desde ISP (Service Tag)"

# Paso 2: Extraer C-VLANs desde S-VLAN 4000
add name=vlan10-extracted interface=s-vlan-4000-in vlan-id=10 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 10 - Extraida de Q-in-Q"

add name=vlan20-extracted interface=s-vlan-4000-in vlan-id=20 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 20 - Extraida de Q-in-Q"

add name=vlan90-extracted interface=s-vlan-4000-in vlan-id=90 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 90 - Extraida de Q-in-Q"

add name=vlan96-extracted interface=s-vlan-4000-in vlan-id=96 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 96 - Extraida de Q-in-Q"

add name=vlan201-extracted interface=s-vlan-4000-in vlan-id=201 \
    mtu=1580 arp=enabled \
    comment="C-VLAN 201 - Extraida de Q-in-Q"

:log info "MK02: C-VLANs extraidas exitosamente."

# Paso 3: Crear VLAN 999 para gestión
add name=vlan999-mgmt interface=BR-TRANSPORT vlan-id=999 \
    comment="VLAN 999 - Management"

:log info "MK02: Desencapsulacion Q-in-Q configurada."

# ----------------------------------------------------------------------------
# FASE 5: WIRELESS (OPCIONAL - AP LOCAL FUTURO)
# ----------------------------------------------------------------------------

:log info "MK02: Wireless deshabilitado (no usado en esta topologia)..."

# Dejar wlan1 deshabilitado (puede usarse futuro para AP local oficina)
/interface wireless
set [ find default-name=wlan1 ] disabled=yes \
    comment="Disponible para AP local futuro"

:log info "MK02: Wireless deshabilitado."

# ----------------------------------------------------------------------------
# FASE 6: PUERTOS DEL BRIDGE Y VLAN FILTERING
# ----------------------------------------------------------------------------

:log info "MK02: Configurando puertos del bridge..."

/interface bridge port
# Agregar VLANs extraídas al bridge (tráfico desencapsulado)
add bridge=BR-TRANSPORT interface=vlan10-extracted \
    comment="C-VLAN 10 desencapsulada"
add bridge=BR-TRANSPORT interface=vlan20-extracted \
    comment="C-VLAN 20 desencapsulada"
add bridge=BR-TRANSPORT interface=vlan90-extracted \
    comment="C-VLAN 90 desencapsulada"
add bridge=BR-TRANSPORT interface=vlan96-extracted \
    comment="C-VLAN 96 desencapsulada"
add bridge=BR-TRANSPORT interface=vlan201-extracted \
    comment="C-VLAN 201 desencapsulada"

# ether1: Trunk CABLE hacia SXT-MG (TODAS las VLANs tagged)
add bridge=BR-TRANSPORT interface=ether1-to-sxt \
    frame-types=admit-all \
    comment="Trunk to SXT-MG via CABLE - All VLANs"

# ether3: Management (VLAN 999 untagged)
add bridge=BR-TRANSPORT interface=ether3-mgmt pvid=999 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Management Access - VLAN 999 Untagged"

# ether4/5: Trunk local opcional (todas las VLANs tagged)
add bridge=BR-TRANSPORT interface=ether4-local \
    frame-types=admit-all \
    comment="Local Trunk opcional - All VLANs"

add bridge=BR-TRANSPORT interface=ether5-local \
    frame-types=admit-all \
    comment="Local Trunk opcional - All VLANs"

# Bridge en sí mismo
add bridge=BR-TRANSPORT interface=BR-TRANSPORT

:log info "MK02: Puertos configurados."

# VLAN Filtering
/interface bridge vlan
# VLAN 10
add bridge=BR-TRANSPORT vlan-ids=10 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

# VLAN 20
add bridge=BR-TRANSPORT vlan-ids=20 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

# VLAN 90
add bridge=BR-TRANSPORT vlan-ids=90 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

# VLAN 96
add bridge=BR-TRANSPORT vlan-ids=96 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

# VLAN 201
add bridge=BR-TRANSPORT vlan-ids=201 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local

# VLAN 999 - Management
add bridge=BR-TRANSPORT vlan-ids=999 \
    tagged=BR-TRANSPORT,ether1-to-sxt,ether4-local,ether5-local \
    untagged=ether3-mgmt

:log info "MK02: VLAN filtering configurado."

# ----------------------------------------------------------------------------
# FASE 7: DIRECCIONAMIENTO IP Y ENRUTAMIENTO
# ----------------------------------------------------------------------------

:log info "MK02: Configurando IP y enrutamiento..."

# IP de gestión
/ip address
add address=10.200.1.10/24 interface=vlan999-mgmt \
    comment="Management IP - VLAN 999"

# Ruta por defecto a MK01 (gateway central)
/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1 distance=1 \
    comment="Default route to MK01"

# Rutas específicas hacia redes corporativas via MK01
add dst-address=192.168.10.0/24 gateway=10.200.1.1 distance=1 \
    comment="Route to VLAN 10 via MK01"

add dst-address=192.168.20.0/24 gateway=10.200.1.1 distance=1 \
    comment="Route to VLAN 20 via MK01"

add dst-address=192.168.90.0/24 gateway=10.200.1.1 distance=1 \
    comment="Route to VLAN 90 via MK01"

add dst-address=192.168.96.0/24 gateway=10.200.1.1 distance=1 \
    comment="Route to VLAN 96 via MK01"

add dst-address=192.168.201.0/24 gateway=10.200.1.1 distance=1 \
    comment="Route to VLAN 201 via MK01"

:log info "MK02: Enrutamiento configurado."

# DNS forwarding a MK01
/ip dns
set allow-remote-requests=no servers=10.200.1.1

:log info "MK02: DNS configurado."

# ----------------------------------------------------------------------------
# FASE 8: FIREWALL
# ----------------------------------------------------------------------------

:log info "MK02: Configurando firewall..."

/ip firewall filter
# INPUT chain
add chain=input connection-state=established,related \
    action=accept \
    comment="01-INPUT: Accept established/related"

add chain=input protocol=icmp icmp-options=8:0 \
    action=accept \
    comment="02-INPUT: Accept ICMP"

add chain=input src-address=10.200.1.0/24 \
    action=accept \
    comment="03-INPUT: Accept from Management"

add chain=input \
    action=log \
    log-prefix="DROP-INPUT-MK02: " \
    comment="04-INPUT: Log dropped"

add chain=input \
    action=drop \
    comment="05-INPUT: Drop all other"

# FORWARD chain - L2 bridge transparente
add chain=forward connection-state=established,related \
    action=accept \
    comment="01-FORWARD: Accept established/related"

add chain=forward connection-state=invalid \
    action=drop \
    comment="02-FORWARD: Drop invalid"

add chain=forward \
    action=accept \
    comment="03-FORWARD: Accept all (L2 bridge)"

:log info "MK02: Firewall configurado."

# MSS Clamping
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu \
    passthrough=yes \
    comment="MSS Clamp for Q-in-Q MTU"

:log info "MK02: MSS Clamping configurado."

# ----------------------------------------------------------------------------
# FASE 9: MONITOREO Y GESTIÓN
# ----------------------------------------------------------------------------

:log info "MK02: Configurando monitoreo..."

# NTP Client
/system ntp client
set enabled=yes \
    primary-ntp=10.200.1.1 \
    secondary-ntp=200.23.1.7

# SNMP
/snmp
set enabled=yes \
    contact="protocolosinlambrica@gmail.com" \
    location="Magdalena - Hub Desencapsulador Q-in-Q" \
    trap-community=public \
    trap-version=2

# Logging
/system logging
add topics=error,critical,warning \
    action=memory \
    prefix="MK02"

:log info "MK02: Monitoreo configurado."

# ----------------------------------------------------------------------------
# FASE 10: SEGURIDAD Y SERVICIOS
# ----------------------------------------------------------------------------

:log info "MK02: Configurando servicios..."

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no port=80
set ssh disabled=no port=22
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox disabled=no port=8291

# MAC Server solo en gestión
/interface list
add name=MGMT comment="Management interfaces"
/interface list member
add list=MGMT interface=ether3-mgmt
add list=MGMT interface=vlan999-mgmt

/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

/tool bandwidth-server
set enabled=yes authenticate=yes

:log info "MK02: Servicios configurados."

# ----------------------------------------------------------------------------
# FASE 11: SCRIPTS DE DIAGNÓSTICO
# ----------------------------------------------------------------------------

:log info "MK02: Creando scripts de diagnostico..."

/system script
add name=check-qinq-decap \
    source={
        :log info "=== Q-in-Q Decapsulation Status ==="
        :log info "S-VLAN 4000 Input:"
        /interface print stats where name="s-vlan-4000-in"
        :log info "Extracted C-VLANs:"
        /interface print stats where name~"extracted"
        :log info "=== End Check ==="
    } \
    comment="Verificar desencapsulacion Q-in-Q"

add name=check-trunk-sxt \
    source={
        :log info "=== Trunk to SXT-MG Status ==="
        :log info "ether1-to-sxt stats:"
        /interface print stats where name="ether1-to-sxt"
        :log info "Bridge VLAN stats:"
        /interface bridge vlan print where bridge=BR-TRANSPORT
        :log info "=== End Check ==="
    } \
    comment="Verificar trunk por cable a SXT-MG"

add name=check-bridge \
    source={
        :log info "=== Bridge Status ==="
        /interface bridge print
        /interface bridge port print
        /interface bridge vlan print
        :log info "=== End Check ==="
    } \
    comment="Verificar bridge y VLANs"

add name=ping-test-topology \
    source={
        :log info "=== Connectivity Test ==="
        :local targets {"10.200.1.1";"10.200.1.50";"10.200.1.51";"10.200.1.20"}
        :foreach t in=$targets do={
            :log info ("Testing " . $t)
            /ping $t count=3
        }
        :log info "=== End Test ==="
    } \
    comment="Test conectividad a toda la topologia"

:log info "MK02: Scripts creados."

# ----------------------------------------------------------------------------
# FASE 12: BACKUP AUTOMÁTICO
# ----------------------------------------------------------------------------

/system scheduler
add name=auto-backup \
    interval=1d \
    start-time=03:15:00 \
    on-event="/system backup save name=(\"MK02-auto-\" . \
        [:pick [/system clock get date] 7 11] . \
        [:pick [/system clock get date] 0 3] . \
        [:pick [/system clock get date] 4 6])" \
    comment="Backup diario automatico"

:log info "MK02: Backup configurado."

# ----------------------------------------------------------------------------
# CONFIGURACIÓN COMPLETA
# ----------------------------------------------------------------------------

:log warning "============================================"
:log warning "MK02 v5.0 - CONFIGURACION COMPLETADA"
:log warning "============================================"
:log warning "Hub Magdalena - Q-in-Q Decapsulator"
:log warning "Management IP: 10.200.1.10/24"
:log warning "Acceso: ether3-mgmt (VLAN 999 untagged)"
:log warning "Q-in-Q Input: ether2-isp (S-VLAN 4000)"
:log warning "Trunk to SXT: ether1-to-sxt (CABLE)"
:log warning "============================================"
:log warning "CABLEADO REQUERIDO:"
:log warning "  MK02-ether1 ──Cable Cat5e──► SXT-MG-ether1"
:log warning "============================================"
:log warning "VERIFICACION:"
:log warning "1. /system script run check-qinq-decap"
:log warning "2. /system script run check-trunk-sxt"
:log warning "3. /system script run ping-test-topology"
:log warning "============================================"

# FIN DEL SCRIPT
```

---

## 📋 RESUMEN DE CAMBIOS v4.0 → v5.0

| Aspecto | Versión 4.0 (WDS) | Versión 5.0 (Cable) ✅ |
|---------|-------------------|------------------------|
| **Conexión MK02↔SXT-MG** | wlan1 ~~~WDS RF~~~ | ether1 ──Cable── ether1 |
| **ether1** | Spare/No usado | Trunk to SXT-MG |
| **wlan1** | WDS Hub AP | Disabled (futuro AP local) |
| **Security profile** | wds-link-sxt | (Eliminado) |
| **Throughput** | ~50% (half-duplex RF) | 100% (full-duplex cable) |
| **Complejidad** | WDS config + wireless | Solo bridge L2 |
| **VLAN filtering** | wlan1 tagged | ether1-to-sxt tagged |

---

## 🔌 CABLEADO ACTUALIZADO
```
┌──────────────────────────────────────────────┐
│            MAGDALENA CIUDAD                  │
├──────────────────────────────────────────────┤
│                                              │
│  [Switch TP-LINK Port 2]                     │
│           │                                  │
│           │ Cat5e Q-in-Q                     │
│           ▼                                  │
│    ┌──────────────┐                          │
│    │     MK02     │                          │
│    │              │                          │
│    │ ether2◄──────┘ Q-in-Q from MK01         │
│    │ ether3◄──────  Laptop gestión           │
│    │              │                          │
│    │ ether1───────┐ Trunk to SXT             │
│    └──────────────┼──────────────────        │
│                   │ Cat5e                    │
│                   │ CABLE FÍSICO             │
│              ┌────▼─────────┐                │
│              │   SXT-MG     │                │
│              │              │                │
│              │ ether1◄──────┘ Trunk VLANs    │
│              │              │                │
│              │ wlan1────────► PtP 8km        │
│              └──────────────┘                │
└──────────────────────────────────────────────┘