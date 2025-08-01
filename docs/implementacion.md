# Laboratorio Indoor: Radioenlaces y Transporte de VLANs
## Implementación Académica con MikroTik RB951ui-2HnD

### Información del Proyecto
**Objetivo:** Validar transporte de VLANs sobre radioenlaces WDS en ambiente controlado  
**Equipos:** 6x MikroTik RB951ui-2HnD  
**Modalidad:** Laboratório académico indoor  
**Duración estimada:** 3-4 horas  

---

## **Fase 1: Planificación y Setup Físico**

### **1.1 Inventario de Equipos**

| ID | Hostname | Función | Ubicación Simulada | IP Gestión |
|----|----------|---------|-------------------|------------|
| MK01 | agrotech-lp-gw | Gateway Principal | La Plata | 10.200.1.1 |
| MK02 | agrotech-mg-ap | AP WDS Magdalena | Magdalena | 10.200.1.10 |
| MK03 | agrotech-ca-gw | Station WDS + AP | Campo A | 10.200.1.20 |
| MK04 | agrotech-cb-st | Station WDS | Campo B | 10.200.1.21 |
| MK05 | agrotech-cc-st | Station WDS | Campo C | 10.200.1.22 |
| MK06 | agrotech-ap-extra | AP Adicional | Campo A Interior | 10.200.1.25 |

### **1.2 Layout Físico del Laboratorio**

```
Mesa 1: [MK01-Gateway] ←→ Cable → [Switch] ← WiFi → [MK02-AP_WDS]
                                    ↓
Mesa 2:              [MK03-Station_WDS] ← WiFi → [MK02]
                              ↓
Mesa 3:     [MK04-Station_B] ← WiFi → [MK03] → WiFi → [MK05-Station_C]
                              ↓
Mesa 4:              [MK06-AP_Extra]
```

**Distancias físicas sugeridas:**
- **MK02 ↔ MK03:** 5-8 metros (simula enlace 8km)
- **MK03 ↔ MK04:** 3-4 metros (simula enlace 2km)
- **MK03 ↔ MK05:** 3-4 metros (simula enlace 1.5km)
- **MK03 ↔ MK06:** 2-3 metros (AP local)

### **1.3 Materiales Adicionales Necesarios**

**Esenciales:**
- [ ] 6x Fuentes de poder 24V 0.8A (incluidas con equipos)
- [ ] 6x Cables Ethernet Cat5e/6 (1-2 metros c/u)
- [ ] 1x Switch no gestionado 8 puertos (para simulación)
- [ ] 1x Laptop/PC para configuración y monitoreo
- [ ] 6x Etiquetas para identificación de equipos

**Opcionales para mayor realismo:**
- [ ] Atenuadores RF variables (10-30dB)
- [ ] Cables UTP cortos
- [ ] Analizador de espectro WiFi (software)
- [ ] Cronómetro para mediciones de latencia

---

## **Fase 2: Configuración Base de Equipos**

### **2.1 Preparación Inicial (Todos los Equipos)**

**Paso 1: Reset a configuración de fábrica**
```bash
# Conectar por WinBox o Web (192.168.88.1)
/system reset-configuration no-defaults=yes keep-users=yes
```

**Paso 2: Configuración básica común**
```bash
# Timezone y NTP
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org

# Usuario administrador
/user add name=laboratorio group=full password="Lab2024!"

# Configuración SNMP
/snmp set enabled=yes contact="laboratorio@universidad.edu" 
```

### **2.2 Configuración por Equipo**

