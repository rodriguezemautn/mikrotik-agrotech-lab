# 🔧 CONFIGURACIONES FALTANTES Y MEJORAS CRÍTICAS
## Red Agrotech - Complemento a la Implementación v5.0

**Fecha:** 28 de Noviembre de 2025  
**Objetivo:** Corregir deficiencias identificadas y agregar funcionalidades faltantes

---

## 📑 ÍNDICE DE CONTENIDO

1. **MK03 - Operación Autónoma (CRÍTICO)**
2. **DHCP Relay como Alternativa**
3. **Netwatch Avanzado para Toda la Topología**
4. **WiFi Virtual para Guest**
5. **QoS y Rate Limiting**
6. **Syslog Centralizado**
7. **Optimizaciones PtP**
8. **Script de Monitoreo Global**

---

## 1️⃣ MK03 - OPERACIÓN AUTÓNOMA (CRÍTICO)

### **Problema:**
Si el enlace PTP (8km) cae, los dispositivos en Campo (MK03, MK04, MK05, MK06) quedan sin servicios de red:
- ❌ Sin DHCP (no pueden obtener IP)
- ❌ Sin DNS (no resuelven nombres)
- ❌ Sin gateway (no acceso a Internet si hay backup)

### **Solución: Failover Automático**

```routeros
# ============================================================================
# MK03 - CONFIGURACIÓN DE OPERACIÓN AUTÓNOMA
# ============================================================================
# Agregar al archivo MK03_agrotech-ca-gw_v5.rsc existente
# ============================================================================

:log info "MK03: Configurando operacion autonoma..."

# ----------------------------------------------------------------------------
# PASO 1: CREAR VLAN INTERFACES PARA DHCP LOCAL
# ----------------------------------------------------------------------------

/interface vlan
add name=vlan10-dhcp interface=BR-CAMPO vlan-id=10 \
    comment="VLAN 10 para DHCP local"
add name=vlan20-dhcp interface=BR-CAMPO vlan-id=20 \
    comment="VLAN 20 para DHCP local"
add name=vlan90-dhcp interface=BR-CAMPO vlan-id=90 \
    comment="VLAN 90 para DHCP local"
add name=vlan96-dhcp interface=BR-CAMPO vlan-id=96 \
    comment="VLAN 96 para DHCP local"
add name=vlan201-dhcp interface=BR-CAMPO vlan-id=201 \
    comment="VLAN 201 para DHCP local"

:log info "MK03: VLANs para DHCP creadas."

# ----------------------------------------------------------------------------
# PASO 2: ASIGNAR IPs COMO GATEWAY LOCAL
# ----------------------------------------------------------------------------

/ip address
add address=192.168.10.254/24 interface=vlan10-dhcp \
    comment="Gateway Local VLAN 10 - Servers"
add address=192.168.20.254/24 interface=vlan20-dhcp \
    comment="Gateway Local VLAN 20 - Desktop"
add address=192.168.90.254/24 interface=vlan90-dhcp \
    comment="Gateway Local VLAN 90 - WiFi Privada"
add address=192.168.96.254/24 interface=vlan96-dhcp \
    comment="Gateway Local VLAN 96 - WiFi Guest"
add address=192.168.201.254/24 interface=vlan201-dhcp \
    comment="Gateway Local VLAN 201 - CCTV"

:log info "MK03: IPs de gateway local asignadas."

# ----------------------------------------------------------------------------
# PASO 3: POOLS DHCP LOCALES
# ----------------------------------------------------------------------------

/ip pool
add name=pool-vlan10-local ranges=192.168.10.100-192.168.10.200 \
    comment="Pool local VLAN 10"
add name=pool-vlan20-local ranges=192.168.20.100-192.168.20.250 \
    comment="Pool local VLAN 20"
add name=pool-vlan90-local ranges=192.168.90.100-192.168.90.250 \
    comment="Pool local VLAN 90"
add name=pool-vlan96-local ranges=192.168.96.100-192.168.96.250 \
    comment="Pool local VLAN 96"
add name=pool-vlan201-local ranges=192.168.201.50-192.168.201.100 \
    comment="Pool local VLAN 201 - CCTV"

:log info "MK03: Pools DHCP locales creados."

# ----------------------------------------------------------------------------
# PASO 4: SERVIDORES DHCP LOCALES (DESHABILITADOS POR DEFECTO)
# ----------------------------------------------------------------------------

/ip dhcp-server
add name=dhcp-vlan10-local \
    interface=vlan10-dhcp \
    address-pool=pool-vlan10-local \
    disabled=yes \
    lease-time=2h \
    comment="DHCP Local VLAN 10 - Activado en failover"

add name=dhcp-vlan20-local \
    interface=vlan20-dhcp \
    address-pool=pool-vlan20-local \
    disabled=yes \
    lease-time=2h \
    comment="DHCP Local VLAN 20 - Activado en failover"

add name=dhcp-vlan90-local \
    interface=vlan90-dhcp \
    address-pool=pool-vlan90-local \
    disabled=yes \
    lease-time=1h \
    comment="DHCP Local VLAN 90 - Activado en failover"

add name=dhcp-vlan96-local \
    interface=vlan96-dhcp \
    address-pool=pool-vlan96-local \
    disabled=yes \
    lease-time=30m \
    comment="DHCP Local VLAN 96 Guest - Activado en failover"

add name=dhcp-vlan201-local \
    interface=vlan201-dhcp \
    address-pool=pool-vlan201-local \
    disabled=yes \
    lease-time=7d \
    comment="DHCP Local VLAN 201 CCTV - Activado en failover"

:log info "MK03: Servidores DHCP locales creados (deshabilitados)."

# ----------------------------------------------------------------------------
# PASO 5: NETWORKS DHCP
# ----------------------------------------------------------------------------

/ip dhcp-server network
add address=192.168.10.0/24 \
    gateway=192.168.10.254 \
    dns-server=8.8.8.8,1.1.1.1 \
    comment="VLAN 10 - Servers"

add address=192.168.20.0/24 \
    gateway=192.168.20.254 \
    dns-server=8.8.8.8,1.1.1.1 \
    comment="VLAN 20 - Desktop"

add address=192.168.90.0/24 \
    gateway=192.168.90.254 \
    dns-server=8.8.8.8,1.1.1.1 \
    comment="VLAN 90 - WiFi Privada"

add address=192.168.96.0/24 \
    gateway=192.168.96.254 \
    dns-server=8.8.8.8,1.1.1.1 \
    comment="VLAN 96 - WiFi Guest"

add address=192.168.201.0/24 \
    gateway=192.168.201.254 \
    dns-server=192.168.201.254 \
    comment="VLAN 201 - CCTV (sin DNS externo)"

:log info "MK03: Networks DHCP configuradas."

# ----------------------------------------------------------------------------
# PASO 6: DNS CACHE LOCAL
# ----------------------------------------------------------------------------

/ip dns
set allow-remote-requests=yes \
    servers=8.8.8.8,1.1.1.1 \
    cache-size=8192KiB \
    cache-max-ttl=1d

:log info "MK03: DNS cache local habilitado."

# ----------------------------------------------------------------------------
# PASO 7: NTP SERVER LOCAL
# ----------------------------------------------------------------------------

/system ntp server
set enabled=yes \
    broadcast=yes \
    manycast=no

:log info "MK03: NTP server local habilitado."

# ----------------------------------------------------------------------------
# PASO 8: NETWATCH PARA FAILOVER AUTOMÁTICO
# ----------------------------------------------------------------------------

/tool netwatch
add host=10.200.1.1 \
    interval=10s \
    timeout=5s \
    comment="Monitor MK01 Gateway" \
    down-script={
        :log warning "======================================"
        :log warning "ENLACE CAIDO - MK01 NO RESPONDE"
        :log warning "ACTIVANDO MODO AUTONOMO"
        :log warning "======================================"
        
        # 1. Activar DHCP Servers locales
        :log info "Activando DHCP servers locales..."
        /ip dhcp-server set [find name=dhcp-vlan10-local] disabled=no
        /ip dhcp-server set [find name=dhcp-vlan20-local] disabled=no
        /ip dhcp-server set [find name=dhcp-vlan90-local] disabled=no
        /ip dhcp-server set [find name=dhcp-vlan96-local] disabled=no
        /ip dhcp-server set [find name=dhcp-vlan201-local] disabled=no
        
        # 2. Cambiar prioridad de rutas (hacer local el default)
        :log info "Modificando rutas por defecto..."
        /ip route set [find comment="Default to MK01"] distance=100
        /ip route set [find comment="Corporate VLANs via MK01"] distance=100
        
        # 3. Opcional: Activar NAT local si hay WAN backup
        # /ip firewall nat set [find comment="Local NAT Backup"] disabled=no
        
        # 4. Cambiar DNS a cache local únicamente
        :log info "Usando DNS cache local..."
        # Los clientes DHCP ya recibirán DNS local (192.168.x.254)
        
        # 5. Enviar alerta por email (si email relay funciona sin MK01)
        # /tool e-mail send to="admin@agrotech.com" \
        #     subject="ALERTA CRITICA: Enlace PTP caido en MK03" \
        #     body="MK03 ha entrado en modo autonomo. MK01 no responde."
        
        :log warning "MODO AUTONOMO ACTIVADO EXITOSAMENTE"
        :log warning "Servicios locales operativos: DHCP, DNS, NTP"
        :log warning "======================================"
    } \
    up-script={
        :log info "======================================"
        :log info "ENLACE RECUPERADO - MK01 RESPONDE"
        :log info "DESACTIVANDO MODO AUTONOMO"
        :log info "======================================"
        
        # 1. Desactivar DHCP Servers locales
        :log info "Desactivando DHCP servers locales..."
        /ip dhcp-server set [find name=dhcp-vlan10-local] disabled=yes
        /ip dhcp-server set [find name=dhcp-vlan20-local] disabled=yes
        /ip dhcp-server set [find name=dhcp-vlan90-local] disabled=yes
        /ip dhcp-server set [find name=dhcp-vlan96-local] disabled=yes
        /ip dhcp-server set [find name=dhcp-vlan201-local] disabled=yes
        
        # 2. Restaurar rutas por defecto a MK01
        :log info "Restaurando rutas por defecto..."
        /ip route set [find comment="Default to MK01"] distance=1
        /ip route set [find comment="Corporate VLANs via MK01"] distance=1
        
        # 3. Desactivar NAT local (si estaba activo)
        # /ip firewall nat set [find comment="Local NAT Backup"] disabled=yes
        
        # 4. Enviar notificación de recuperación
        # /tool e-mail send to="admin@agrotech.com" \
        #     subject="INFO: Enlace PTP recuperado en MK03" \
        #     body="MK03 ha vuelto a modo normal. Conectividad con MK01 restaurada."
        
        :log info "MODO NORMAL RESTAURADO EXITOSAMENTE"
        :log info "======================================"
    }

:log info "MK03: Netwatch failover configurado."

# ----------------------------------------------------------------------------
# PASO 9: SCRIPT DE VERIFICACIÓN DE MODO
# ----------------------------------------------------------------------------

/system script
add name=check-autonomous-mode \
    source={
        :log info "=== AUTONOMOUS MODE CHECK ==="
        :local mk01status [/tool netwatch get [find host=10.200.1.1] status]
        :log info ("MK01 Status: " . $mk01status)
        
        :if ($mk01status = "down") do={
            :log warning "MODO: AUTONOMO (MK01 caido)"
            :log info "DHCP Servers:"
            /ip dhcp-server print where name~"local"
            :log info "Rutas:"
            /ip route print where comment~"MK01"
        } else={
            :log info "MODO: NORMAL (MK01 operativo)"
        }
        :log info "=== END CHECK ==="
    } \
    comment="Verificar modo de operacion actual"

:log info "MK03: Script de verificacion creado."

# ----------------------------------------------------------------------------
# PASO 10: OPCIONAL - WAN BACKUP LOCAL
# ----------------------------------------------------------------------------
# Si MK03 tiene una conexión WAN propia (3G/4G, otro ISP), descomentar:

# /interface ethernet
# set [ find default-name=ether2 ] name=ether2-wan-backup \
#     comment="WAN Backup local (3G/4G modem)"

# /ip address
# add address=<IP_WAN_LOCAL> interface=ether2-wan-backup

# Ruta backup (activada solo en failover)
# /ip route
# add dst-address=0.0.0.0/0 gateway=<GATEWAY_WAN_LOCAL> distance=100 \
#     comment="Local WAN backup - Activado en failover"

# NAT para WAN backup (deshabilitado por defecto)
# /ip firewall nat
# add chain=srcnat out-interface=ether2-wan-backup \
#     action=masquerade \
#     disabled=yes \
#     comment="Local NAT Backup"

# Script adicional en netwatch down-script:
# /ip route set [find comment="Local WAN backup"] distance=10
# /ip firewall nat set [find comment="Local NAT Backup"] disabled=no

:log warning "============================================"
:log warning "MK03 - OPERACION AUTONOMA CONFIGURADA"
:log warning "============================================"
:log warning "MODO NORMAL:"
:log warning "  - DHCP via MK01 (relay o remoto)"
:log warning "  - DNS via MK01"
:log warning "  - Gateway: 10.200.1.1 (MK01)"
:log warning ""
:log warning "MODO AUTONOMO (si cae PTP):"
:log warning "  - DHCP local en MK03"
:log warning "  - DNS cache local"
:log warning "  - NTP local"
:log warning "  - Gateway local (sin Internet si no hay WAN backup)"
:log warning "============================================"
:log warning "VERIFICAR:"
:log warning "  /system script run check-autonomous-mode"
:log warning "  /tool netwatch print"
:log warning "============================================"

# FIN DE CONFIGURACIÓN AUTÓNOMA
```

### **Cómo Probar el Failover:**

```bash
# 1. Verificar modo normal
/system script run check-autonomous-mode
# Debe decir: "MODO: NORMAL"

# 2. Simular caída de enlace
# En MK03, bloquear temporalmente tráfico a MK01:
/ip firewall filter add chain=output dst-address=10.200.1.1 action=drop

# 3. Esperar 10-15 segundos y verificar logs
/log print where message~"AUTONOMO"

# 4. Verificar DHCP activo
/ip dhcp-server print
# dhcp-vlan10-local debe estar enabled=yes

# 5. Verificar rutas
/ip route print
# Ruta a MK01 debe tener distance=100 (inactiva)

# 6. Restaurar conectividad
/ip firewall filter remove [find dst-address=10.200.1.1]

# 7. Esperar 10-15 segundos y verificar logs
/log print where message~"RESTAURADO"

# 8. Verificar modo normal restaurado
/system script run check-autonomous-mode
```

---

## 2️⃣ DHCP RELAY (ALTERNATIVA MÁS SIMPLE)

### **Cuándo Usar DHCP Relay:**
- Cuando NO quieres DHCP servers locales
- Prefieres gestión centralizada en MK01
- No necesitas operación autónoma total

### **Configuración en MK03:**

```routeros
# ============================================================================
# MK03 - DHCP RELAY (ALTERNATIVA A DHCP LOCAL)
# ============================================================================

:log info "MK03: Configurando DHCP Relay..."

# DHCP Relay hacia MK01
/ip dhcp-relay
add name=relay-to-mk01 \
    interface=vlan10-local,vlan20-local,vlan90-local,vlan96-local,vlan201-local \
    dhcp-server=192.168.10.1,192.168.20.1,192.168.90.1,192.168.96.1,192.168.201.1 \
    local-address=10.200.1.20 \
    disabled=no \
    comment="Relay DHCP requests to MK01"

:log info "MK03: DHCP Relay configurado."

# Verificación
/ip dhcp-relay print
```