#### **MK01: Gateway La Plata (agrotech-lp-gw)**
```bash
/system identity set name=agrotech-lp-gw

# Crear bridge VLAN-aware
/interface bridge add name=BR-MAIN vlan-filtering=yes

# Crear VLANs corporativas
/interface vlan
add interface=ether2 name=VLAN10-Servidores vlan-id=10
add interface=ether2 name=VLAN20-Escritorio vlan-id=20
add interface=ether2 name=VLAN90-WiFi-Priv vlan-id=90
add interface=ether2 name=VLAN96-WiFi-Guest vlan-id=96
add interface=ether2 name=VLAN201-CCTV vlan-id=201

# Asignar al bridge
/interface bridge port
add bridge=BR-MAIN interface=ether2
add bridge=BR-MAIN interface=VLAN10-Servidores
add bridge=BR-MAIN interface=VLAN20-Escritorio
add bridge=BR-MAIN interface=VLAN90-WiFi-Priv
add bridge=BR-MAIN interface=VLAN96-WiFi-Guest
add bridge=BR-MAIN interface=VLAN201-CCTV

# IPs y DHCP centralizado
/ip address
add address=192.168.10.1/24 interface=VLAN10-Servidores
add address=192.168.20.1/24 interface=VLAN20-Escritorio
add address=192.168.90.1/24 interface=VLAN90-WiFi-Priv
add address=192.168.96.1/24 interface=VLAN96-WiFi-Guest
add address=192.168.201.1/24 interface=VLAN201-CCTV
add address=10.200.1.1/24 interface=ether3 comment="Gestion"

# DHCP Servers centralizados
/ip pool
add name=POOL-20 ranges=192.168.20.10-192.168.20.100
add name=POOL-90 ranges=192.168.90.10-192.168.90.100
add name=POOL-96 ranges=192.168.96.10-192.168.96.100

/ip dhcp-server
add name=DHCP-20 interface=VLAN20-Escritorio address-pool=POOL-20 disabled=no
add name=DHCP-90 interface=VLAN90-WiFi-Priv address-pool=POOL-90 disabled=no
add name=DHCP-96 interface=VLAN96-WiFi-Guest address-pool=POOL-96 disabled=no

/ip dhcp-server network
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=8.8.8.8
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=8.8.8.8
```

#### **MK02: AP WDS Magdalena (agrotech-mg-ap)**
```bash
/system identity set name=agrotech-mg-ap

# Perfil de seguridad WDS
/interface wireless security-profiles
add name=WDS-Profile mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm \
    wpa2-pre-shared-key="LabWDS2024!"

# Configurar wireless como AP WDS
/interface wireless
set wlan1 band=2ghz-b/g/n channel-width=20mhz frequency=2437 \
    mode=ap-bridge ssid="AGROTECH-BACKBONE" \
    security-profile=WDS-Profile wds-mode=dynamic \
    wds-default-bridge=BR-WDS tx-power=10

# Bridge WDS
/interface bridge add name=BR-WDS vlan-filtering=yes

/interface bridge port
add bridge=BR-WDS interface=wlan1
add bridge=BR-WDS interface=ether2

# VLAN filtering para transporte
/interface bridge vlan
add bridge=BR-WDS tagged=wlan1,ether2 vlan-ids=10,20,90,96,201

# IP gestión
/ip address add address=10.200.1.10/24 interface=ether3
```

#### **MK03: Station WDS Campo A (agrotech-ca-gw)**
```bash
/system identity set name=agrotech-ca-gw

# Configurar como Station WDS
/interface wireless
set wlan1 mode=station-wds ssid="AGROTECH-BACKBONE" \
    frequency=2437 security-profile=WDS-Profile \
    wds-mode=dynamic wds-default-bridge=BR-CAMPO tx-power=10

# Bridge principal
/interface bridge add name=BR-CAMPO vlan-filtering=yes

# VLANs locales
/interface vlan
add interface=BR-CAMPO name=VLAN10-Local vlan-id=10
add interface=BR-CAMPO name=VLAN20-Local vlan-id=20
add interface=BR-CAMPO name=VLAN90-Local vlan-id=90
add interface=BR-CAMPO name=VLAN96-Local vlan-id=96
add interface=BR-CAMPO name=VLAN201-Local vlan-id=201

/interface bridge port
add bridge=BR-CAMPO interface=wlan1
add bridge=BR-CAMPO interface=ether2
add bridge=BR-CAMPO interface=VLAN10-Local
add bridge=BR-CAMPO interface=VLAN20-Local
add bridge=BR-CAMPO interface=VLAN90-Local
add bridge=BR-CAMPO interface=VLAN96-Local
add bridge=BR-CAMPO interface=VLAN201-Local

# Enlaces secundarios a B y C
/interface wireless
add master-interface=wlan1 name=wlan-to-B ssid="LINK-CAMPO-B" \
    frequency=2462 tx-power=5 wds-mode=dynamic
add master-interface=wlan1 name=wlan-to-C ssid="LINK-CAMPO-C" \
    frequency=2412 tx-power=5 wds-mode=dynamic

/interface bridge port
add bridge=BR-CAMPO interface=wlan-to-B
add bridge=BR-CAMPO interface=wlan-to-C

# IP gestión
/ip address add address=10.200.1.20/24 interface=ether3
```

#### **MK04: Station WDS Campo B (agrotech-cb-st)**
```bash
/system identity set name=agrotech-cb-st

# Station WDS a Campo A
/interface wireless
set wlan1 mode=station-wds ssid="LINK-CAMPO-B" \
    frequency=2462 wds-mode=dynamic wds-default-bridge=BR-CAMPO-B tx-power=5

/interface bridge add name=BR-CAMPO-B vlan-filtering=yes

/interface bridge port
add bridge=BR-CAMPO-B interface=wlan1
add bridge=BR-CAMPO-B interface=ether2

# VLANs locales necesarias
/interface vlan
add interface=BR-CAMPO-B name=VLAN20-B vlan-id=20
add interface=BR-CAMPO-B name=VLAN90-B vlan-id=90
add interface=BR-CAMPO-B name=VLAN201-B vlan-id=201

/interface bridge port
add bridge=BR-CAMPO-B interface=VLAN20-B
add bridge=BR-CAMPO-B interface=VLAN90-B
add bridge=BR-CAMPO-B interface=VLAN201-B

/ip address add address=10.200.1.21/24 interface=ether3
```

#### **MK05: Station WDS Campo C (agrotech-cc-st)**
```bash
/system identity set name=agrotech-cc-st

# Similar a MK04 pero conectando a LINK-CAMPO-C
/interface wireless
set wlan1 mode=station-wds ssid="LINK-CAMPO-C" \
    frequency=2412 wds-mode=dynamic wds-default-bridge=BR-CAMPO-C tx-power=5

# Resto de configuración similar a MK04
/ip address add address=10.200.1.22/24 interface=ether3
```

#### **MK06: AP Adicional Campo A (agrotech-ap-extra)**
```bash
/system identity set name=agrotech-ap-extra

# AP local para WiFi
/interface wireless
set wlan1 mode=ap-bridge ssid="AgroTech-Lab" frequency=2452 \
    security-profile=default-profile tx-power=5

/interface bridge add name=BR-LOCAL

/interface bridge port
add bridge=BR-LOCAL interface=wlan1
add bridge=BR-LOCAL interface=ether2

/ip address add address=10.200.1.25/24 interface=ether3
```

---

## **Fase 3: Metodología de Pruebas**

### **3.1 Lista de Verificación de Conectividad**

**Prueba 1: Conectividad WDS Básica**
```bash
# Desde MK03 verificar conexión a MK02
/tool ping address=10.200.1.10 count=10

# Verificar tabla de registro WDS
/interface wireless registration-table print

# Verificar bridge MAC table
/interface bridge mac-table print
```

**Prueba 2: Transporte de VLANs**
```bash
# Conectar cliente en VLAN 20 en Campo A
# Verificar obtención de IP desde La Plata
# Comprobar conectividad extremo a extremo
```

**Prueba 3: Aislamiento de VLANs**
```bash
# Verificar que VLAN 96 no accede a VLANs internas
# Comprobar firewalls entre VLANs
```