### **Ventajas del Relay:**
✅ Más simple de configurar  
✅ Gestión centralizada en MK01  
✅ No requiere sincronización de pools

### **Desventajas del Relay:**
❌ NO funciona si cae el enlace PTP  
❌ Dependencia total de MK01  
❌ Latencia adicional en DHCP requests

---

## 3️⃣ NETWATCH AVANZADO - MONITOREO PROACTIVO

### **En MK01 - Monitorear TODOS los Dispositivos:**

```routeros
# ============================================================================
# MK01 - NETWATCH AVANZADO PARA TODA LA TOPOLOGÍA
# ============================================================================

:log info "MK01: Configurando netwatch avanzado..."

# MK02 - Magdalena Hub
/tool netwatch
add host=10.200.1.10 \
    interval=30s \
    timeout=5s \
    comment="MK02 Magdalena Hub" \
    down-script={
        :log error "ALERTA: MK02 (Magdalena Hub) NO RESPONDE"
        /tool e-mail send to="admin@agrotech.com" \
            subject="CRITICO: MK02 Offline" \
            body="Dispositivo MK02 (10.200.1.10) no responde. Verificar Q-in-Q trunk."
    } \
    up-script={
        :log info "INFO: MK02 (Magdalena Hub) RECUPERADO"
    }

# SXT-MG - PtP AP
add host=10.200.1.50 \
    interval=30s \
    timeout=5s \
    comment="SXT-MG PtP AP" \
    down-script={
        :log error "ALERTA: SXT-MG (PtP AP) NO RESPONDE"
        /tool e-mail send to="admin@agrotech.com" \
            subject="CRITICO: SXT-MG Offline" \
            body="Radio SXT-MG (10.200.1.50) no responde. Enlace PtP 8km afectado."
    }

# SXT-CA - PtP Station
add host=10.200.1.51 \
    interval=30s \
    timeout=5s \
    comment="SXT-CA PtP Station" \
    down-script={
        :log error "ALERTA: SXT-CA (PtP Station) NO RESPONDE"
        :log error "IMPACTO: Campo completamente aislado"
        /tool e-mail send to="admin@agrotech.com" \
            subject="CRITICO: SXT-CA Offline - Campo Aislado" \
            body="Radio SXT-CA (10.200.1.51) no responde. Todos los sitios de Campo sin conectividad."
    }

# MK03 - Gateway Campo
add host=10.200.1.20 \
    interval=30s \
    timeout=5s \
    comment="MK03 Gateway Campo" \
    down-script={
        :log error "ALERTA: MK03 (Gateway Campo) NO RESPONDE"
        /tool e-mail send to="admin@agrotech.com" \
            subject="CRITICO: MK03 Offline" \
            body="Gateway MK03 (10.200.1.20) no responde. PTMP y sitios campo afectados."
    }

# MK04 - Station Campo Drones
add host=10.200.1.21 \
    interval=60s \
    timeout=10s \
    comment="MK04 Station Drones" \
    down-script={
        :log warning "ALERTA: MK04 (Centro Drones) NO RESPONDE"
    }

# MK05 - Station Galpón
add host=10.200.1.22 \
    interval=60s \
    timeout=10s \
    comment="MK05 Station Galpon" \
    down-script={
        :log warning "ALERTA: MK05 (Galpon) NO RESPONDE"
    }

# MK06 - Station AP Extra
add host=10.200.1.25 \
    interval=60s \
    timeout=10s \
    comment="MK06 Station AP Extra" \
    down-script={
        :log warning "ALERTA: MK06 (AP Extra) NO RESPONDE"
    }

:log info "MK01: Netwatch avanzado configurado para 7 dispositivos."

# Script de resumen de netwatch
/system script
add name=netwatch-status \
    source={
        :log info "=== NETWATCH STATUS REPORT ==="
        :local devicesDown 0
        :foreach i in=[/tool netwatch find] do={
            :local host [/tool netwatch get $i host]
            :local status [/tool netwatch get $i status]
            :local comment [/tool netwatch get $i comment]
            :if ($status = "down") do={
                :log error ("✗ " . $comment . " (" . $host . ") - DOWN")
                :set devicesDown ($devicesDown + 1)
            } else={
                :log info ("✓ " . $comment . " (" . $host . ") - UP")
            }
        }
        :if ($devicesDown = 0) do={
            :log info "ESTADO: Todos los dispositivos operativos ✓"
        } else={
            :log error ("ESTADO: " . $devicesDown . " dispositivos caidos ✗")
        }
        :log info "=== END REPORT ==="
    }

# Ejecutar cada hora
/system scheduler
add name=hourly-netwatch-report \
    interval=1h \
    start-time=00:00:00 \
    on-event="/system script run netwatch-status"

:log info "MK01: Scripts de netwatch creados."
```

---

## 4️⃣ WIFI VIRTUAL PARA GUEST (MEJORA SEGURIDAD)

### **Crear SSID Virtual en MK04, MK05, MK06:**

```routeros
# ============================================================================
# MK04/MK05/MK06 - WiFi VIRTUAL para Guest
# ============================================================================

:log info "Configurando WiFi virtual para Guest..."

# Crear interfaz virtual wireless
/interface wireless
add name=wlan-guest \
    master-interface=wlan1 \
    ssid="Agrotech-Guest" \
    security-profile=agrotech-guest \
    default-forwarding=no \
    wds-mode=disabled \
    comment="Guest WiFi Virtual - VLAN 96"

:log info "WiFi virtual creado."

# Agregar al bridge con PVID 96
/interface bridge port
add bridge=BR-CAMPO interface=wlan-guest \
    pvid=96 \
    frame-types=admit-only-untagged-and-priority-tagged \
    ingress-filtering=yes \
    comment="Guest WiFi Virtual - VLAN 96 Untagged"

# Client isolation (los clientes guest no se ven entre sí)
/interface wireless access-list
add interface=wlan-guest \
    forwarding=no \
    comment="Aislar clientes Guest entre si"

:log info "Client isolation configurado."

# VLAN filtering actualizado
/interface bridge vlan
set [find bridge=BR-CAMPO vlan-ids=96] \
    untagged=wlan-guest

:log info "VLAN filtering actualizado para Guest virtual."
```