### **3.2 Métricas a Medir**

#### **3.2.1 Métricas de Radioenlace**

**Herramientas de medición:**
```bash
# Signal strength y quality
/interface wireless monitor wlan1 duration=60

# Throughput test
/tool bandwidth-test address=10.200.1.10 protocol=tcp duration=60

# Latency test  
/tool ping address=10.200.1.10 count=100 size=64
/tool ping address=10.200.1.10 count=100 size=1500
```

**Tabla de registro de métricas:**

| Métrica | Enlace MK02-MK03 | Enlace MK03-MK04 | Enlace MK03-MK05 |
|---------|------------------|------------------|------------------|
| RSSI (dBm) | | | |
| Noise Floor (dBm) | | | |
| SNR (dB) | | | |
| TX Rate (Mbps) | | | |
| RX Rate (Mbps) | | | |
| Throughput TCP (Mbps) | | | |
| Throughput UDP (Mbps) | | | |
| Latency mín (ms) | | | |
| Latency avg (ms) | | | |
| Latency máx (ms) | | | |
| Jitter (ms) | | | |
| Packet Loss (%) | | | |

#### **3.2.2 Métricas de VLANs**

**Pruebas por VLAN:**

| VLAN | Función | DHCP Test | Ping Test | Bandwidth Test | Aislamiento |
|------|---------|-----------|-----------|----------------|-------------|
| 10 | Servidores | ✓/✗ | ✓/✗ | __ Mbps | ✓/✗ |
| 20 | Escritorio | ✓/✗ | ✓/✗ | __ Mbps | ✓/✗ |
| 90 | WiFi Priv | ✓/✗ | ✓/✗ | __ Mbps | ✓/✗ |
| 96 | WiFi Guest | ✓/✗ | ✓/✗ | __ Mbps | ✓/✗ |
| 201 | CCTV | ✓/✗ | ✓/✗ | __ Mbps | ✓/✗ |

### **3.3 Scripts de Automatización de Pruebas**

#### **Script de Monitoreo Continuo**
```bash
# Crear en MK01 (Gateway)
/system script add name=lab-monitor source={
:put "=== LABORATORIO AGROTECH - MONITOR ==="
:put ("Timestamp: " . [/system clock get date] . " " . [/system clock get time])

# Test conectividad a cada sitio
:local sites {{10.200.1.10;"Magdalena"} {10.200.1.20;"Campo A"} {10.200.1.21;"Campo B"} {10.200.1.22;"Campo C"}}

foreach site in=$sites do={
    :local ip ($site->0)
    :local name ($site->1)
    :local result [/tool ping address=$ip count=3]
    :put ("$name ($ip): $result/3 pings successful")
}

# Verificar DHCP leases activos
:local leases [/ip dhcp-server lease print count-only where active=yes]
:put ("DHCP Leases activos: $leases")

:put "=================================="
}

# Programar ejecución cada 5 minutos
/system scheduler add interval=5m name=lab-monitoring on-event=lab-monitor
```

#### **Script de Pruebas de Performance**
```bash
/system script add name=performance-test source={
:put "=== PRUEBAS DE PERFORMANCE ==="

# Bandwidth test a cada enlace
:local targets {10.200.1.10;10.200.1.20;10.200.1.21;10.200.1.22}

foreach target in=$targets do={
    :put ("Testing bandwidth to $target...")
    /tool bandwidth-test address=$target protocol=tcp duration=10 direction=both
    :delay 2s
}

:put "Performance test completed"
}
```

---

## **Fase 4: Documentación y Análisis**

### **4.1 Plantilla de Informe de Laboratorio**