### **Ventajas del WiFi Virtual:**
✅ Aislamiento físico de SSIDs  
✅ Mejor seguridad (Guest no ve red corporativa)  
✅ Client isolation entre invitados  
✅ No impacta performance del SSID corporativo

---

## 5️⃣ QoS Y RATE LIMITING

### **Priorizar Tráfico Crítico:**

```routeros
# ============================================================================
# MK01 - QoS AVANZADO Y RATE LIMITING
# ============================================================================

:log info "MK01: Configurando QoS..."

# ----------------------------------------------------------------------------
# PASO 1: PACKET MARKING (Marcar paquetes por tipo)
# ----------------------------------------------------------------------------

/ip firewall mangle
# Management (máxima prioridad)
add chain=prerouting \
    src-address=10.200.1.0/24 \
    action=mark-packet \
    new-packet-mark=mgmt-traffic \
    passthrough=no \
    comment="01-QoS: Management traffic"

# CCTV (alta prioridad)
add chain=prerouting \
    src-address=192.168.201.0/24 \
    action=mark-packet \
    new-packet-mark=cctv-traffic \
    passthrough=no \
    comment="02-QoS: CCTV traffic"

# VoIP (alta prioridad) - Ejemplo
add chain=prerouting \
    protocol=udp \
    dst-port=5060-5090 \
    action=mark-packet \
    new-packet-mark=voip-traffic \
    passthrough=no \
    comment="03-QoS: VoIP traffic"

# Corporate (prioridad media)
add chain=prerouting \
    src-address=192.168.10.0/24,192.168.20.0/24,192.168.90.0/24 \
    action=mark-packet \
    new-packet-mark=corporate-traffic \
    passthrough=no \
    comment="04-QoS: Corporate traffic"

# Guest (baja prioridad)
add chain=prerouting \
    src-address=192.168.96.0/24 \
    action=mark-packet \
    new-packet-mark=guest-traffic \
    passthrough=no \
    comment="05-QoS: Guest traffic (low priority)"

:log info "MK01: Packet marking configurado."

# ----------------------------------------------------------------------------
# PASO 2: QUEUE TREE (Árbol de colas por prioridad)
# ----------------------------------------------------------------------------

/queue tree
# Cola padre (global)
add name=qos-global parent=global

# Management - Prioridad 1 (máxima)
add name=qos-mgmt \
    parent=qos-global \
    packet-mark=mgmt-traffic \
    priority=1 \
    limit-at=2M \
    max-limit=20M \
    comment="Management - Highest Priority"

# CCTV - Prioridad 2
add name=qos-cctv \
    parent=qos-global \
    packet-mark=cctv-traffic \
    priority=2 \
    limit-at=10M \
    max-limit=50M \
    comment="CCTV - High Priority"

# VoIP - Prioridad 2
add name=qos-voip \
    parent=qos-global \
    packet-mark=voip-traffic \
    priority=2 \
    limit-at=1M \
    max-limit=5M \
    comment="VoIP - High Priority"

# Corporate - Prioridad 4 (normal)
add name=qos-corporate \
    parent=qos-global \
    packet-mark=corporate-traffic \
    priority=4 \
    max-limit=100M \
    comment="Corporate - Normal Priority"

# Guest - Prioridad 8 (baja)
add name=qos-guest \
    parent=qos-global \
    packet-mark=guest-traffic \
    priority=8 \
    max-limit=30M \
    comment="Guest - Low Priority"

:log info "MK01: Queue tree configurado."

# ----------------------------------------------------------------------------
# PASO 3: RATE LIMITING POR CLIENTE (SIMPLE QUEUE)
# ----------------------------------------------------------------------------

# Limitar ancho de banda individual para Guest
/queue simple
add name=guest-per-client \
    target=192.168.96.0/24 \
    max-limit=5M/5M \
    burst-limit=8M/8M \
    burst-threshold=4M/4M \
    burst-time=10s/10s \
    comment="Limit per guest client to 5 Mbps"

# Limitar CCTV para evitar saturación
add name=cctv-total-limit \
    target=192.168.201.0/24 \
    max-limit=40M/40M \
    priority=2 \
    comment="Total CCTV bandwidth limit"

:log info "MK01: Rate limiting configurado."

# ----------------------------------------------------------------------------
# PASO 4: PCQ (Per Connection Queuing) - Distribución justa
# ----------------------------------------------------------------------------

/queue type
add name=pcq-download \
    kind=pcq \
    pcq-rate=0 \
    pcq-limit=50 \
    pcq-classifier=dst-address \
    comment="PCQ for fair download distribution"

add name=pcq-upload \
    kind=pcq \
    pcq-rate=0 \
    pcq-limit=50 \
    pcq-classifier=src-address \
    comment="PCQ for fair upload distribution"

# Aplicar PCQ a colas
/queue tree
add name=pcq-corporate-down \
    parent=qos-corporate \
    queue=pcq-download \
    comment="Fair distribution for corporate downloads"

add name=pcq-corporate-up \
    parent=qos-corporate \
    queue=pcq-upload \
    comment="Fair distribution for corporate uploads"

:log info "MK01: PCQ configurado."

:log warning "============================================"
:log warning "MK01 - QoS Y RATE LIMITING CONFIGURADO"
:log warning "============================================"
:log warning "PRIORIDADES:"
:log warning "  1. Management (10.200.1.0/24)"
:log warning "  2. CCTV (192.168.201.0/24)"
:log warning "  2. VoIP (UDP 5060-5090)"
:log warning "  4. Corporate (VLANs 10,20,90)"
:log warning "  8. Guest (VLAN 96) - Máx 5 Mbps/cliente"
:log warning "============================================"
:log warning "VERIFICAR:"
:log warning "  /queue tree print"
:log warning "  /queue simple print"
:log warning "  /ip firewall mangle print"
:log warning "============================================"
```

---

## 6️⃣ SYSLOG CENTRALIZADO

### **En MK01 - Recibir Logs de Todos los Dispositivos:**

```routeros
# ============================================================================
# MK01 - SYSLOG SERVER CENTRALIZADO
# ============================================================================

:log info "MK01: Configurando syslog centralizado..."

# Habilitar puerto 514 para syslog (UDP)
/ip firewall filter
add chain=input \
    protocol=udp \
    dst-port=514 \
    src-address=10.200.1.0/24 \
    action=accept \
    place-before=0 \
    comment="Allow syslog from management network"

# Configurar logging action remote
/system logging action
add name=remote-syslog-server \
    target=remote \
    remote=10.200.1.1 \
    src-address=10.200.1.1 \
    bsd-syslog=yes

# Log local para verificar recepción
/system logging
add topics=info,warning,error,critical \
    action=memory \
    prefix="SYSLOG-SERVER"

:log info "MK01: Syslog server configurado en puerto 514/UDP."
```

### **En MK02-MK06 - Enviar Logs a MK01:**

```routeros
# ============================================================================
# MK02-MK06 - SYSLOG CLIENT
# ============================================================================

:log info "Configurando syslog client..."

# Logging action hacia MK01
/system logging action
add name=remote-syslog \
    target=remote \
    remote=10.200.1.1 \
    src-address=10.200.1.<ID> \  # Usar IP propia (10, 20, 50, 51, 21, 22, 25)
    bsd-syslog=yes

# Enviar logs importantes a syslog
/system logging
add topics=error,critical,warning \
    action=remote-syslog \
    prefix="<DEVICE-NAME>"

add topics=wireless,dhcp \
    action=remote-syslog \
    prefix="<DEVICE-NAME>"

:log info "Syslog client configurado. Logs enviados a 10.200.1.1"
```