```markdown
# INFORME DE LABORATORIO
## Radioenlaces y Transporte de VLANs con MikroTik

### Datos del Experimento
- **Fecha:** [DD/MM/YYYY]
- **Duración:** [X horas]
- **Participantes:** [Nombres]
- **Equipos utilizados:** 6x RB951ui-2HnD

### Objetivos Cumplidos
- [ ] Establecimiento de enlaces WDS
- [ ] Transporte transparente de VLANs
- [ ] DHCP centralizado funcional
- [ ] Aislamiento entre VLANs
- [ ] Métricas de performance documentadas

### Resultados Obtenidos

#### Conectividad WDS
[Insertar tabla de métricas de radioenlace]

#### Performance de VLANs
[Insertar tabla de throughput por VLAN]

#### Problemas Encontrados
1. [Descripción del problema]
   - Causa identificada: [...]
   - Solución aplicada: [...]
   - Resultado: [...]

### Conclusiones
[Análisis de resultados y lecciones aprendidas]

### Recomendaciones
[Mejoras para futuras implementaciones]
```

### **4.2 Métricas de Éxito**

**Criterios de Aprobación del Laboratorio:**

| Criterio | Meta | Resultado | ✓/✗ |
|----------|------|-----------|-----|
| Enlaces WDS estables | >95% uptime | ___% | |
| Throughput mínimo | >20 Mbps por enlace | ___ Mbps | |
| Latencia máxima | <10ms indoor | ___ ms | |
| DHCP success rate | >98% | ___% | |
| VLAN isolation | 100% efectivo | ___% | |
| Packet loss | <1% | ___% | |

---

## **Fase 5: Troubleshooting y Optimización**

### **5.1 Problemas Comunes Indoor**

**Problema 1: Interferencia entre equipos**
- **Síntoma:** Throughput bajo, desconexiones
- **Solución:** Separar físicamente, ajustar potencias
- **Comando:** `/interface wireless set wlan1 tx-power=5`

**Problema 2: WDS no conecta**
- **Síntoma:** No aparece en registration-table
- **Solución:** Verificar SSID, security-profile, frequency
- **Debug:** `/interface wireless scan 0 duration=10`

**Problema 3: VLANs no transportan**
- **Síntoma:** No obtiene DHCP remoto
- **Solución:** Verificar VLAN filtering, bridge configuration
- **Debug:** `/interface bridge vlan print`

### **5.2 Optimizaciones**

**Para mejor performance indoor:**
```bash
# Reducir potencia para evitar interferencia
/interface wireless set wlan1 tx-power=5

# Habilitar frame aggregation
/interface wireless set wlan1 frame-lifetime=0

# Optimizar channel width
/interface wireless set wlan1 channel-width=20mhz
```

---

## **Cronograma Sugerido (4 Semanas)**

### **Semana 1: Setup y Configuración Básica**
- **Hora 1-2:** Preparación física y reset de equipos
- **Hora 3-4:** Configuración MK01 (Gateway) y MK02 (AP WDS)
- **Hora 5:** Primer enlace WDS MK02-MK03

### **Semana 2: Expansión de Enlaces**
- **Hora 1-2:** Configuración MK04 y MK05 (Stations WDS)
- **Hora 3-4:** Enlaces secundarios MK03-MK04, MK03-MK05
- **Hora 5:** Configuración MK06 (AP adicional)

### **Semana 3: VLANs y Servicios**
- **Hora 1-2:** Implementación completa de VLANs
- **Hora 3-4:** DHCP centralizado y pruebas
- **Hora 5:** Firewall y aislamiento de VLANs

### **Semana 4: Pruebas y Documentación**
- **Hora 1-2:** Mediciones de performance completas
- **Hora 3-4:** Troubleshooting y optimización
- **Hora 5:** Documentación final y presentación

---

## **Entregables del Laboratorio**

1. **Configuraciones CLI completas** de los 6 equipos
2. **Tabla de métricas** con todos los valores medidos
3. **Informe técnico** con análisis de resultados
4. **Video demostración** del funcionamiento (opcional)
5. **Presentación** de lecciones aprendidas
6. **Recomendaciones** para implementación real