### **Verificar Logs Centralizados:**

```routeros
# En MK01
/log print where topics~"remote"
# Debería ver logs de MK02, MK03, SXTs, MK04-06
```

---

## 7️⃣ OPTIMIZACIONES PtP (8km 2.4GHz)

### **Ajustes Finos para Maximizar Performance:**

```routeros
# ============================================================================
# SXT-MG y SXT-CA - OPTIMIZACIONES PtP
# ============================================================================

:log info "Aplicando optimizaciones PtP..."

# En SXT-MG (AP)
/interface wireless
set wlan1 \
    tx-power-mode=all-rates-fixed \
    tx-power=20 \  # Ajustar según signal survey
    default-forwarding=no \
    hide-ssid=yes \
    compression=yes \
    wmm-support=enabled

# Escaneo mínimo (canal fijo)
set wlan1 scan-list=2437

# TX/RX chains optimization (SXT tiene 2x2 MIMO)
/interface wireless set wlan1 \
    tx-chains=0,1 \
    rx-chains=0,1

# NV2 timing adjustments
/interface wireless nv2 set wlan1 \
    tdma-period-size=2 \
    qos=frame-priority \
    security=enabled

:log info "Optimizaciones PtP aplicadas."

# Scheduler para survey de interferencias (cada noche)
/system scheduler
add name=nightly-rf-scan \
    interval=1d \
    start-time=03:00:00 \
    on-event={
        /interface wireless scan wlan1 duration=30
        :log info "RF Scan completed - Review /interface wireless scan"
    }
```

---

## 8️⃣ SCRIPT DE MONITOREO GLOBAL

### **Dashboard de Estado Completo:**

```routeros
# ============================================================================
# MK01 - SCRIPT DE MONITOREO GLOBAL
# ============================================================================

/system script
add name=full-topology-status \
    source={
        :log info "========================================"
        :log info "AGROTECH NETWORK - STATUS DASHBOARD"
        :log info "========================================"
        :log info ""
        
        # 1. Dispositivos en red
        :log info "1. DISPOSITIVOS ONLINE:"
        :local devices {"10.200.1.10";"10.200.1.50";"10.200.1.51";"10.200.1.20";"10.200.1.21";"10.200.1.22";"10.200.1.25"}
        :local names {"MK02-Magdalena";"SXT-MG-PtP-AP";"SXT-CA-PtP-ST";"MK03-Campo";"MK04-Drones";"MK05-Galpon";"MK06-Extra"}
        :local i 0
        :local onlineCount 0
        :foreach dev in=$devices do={
            :local name [:pick $names $i]
            :if ([/ping $dev count=2] > 0) do={
                :log info ("   ✓ " . $name . " (" . $dev . ")")
                :set onlineCount ($onlineCount + 1)
            } else={
                :log error ("   ✗ " . $name . " (" . $dev . ") - OFFLINE!")
            }
            :set i ($i + 1)
        }
        :log info ("   Total: " . $onlineCount . "/7 online")
        :log info ""
        
        # 2. Q-in-Q Status
        :log info "2. Q-IN-Q ENCAPSULATION:"
        :local qinqOk [:len [/interface find name~"qinq-vlan"]]
        :log info ("   VLANs encapsuladas: " . $qinqOk . "/5")
        :log info ""
        
        # 3. DHCP Leases
        :log info "3. DHCP ACTIVE LEASES:"
        :local dhcpVlan10 [:len [/ip dhcp-server lease find where server=dhcp-vlan10 active-address~"192.168.10."]]
        :local dhcpVlan20 [:len [/ip dhcp-server lease find where server=dhcp-vlan20 active-address~"192.168.20."]]
        :local dhcpVlan90 [:len [/ip dhcp-server lease find where server=dhcp-vlan90 active-address~"192.168.90."]]
        :local dhcpVlan96 [:len [/ip dhcp-server lease find where server=dhcp-vlan96 active-address~"192.168.96."]]
        :log info ("   VLAN 10 (Servers): " . $dhcpVlan10 . " leases")
        :log info ("   VLAN 20 (Desktop): " . $dhcpVlan20 . " leases")
        :log info ("   VLAN 90 (WiFi):    " . $dhcpVlan90 . " leases")
        :log info ("   VLAN 96 (Guest):   " . $dhcpVlan96 . " leases")
        :log info ""
        
        # 4. Firewall stats
        :log info "4. FIREWALL STATISTICS:"
        :local fwDrop [:len [/ip firewall filter find where action=drop]]
        :local fwLog [:len [/log find where message~"DROP-"]]
        :log info ("   Drop rules: " . $fwDrop)
        :log info ("   Dropped packets (log): " . $fwLog)
        :log info ""
        
        # 5. Uptime
        :log info "5. SYSTEM UPTIME:"
        :local uptime [/system resource get uptime]
        :log info ("   MK01 Uptime: " . $uptime)
        :log info ""
        
        :log info "========================================"
        :log info "END OF DASHBOARD"
        :log info "========================================"
    } \
    comment="Dashboard completo del estado de la red"

# Ejecutar manualmente o programar cada hora
/system scheduler
add name=hourly-dashboard \
    interval=1h \
    start-time=00:00:00 \
    on-event="/system script run full-topology-status"
```

---

## 🎯 RESUMEN DE CONFIGURACIONES FALTANTES

| Config | Prioridad | Dónde | Tiempo Est. |
|--------|-----------|-------|-------------|
| **Operación Autónoma MK03** | 🔴 CRÍTICA | MK03 | 30 min |
| **Netwatch Avanzado** | 🟡 ALTA | MK01 | 15 min |
| **QoS y Rate Limiting** | 🟡 ALTA | MK01 | 20 min |
| **WiFi Virtual Guest** | 🟢 MEDIA | MK04-06 | 10 min |
| **Syslog Centralizado** | 🟢 MEDIA | MK01 + Todos | 15 min |
| **Optimizaciones PtP** | 🟢 BAJA | SXT-MG/CA | 10 min |
| **Script Monitoreo Global** | 🟢 BAJA | MK01 | 5 min |

**TOTAL: ~2 horas de configuración adicional**

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

```
□ Operación Autónoma MK03 implementada
  □ VLANs DHCP creadas
  □ IPs gateway local asignadas
  □ DHCP servers locales configurados (disabled)
  □ Netwatch failover probado
  
□ Netwatch Avanzado en MK01
  □ Monitores para 7 dispositivos
  □ Email alerts configurados
  □ Script de status creado
  
□ QoS Configurado
  □ Packet marking por tipo de tráfico
  □ Queue tree con prioridades
  □ Rate limiting para Guest
  
□ WiFi Virtual Guest
  □ Interfaces virtuales creadas
  □ Client isolation activo
  □ Pruebas de aislamiento realizadas
  
□ Syslog Centralizado
  □ MK01 recibiendo logs
  □ Clientes enviando logs
  □ Logs verificados
  
□ Optimizaciones PtP
  □ TX power ajustado
  □ Scan list optimizado
  □ NV2 timing configurado
  
□ Scripts de Monitoreo
  □ Dashboard global creado
  □ Scheduler configurado
  □ Pruebas realizadas
```

---

## 📞 SOPORTE POST-IMPLEMENTACIÓN

### **Comandos Útiles para Troubleshooting:**

```routeros
# Verificar operación autónoma
/system script run check-autonomous-mode

# Ver status de todos los dispositivos
/system script run full-topology-status

# Verificar netwatch
/tool netwatch print detail

# Ver DHCP activo
/ip dhcp-server lease print where status=bound

# Estadísticas de QoS
/queue tree print stats

# Logs recientes
/log print where time>now-1h

# Test de bandwidth
/tool bandwidth-test 10.200.1.20 protocol=tcp duration=30s
```

---

**Documento generado:** 28/Nov/2025  
**Versión:** 1.0  
**Estado:** Listo para implementación
