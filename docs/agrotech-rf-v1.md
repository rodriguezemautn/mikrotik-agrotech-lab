# Laboratorio de Radioenlaces para Empresa Agrotech
## Implementación de Infraestructura de Red Distribuida con MikroTik RB951ui-2HnD

### Autores
**Laboratorio de Ingeniería de Redes y Telecomunicaciones**  
*Especialización en Radioenlaces y Protocolos de Seguridad*

---

## Resumen Ejecutivo

Este documento presenta el diseño, implementación y configuración de una infraestructura de red distribuida para una empresa agrotech de producción ganadera, utilizando radioenlaces MikroTik RB951ui-2HnD. La solución integra oficinas en La Plata y Magdalena mediante ISPs mayorista y minorista, con extensión por radioenlace propio al establecimiento de producción rural.

**Palabras clave:** Radioenlaces, MikroTik, VLAN, Seguridad de redes, Agrotech, ISP, Última milla

---

## 1. Marco Teórico

### 1.1 Radioenlaces en Redes Empresariales

Los radioenlaces constituyen una tecnología fundamental para la conectividad en entornos rurales y empresariales distribuidos. Operan mediante la transmisión de señales electromagnéticas en espectros radioeléctricos específicos, permitiendo la comunicación de datos sin infraestructura física cableada.

### 1.2 Tecnología MikroTik RouterBoard

La familia RouterBoard de MikroTik ofrece soluciones integradas de routing y comunicaciones inalámbricas. El modelo RB951ui-2HnD presenta características específicas para implementaciones de radioenlace:

**Especificaciones Técnicas Relevantes:**
- Procesador: AR9344 600MHz MIPSBE
- Memoria: 128MB RAM / 128MB NAND Storage
- Conectividad inalámbrica: 2.4GHz 802.11b/g/n, 300Mbps
- Puertos Ethernet: 5x 10/100Mbps
- Capacidades PoE: Entrada y salida pasiva
- Rango operativo: -20°C a +60°C

### 1.3 Protocolos de Seguridad en Radioenlaces

#### 1.3.1 WPA2/WPA3 Enterprise
Implementación de autenticación robusta mediante servidores RADIUS y certificados digitales.

#### 1.3.2 IPSec
Establecimiento de túneles seguros a nivel de capa de red para proteger el tráfico entre sitios.

#### 1.3.3 EAP-TLS
Protocolo de autenticación basado en certificados digitales para máxima seguridad.

### 1.4 Virtualización de Redes (VLANs)

Las redes virtuales permiten la segmentación lógica del tráfico, proporcionando aislamiento y gestión granular de servicios. La implementación de VLAN tagging (802.1Q) facilita el transporte de múltiples redes lógicas sobre una infraestructura física compartida.

---

## 2. Contexto del Proyecto

### 2.1 Empresa Agrotech

Empresa dedicada a la **producción ganadera sostenible** con enfoque en **pastoreo natural (grass feed) y crianza intensiva (feedlot)**. Incorpora **drones y análisis con inteligencia artificial** para monitoreo de rebaños, pastos y salud animal.

**Sector:** Producción ganadera con tecnología de precisión  
**Ubicaciones:**
- **Oficinas Centrales:** La Plata, Buenos Aires
- **Oficinas Regionales:** Magdalena (50km desde La Plata)
- **Establecimiento de Producción:** Campo rural (8km desde Magdalena)
  - **A: Casa principal** (administración, red principal).
  - **B: Centro de datos y operaciones con drones.**
  - **C: Galpón con corrales (feedlot y pastoreo).**

### 2.2 Infraestructura de Campo

**Ubicación A - Casa Principal:**
- Centro de operaciones y administración local
- Punto de interconexión principal
- Servidor local y equipamiento IT

**Ubicación B - Centro de Recolección de Datos:**
- Estación de procesamiento de datos de drones
- Sistemas de inteligencia artificial
- Almacenamiento y análisis de información

**Ubicación C - Galpón y Corrales:**
- Sistemas de monitoreo de ganado
- Videovigilancia
- Sensores IoT para feedlot y pastoreo

---

## 3. Situación Problemática Detallada

### 3.1 Desafíos de Conectividad

La empresa agrotech enfrenta múltiples desafíos de conectividad que afectan su operación integrada:

#### 3.1.1 Distancias Geográficas
- **La Plata ↔ Magdalena:** 50km requiere solución ISP
- **Magdalena ↔ Campo:** 8km sin infraestructura de fibra óptica
- **Distribución interna del campo:** Múltiples ubicaciones dispersas

#### 3.1.2 Segmentación de Servicios
La operación requiere cinco redes lógicas independientes:
- **VLAN 10:** Servidores y aplicaciones críticas
- **VLAN 20:** Estaciones de trabajo administrativas
- **VLAN 90:** Acceso WiFi para personal autorizado
- **VLAN 96:** WiFi para invitados y terceros
- **VLAN 201:** Sistemas de videovigilancia

#### 3.1.3 Interoperabilidad ISP
- **ISP Mayorista (Fiber Corp):** Conectividad troncal La Plata-Magdalena
- **ISP Minorista (Cooperativa WISP):** Última milla en Magdalena
- **Requerimiento:** Transparencia de VLANs entre proveedores

#### 3.1.4 Condiciones Ambientales
- Entorno rural con variaciones climáticas extremas
- Interferencias electromagnéticas potenciales
- Requisitos de disponibilidad 24/7

### 3.2 Requerimientos Técnicos

#### 3.2.1 Ancho de Banda
- **Oficina La Plata:** 100Mbps simétrico mínimo
- **Oficina Magdalena:** 50Mbps simétrico mínimo
- **Campo - Ubicación A:** 20Mbps simétrico mínimo
- **Campo - Ubicaciones B y C:** 10Mbps simétrico cada una

#### 3.2.2 Latencia
- **La Plata ↔ Campo:** <50ms máximo
- **Aplicaciones críticas:** <20ms entre ubicaciones del campo

#### 3.2.3 Disponibilidad
- **SLA objetivo:** 99.5% uptime mensual
- **Tiempo máximo de recuperación:** 4 horas

---

## 4. Protocolos de Seguridad para Radioenlaces

### 4.1 Arquitectura de Seguridad por Capas

#### 4.1.1 Capa Física
- **Potencia de transmisión controlada:** Minimización de la huella electromagnética
- **Antenas direccionales:** Reducción de interceptación por terceros
- **Encriptación a nivel de radio:** WPA2-Enterprise mínimo

#### 4.1.2 Capa de Enlace
- **802.1X:** Autenticación de puerto para dispositivos conectados
- **MAC Address Filtering:** Control de acceso basado en direcciones físicas
- **VLAN Isolation:** Segmentación de tráfico por función

#### 4.1.3 Capa de Red
- **IPSec Tunnels:** Encriptación extremo a extremo
- **Firewall Rules:** Control granular de tráfico
- **NAT Traversal:** Soporte para comunicaciones through NAT

### 4.2 Implementación de WPA2-Enterprise

```
# Configuración de autenticación empresarial
/interface wireless security-profiles
add name="agrotech-secure" mode=dynamic-keys authentication-types=wpa2-eap \
    eap-methods=eap-tls radius-mac-authentication=yes \
    radius-mac-mode=as-username-and-password
```

### 4.3 Configuración IPSec

#### 4.3.1 Políticas de Encriptación
- **Algoritmo de encriptación:** AES-256
- **Hash:** SHA-256
- **Intercambio de claves:** DH Group 14+
- **Perfect Forward Secrecy:** Habilitado

#### 4.3.2 Gestión de Certificados
- **CA Interna:** Autoridad certificadora de la empresa
- **Renovación automática:** Período de 1 año
- **Revocación:** Lista CRL actualizada semanalmente

---

## 5. Desarrollo de Ingeniería de Red

### 5.1 Topología General

```
[La Plata HQ] ←→ [ISP Mayorista] ←→ [ISP Minorista] ←→ [Magdalena] ←→ [Campo A] ←→ [Campo B]
                                                                              ↓
                                                                          [Campo C]
```

### 5.2 Esquema de Direccionamiento IP

#### 5.2.1 Red Principal de Interconexión
- **Segmento ISP:** 192.168.100.0/24
- **Radioenlace Campo:** 192.168.101.0/30

#### 5.2.2 VLANs por Ubicación

**La Plata (Oficina Central):**
- VLAN 10: 10.1.10.0/24 (Servidores)
- VLAN 20: 10.1.20.0/24 (Escritorio)
- VLAN 90: 10.1.90.0/24 (WiFi Privada)
- VLAN 96: 10.1.96.0/24 (WiFi Invitados)
- VLAN 201: 10.1.201.0/24 (Videovigilancia)

**Magdalena (Oficina Regional):**
- VLAN 10: 10.2.10.0/24 (Servidores)
- VLAN 20: 10.2.20.0/24 (Escritorio)
- VLAN 90: 10.2.90.0/24 (WiFi Privada)
- VLAN 96: 10.2.96.0/24 (WiFi Invitados)
- VLAN 201: 10.2.201.0/24 (Videovigilancia)

**Campo - Ubicación A:**
- VLAN 10: 10.3.10.0/24 (Servidores)
- VLAN 20: 10.3.20.0/24 (Escritorio)
- VLAN 90: 10.3.90.0/24 (WiFi Privada)
- VLAN 96: 10.3.96.0/24 (WiFi Invitados)
- VLAN 201: 10.3.201.0/24 (Videovigilancia)

**Campo - Ubicación B:**
- VLAN 10: 10.4.10.0/24 (Servidores)
- VLAN 20: 10.4.20.0/24 (Escritorio)
- VLAN 90: 10.4.90.0/24 (WiFi Privada)
- VLAN 201: 10.4.201.0/24 (Videovigilancia)

**Campo - Ubicación C:**
- VLAN 20: 10.5.20.0/24 (Escritorio)
- VLAN 90: 10.5.90.0/24 (WiFi Privada)
- VLAN 201: 10.5.201.0/24 (Videovigilancia)

### 5.3 Inventario de Equipos

#### 5.3.1 Identificación de Dispositivos

| Ubicación | Dispositivo | Función | IP Gestión | Hostname |
|-----------|-------------|---------|------------|----------|
| La Plata | RB951-LP-01 | Router Principal | 192.168.100.10 | agrotech-lp-gw |
| Magdalena | RB951-MG-01 | Router Regional | 192.168.100.20 | agrotech-mg-gw |
| Campo A | RB951-CA-01 | Gateway Campo | 192.168.101.1 | agrotech-ca-gw |
| Campo A | RB951-CA-02 | AP Indoor | 10.3.90.1 | agrotech-ca-ap |
| Campo B | RB951-CB-01 | Estación Remota | 192.168.101.5 | agrotech-cb-st |
| Campo C | RB951-CC-01 | Estación Remota | 192.168.101.9 | agrotech-cc-st |

### 5.4 Configuración de Radioenlaces

#### 5.4.1 Enlace Magdalena ↔ Campo A (8km)

**Parámetros de RF:**
- Frecuencia: 2.4GHz (Canal 6 - 2437MHz)
- Potencia de transmisión: 20dBm
- Modo: Station Bridge
- Protocolo: 802.11n
- Ancho de canal: 20MHz

**Cálculo de Enlace:**
- Distancia: 8km
- Pérdida de espacio libre: ~106dB
- Ganancia de antenas: 2.5dBi x 2 = 5dB
- Margen de desvanecimiento: 15dB
- RSSI esperado: -90dBm (aceptable)

#### 5.4.2 Enlace Campo A ↔ Campo B (2km)

**Parámetros de RF:**
- Frecuencia: 2.4GHz (Canal 11 - 2462MHz)
- Potencia de transmisión: 15dBm
- Modo: Station Bridge
- Protocolo: 802.11n

#### 5.4.3 Enlace Campo A ↔ Campo C (1.5km)

**Parámetros de RF:**
- Frecuencia: 2.4GHz (Canal 1 - 2412MHz)
- Potencia de transmisión: 15dBm
- Modo: Station Bridge
- Protocolo: 802.11n

---

## 6. Diagrama de Red Profesional

![alt text](image.png)

### 6.1 Topología Física

```
                    EMPRESA AGROTECH - INFRAESTRUCTURA DE RED
    
    [OFICINA LA PLATA]                [OFICINA MAGDALENA]                [CAMPO DE PRODUCCIÓN]
    ┌─────────────────┐              ┌──────────────────┐               ┌─────────────────────┐
    │   Data Center   │              │  Oficina Reg.    │               │     Casa Ppal.      │
    │                 │              │                  │               │       (A)           │
    │ RB951-LP-01     │◄────────────►│ RB951-MG-01      │◄─────────────►│ RB951-CA-01         │
    │ (Gateway)       │   ISP Link   │ (Regional GW)    │  8km Radio    │ (Campo Gateway)     │
    │                 │   50km       │                  │   Link        │                     │
    │ VLAN 10,20,90,  │              │ VLAN 10,20,90,   │               │ VLAN 10,20,90,      │
    │      96,201     │              │      96,201      │               │      96,201         │
    │                 │              │                  │               │                     │
    │ 192.168.100.10  │              │ 192.168.100.20   │               │ 192.168.101.1       │
    └─────────────────┘              └──────────────────┘               └─────────┬───────────┘
                                                                                   │
                   ┌─────────────────────────────────────────────────────────────┼────────────┐
                   │                                                             │            │
                   ▼                                                             ▼            ▼
        ┌──────────────────┐                                           ┌─────────────┐ ┌─────────────┐
        │Centro Datos (B)  │                                           │ Galpón (C)  │ │ AP Indoor   │
        │                  │                                           │             │ │             │
        │ RB951-CB-01      │                                           │RB951-CC-01  │ │RB951-CA-02  │
        │ (Data Station)   │                                           │(Ganado St.) │ │(WiFi AP)    │
        │                  │                                           │             │ │             │
        │ VLAN 10,20,90,201│                                           │VLAN 20,90,  │ │VLAN 90,96   │
        │                  │                                           │     201     │ │             │
        │ 192.168.101.5    │                                           │192.168.101.9│ │10.3.90.1    │
        └──────────────────┘                                           └─────────────┘ └─────────────┘
             2km Radio                                                       1.5km Radio
```

### 6.2 Esquema Lógico de VLANs

```
                        SEGMENTACIÓN DE VLANS POR UBICACIÓN
    
    VLAN 10 (Servidores)     ┌──────────────────────────────────────────────┐
    [10.1.10.0/24] ←────────→│             BACKBONE ISP                     │←────────→ [10.2.10.0/24]
    [10.3.10.0/24] ←────────→│          + RADIOENLACES                      │←────────→ [10.4.10.0/24]
                             │                                              │           [10.5.10.0/24]
    VLAN 20 (Escritorio)     │                                              │
    [10.1.20.0/24] ←────────→│    Transporte Transparente de VLANs          │←────────→ [10.2.20.0/24]
    [10.3.20.0/24] ←────────→│         mediante 802.1Q Tagging             │←────────→ [10.4.20.0/24]
                             │                                              │           [10.5.20.0/24]
    VLAN 90 (WiFi Priv)      │                                              │
    [10.1.90.0/24] ←────────→│                                              │←────────→ [10.2.90.0/24]
    [10.3.90.0/24] ←────────→│                                              │←────────→ [10.4.90.0/24]
                             │                                              │           [10.5.90.0/24]
    VLAN 96 (WiFi Guest)     │                                              │
    [10.1.96.0/24] ←────────→│                                              │←────────→ [10.2.96.0/24]
    [10.3.96.0/24] ←────────→│                                              │
                             │                                              │
    VLAN 201 (VideoVig)      │                                              │
    [10.1.201.0/24] ←───────→│                                              │←────────→ [10.2.201.0/24]
    [10.3.201.0/24] ←───────→│                                              │←────────→ [10.4.201.0/24]
                             │                                              │           [10.5.201.0/24]
                             └──────────────────────────────────────────────┘
         LA PLATA                        TRANSPORTE                            MAGDALENA
                                                                                 CAMPO
```

---

## 7. Configuración de Dispositivos

### 7.1 RB951-LP-01 (Gateway La Plata)

**Función:** Router principal de oficina central con conexión a ISP mayorista.

**Configuración Base:**
- **Hostname:** agrotech-lp-gw
- **IP de gestión:** 192.168.100.10/24
- **Función principal:** Gateway, DHCP Server, Firewall

**Interfaces:**
- **ether1:** Conexión WAN ISP (DHCP Client)
- **ether2-5:** LAN Switch con VLANs
- **wlan1:** Backup wireless (deshabilitado por defecto)

**VLANs Configuradas:**
- **VLAN 10:** Servidores (10.1.10.0/24)
- **VLAN 20:** Escritorio (10.1.20.0/24)
- **VLAN 90:** WiFi Privada (10.1.90.0/24)
- **VLAN 96:** WiFi Invitados (10.1.96.0/24)
- **VLAN 201:** Videovigilancia (10.1.201.0/24)

### 7.2 RB951-MG-01 (Gateway Magdalena)

**Función:** Router regional con conexión a ISP minorista y enlace de campo.

**Configuración Base:**
- **Hostname:** agrotech-mg-gw
- **IP de gestión:** 192.168.100.20/24
- **Función principal:** Gateway regional, Bridge VLAN

**Interfaces:**
- **ether1:** Conexión ISP minorista
- **ether2-4:** LAN local
- **ether5:** Conexión PoE a antena externa
- **wlan1:** Radioenlace a campo (AP Bridge)

### 7.3 RB951-CA-01 (Gateway Campo A)

**Función:** Gateway principal del campo con distribución a ubicaciones B y C.

**Configuración Base:**
- **Hostname:** agrotech-ca-gw
- **IP de gestión:** 192.168.101.1/30
- **Función principal:** Router de campo, DHCP local, Bridge

**Radioenlaces:**
- **wlan1:** Enlace principal con Magdalena (Station Bridge)
- **Enlaces secundarios:** Distribución interna a B y C

### 7.4 RB951-CB-01 (Estación Campo B)

**Función:** Estación de trabajo para centro de datos de drones.

**Configuración Base:**
- **Hostname:** agrotech-cb-st
- **IP de gestión:** 192.168.101.5/30
- **Función principal:** Station Bridge, Switch local

### 7.5 RB951-CC-01 (Estación Campo C)

**Función:** Estación de trabajo para galpón y corrales.

**Configuración Base:**
- **Hostname:** agrotech-cc-st
- **IP de gestión:** 192.168.101.9/30
- **Función principal:** Station Bridge, Switch local

### 7.6 RB951-CA-02 (Access Point Interior)

**Función:** Punto de acceso WiFi para casa principal.

**Configuración Base:**
- **Hostname:** agrotech-ca-ap
- **IP de gestión:** 10.3.90.1/24
- **Función principal:** Access Point dual-band

---

## 8. Herramientas, Protocolos y Metodología

### 8.1 Herramientas de Configuración

#### 8.1.1 WinBox
- **Función:** Interfaz gráfica principal para configuración
- **Versión recomendada:** 3.40+
- **Uso:** Configuración inicial y monitoreo

#### 8.1.2 RouterOS CLI
- **Función:** Configuración por línea de comandos
- **Acceso:** SSH, Telnet, Serial
- **Uso:** Automatización y scripting

#### 8.1.3 Web Interface
- **Función:** Interfaz web para monitoreo básico
- **Puerto:** 80/443
- **Uso:** Visualización de estado

### 8.2 Protocolos Implementados

#### 8.2.1 Capa de Enlace
- **802.11n:** Comunicación inalámbrica
- **802.1Q:** VLAN Tagging
- **802.1X:** Autenticación de puerto

#### 8.2.2 Capa de Red
- **OSPF:** Protocolo de routing dinámico
- **DHCP:** Asignación automática de IPs
- **DNS:** Resolución de nombres

#### 8.2.3 Capa de Transporte
- **TCP/UDP:** Protocolos de transporte
- **IPSec:** Túneles seguros

#### 8.2.4 Capa de Aplicación
- **SNMP:** Monitoreo de red
- **NTP:** Sincronización de tiempo
- **Syslog:** Registro de eventos

### 8.3 Metodología de Implementación

#### 8.3.1 Fase 1: Planificación
1. **Análisis de requerimientos**
2. **Diseño de topología**
3. **Cálculo de radioenlaces**
4. **Planificación de direccionamiento**

#### 8.3.2 Fase 2: Configuración Base
1. **Actualización de RouterOS**
2. **Configuración de interfaces**
3. **Implementación de VLANs**
4. **Configuración de DHCP**

#### 8.3.3 Fase 3: Radioenlaces
1. **Configuración de parámetros RF**
2. **Alineación de antenas**
3. **Optimización de señal**
4. **Pruebas de throughput**

#### 8.3.4 Fase 4: Seguridad
1. **Implementación de firewall**
2. **Configuración de VPN**
3. **Autenticación de usuarios**
4. **Monitoreo de seguridad**

#### 8.3.5 Fase 5: Monitoreo
1. **Configuración SNMP**
2. **Alertas automatizadas**
3. **Dashboards de monitoreo**
4. **Respaldo de configuraciones**

---

## 9. Anexos

### Anexo A: Configuraciones CLI Completas

#### A.1 RB951-LP-01 (Gateway La Plata)

```routeros
# Configuración inicial del sistema
/system identity
set name=agrotech-lp-gw

# Configuración de interfaces VLAN
/interface vlan
add interface=ether2 name=vlan10-servers vlan-id=10
add interface=ether2 name=vlan20-desktop vlan-id=20
add interface=ether2 name=vlan90-wifi-private vlan-id=90
add interface=ether2 name=vlan96-wifi-guest vlan-id=96
add interface=ether2 name=vlan201-cctv vlan-id=201

# Configuración de bridge
/interface bridge
add name=bridge-local

/interface bridge port
add bridge=bridge-local interface=ether3
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=ether5
add bridge=bridge-local interface=vlan10-servers
add bridge=bridge-local interface=vlan20-desktop
add bridge=bridge-local interface=vlan90-wifi-private
add bridge=bridge-local interface=vlan96-wifi-guest
add bridge=bridge-local interface=vlan201-cctv

# Configuración de direcciones IP
/ip address
add address=192.168.100.10/24 interface=ether1 comment="WAN ISP"
add address=10.1.10.1/24 interface=vlan10-servers comment="Servidores"
add address=10.1.20.1/24 interface=vlan20-desktop comment="Escritorio"
add address=10.1.90.1/24 interface=vlan90-wifi-private comment="WiFi Privada"
add address=10.1.96.1/24 interface=vlan96-wifi-guest comment="WiFi Invitados"
add address=10.1.201.1/24 interface=vlan201-cctv comment="CCTV"

# Configuración de DHCP Server
/ip pool
add name=pool-vlan20 ranges=10.1.20.10-10.1.20.200
add name=pool-vlan90 ranges=10.1.90.10-10.1.90.200
add name=pool-vlan96 ranges=10.1.96.10-10.1.96.200

/ip dhcp-server
add address-pool=pool-vlan20 disabled=no interface=vlan20-desktop name=dhcp-vlan20
add address-pool=pool-vlan90 disabled=no interface=vlan90-wifi-private name=dhcp-vlan90
add address-pool=pool-vlan96 disabled=no interface=vlan96-wifi-guest name=dhcp-vlan96

/ip dhcp-server network
add address=10.1.20.0/24 dns-server=10.1.10.5 gateway=10.1.20.1
add address=10.1.90.0/24 dns-server=10.1.10.5 gateway=10.1.90.1
add address=10.1.96.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=10.1.96.1

# Configuración de rutas estáticas
/ip route
add dst-address=10.2.0.0/16 gateway=192.168.100.20 comment="Magdalena Networks"
add dst-address=10.3.0.0/16 gateway=192.168.100.20 comment="Campo Networks"
add dst-address=10.4.0.0/16 gateway=192.168.100.20 comment="Campo B Networks"
add dst-address=10.5.0.0/16 gateway=192.168.100.20 comment="Campo C Networks"

# Configuración de firewall
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.0.0.0/8
add action=accept chain=input protocol=icmp
add action=accept chain=input dst-port=22,80,443,8291 protocol=tcp src-address=10.1.10.0/24
add action=drop chain=input

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward src-address=10.1.10.0/24
add action=accept chain=forward src-address=10.1.20.0/24 dst-address=10.0.0.0/8
add action=accept chain=forward src-address=10.1.90.0/24 dst-address=10.0.0.0/8
add action=drop chain=forward src-address=10.1.96.0/24 dst-address=10.0.0.0/8
add action=accept chain=forward

# NAT para salida a internet
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1

# Configuración de DNS
/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

# Configuración de NTP
/system ntp client
set enabled=yes primary-ntp=pool.ntp.org secondary-ntp=time.google.com

# Configuración de SNMP
/snmp
set enabled=yes contact="admin@agrotech.com" location="La Plata HQ"

# Configuración de usuarios
/user
add name=admin-agrotech group=full password="Agr0t3ch2024!" comment="Admin principal"
add name=soporte-red group=read password="S0p0rt3R3d!" comment="Soporte técnico"
```

#### A.2 RB951-MG-01 (Gateway Magdalena)

```routeros
# Configuración inicial del sistema
/system identity
set name=agrotech-mg-gw

# Configuración de interfaces VLAN
/interface vlan
add interface=ether2 name=vlan10-servers vlan-id=10
add interface=ether2 name=vlan20-desktop vlan-id=20
add interface=ether2 name=vlan90-wifi-private vlan-id=90
add interface=ether2 name=vlan96-wifi-guest vlan-id=96
add interface=ether2 name=vlan201-cctv vlan-id=201

# Configuración de wireless para radioenlace
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz country=argentina \
    disabled=no frequency=2437 mode=ap-bridge ssid=agrotech-campo-link \
    wireless-protocol=802.11 wps-mode=disabled

# Configuración de seguridad wireless
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys \
    wpa2-pre-shared-key="Agr0t3chC4mp0Link2024!"

# Configuración de bridge
/interface bridge
add name=bridge-local

/interface bridge port
add bridge=bridge-local interface=ether3
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=wlan1
add bridge=bridge-local interface=vlan10-servers
add bridge=bridge-local interface=vlan20-desktop
add bridge=bridge-local interface=vlan90-wifi-private
add bridge=bridge-local interface=vlan96-wifi-guest
add bridge=bridge-local interface=vlan201-cctv

# Configuración de direcciones IP
/ip address
add address=192.168.100.20/24 interface=ether1 comment="ISP Connection"
add address=10.2.10.1/24 interface=vlan10-servers comment="Servidores"
add address=10.2.20.1/24 interface=vlan20-desktop comment="Escritorio"
add address=10.2.90.1/24 interface=vlan90-wifi-private comment="WiFi Privada"
add address=10.2.96.1/24 interface=vlan96-wifi-guest comment="WiFi Invitados"
add address=10.2.201.1/24 interface=vlan201-cctv comment="CCTV"

# Configuración de DHCP Server
/ip pool
add name=pool-vlan20-mg ranges=10.2.20.10-10.2.20.200
add name=pool-vlan90-mg ranges=10.2.90.10-10.2.90.200
add name=pool-vlan96-mg ranges=10.2.96.10-10.2.96.200

/ip dhcp-server
add address-pool=pool-vlan20-mg disabled=no interface=vlan20-desktop name=dhcp-vlan20-mg
add address-pool=pool-vlan90-mg disabled=no interface=vlan90-wifi-private name=dhcp-vlan90-mg
add address-pool=pool-vlan96-mg disabled=no interface=vlan96-wifi-guest name=dhcp-vlan96-mg

/ip dhcp-server network
add address=10.2.20.0/24 dns-server=10.1.10.5 gateway=10.2.20.1
add address=10.2.90.0/24 dns-server=10.1.10.5 gateway=10.2.90.1
add address=10.2.96.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=10.2.96.1

# Configuración de rutas estáticas
/ip route
add dst-address=10.1.0.0/16 gateway=192.168.100.10 comment="La Plata Networks"
add dst-address=10.3.0.0/16 gateway=192.168.101.1 comment="Campo A Networks"
add dst-address=10.4.0.0/16 gateway=192.168.101.1 comment="Campo B Networks"
add dst-address=10.5.0.0/16 gateway=192.168.101.1 comment="Campo C Networks"

# Configuración de firewall (similar a La Plata con adaptaciones)
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.0.0.0/8
add action=accept chain=input protocol=icmp
add action=accept chain=input dst-port=22,80,443,8291 protocol=tcp src-address=10.2.10.0/24
add action=drop chain=input

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward

# Configuración de NTP
/system ntp client
set enabled=yes primary-ntp=10.1.10.5 secondary-ntp=pool.ntp.org

# Configuración de SNMP
/snmp
set enabled=yes contact="admin@agrotech.com" location="Magdalena Regional"
```

#### A.3 RB951-CA-01 (Gateway Campo A)

```routeros
# Configuración inicial del sistema
/system identity
set name=agrotech-ca-gw

# Configuración de wireless para enlace principal
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz country=argentina \
    disabled=no frequency=2437 mode=station-bridge wireless-protocol=802.11 \
    wps-mode=disabled

# Configuración de seguridad wireless
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys \
    wpa2-pre-shared-key="Agr0t3chC4mp0Link2024!"

# Conectar a AP de Magdalena
/interface wireless
set [ find default-name=wlan1 ] ssid=agrotech-campo-link

# Configuración de interfaces VLAN
/interface vlan
add interface=ether2 name=vlan10-servers vlan-id=10
add interface=ether2 name=vlan20-desktop vlan-id=20
add interface=ether2 name=vlan90-wifi-private vlan-id=90
add interface=ether2 name=vlan96-wifi-guest vlan-id=96
add interface=ether2 name=vlan201-cctv vlan-id=201

# Configuración de bridge
/interface bridge
add name=bridge-main

/interface bridge port
add bridge=bridge-main interface=wlan1
add bridge=bridge-main interface=ether3
add bridge=bridge-main interface=ether4
add bridge=bridge-main interface=vlan10-servers
add bridge=bridge-main interface=vlan20-desktop
add bridge=bridge-main interface=vlan90-wifi-private
add bridge=bridge-main interface=vlan96-wifi-guest
add bridge=bridge-main interface=vlan201-cctv

# Configuración de direcciones IP
/ip address
add address=192.168.101.1/30 interface=bridge-main comment="Campo Gateway"
add address=10.3.10.1/24 interface=vlan10-servers comment="Servidores"
add address=10.3.20.1/24 interface=vlan20-desktop comment="Escritorio"
add address=10.3.90.1/24 interface=vlan90-wifi-private comment="WiFi Privada"
add address=10.3.96.1/24 interface=vlan96-wifi-guest comment="WiFi Invitados"
add address=10.3.201.1/24 interface=vlan201-cctv comment="CCTV"

# Configuración para enlaces secundarios
/interface wireless
add disabled=no master-interface=wlan1 multicast-buffering=disabled name=wlan-campo-b \
    ssid=agrotech-campo-b wds-cost-range=0 wds-default-cost=0 wps-mode=disabled

add disabled=no master-interface=wlan1 multicast-buffering=disabled name=wlan-campo-c \
    ssid=agrotech-campo-c wds-cost-range=0 wds-default-cost=0 wps-mode=disabled

# Configuración de DHCP Server
/ip pool
add name=pool-vlan20-ca ranges=10.3.20.10-10.3.20.200
add name=pool-vlan90-ca ranges=10.3.90.10-10.3.90.200
add name=pool-vlan96-ca ranges=10.3.96.10-10.3.96.200

/ip dhcp-server
add address-pool=pool-vlan20-ca disabled=no interface=vlan20-desktop name=dhcp-vlan20-ca
add address-pool=pool-vlan90-ca disabled=no interface=vlan90-wifi-private name=dhcp-vlan90-ca
add address-pool=pool-vlan96-ca disabled=no interface=vlan96-wifi-guest name=dhcp-vlan96-ca

/ip dhcp-server network
add address=10.3.20.0/24 dns-server=10.1.10.5 gateway=10.3.20.1
add address=10.3.90.0/24 dns-server=10.1.10.5 gateway=10.3.90.1
add address=10.3.96.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=10.3.96.1

# Configuración de rutas
/ip route
add dst-address=0.0.0.0/0 gateway=192.168.100.20 comment="Default via Magdalena"
add dst-address=10.4.0.0/16 gateway=192.168.101.5 comment="Campo B"
add dst-address=10.5.0.0/16 gateway=192.168.101.9 comment="Campo C"

# Configuración de firewall
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.0.0.0/8
add action=accept chain=input protocol=icmp
add action=accept chain=input dst-port=22,80,443,8291 protocol=tcp src-address=10.3.10.0/24
add action=drop chain=input

add action=accept chain=forward

# Configuración de NTP
/system ntp client
set enabled=yes primary-ntp=10.1.10.5

# Configuración de SNMP
/snmp
set enabled=yes contact="admin@agrotech.com" location="Campo A - Casa Principal"
```

#### A.4 RB951-CB-01 (Estación Campo B)

```routeros
# Configuración inicial del sistema
/system identity
set name=agrotech-cb-st

# Configuración de wireless en modo station
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz country=argentina \
    disabled=no frequency=2462 mode=station-bridge ssid=agrotech-campo-b \
    wireless-protocol=802.11 wps-mode=disabled

# Configuración de seguridad wireless
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys \
    wpa2-pre-shared-key="Agr0t3chC4mp0Link2024!"

# Configuración de interfaces VLAN
/interface vlan
add interface=ether2 name=vlan10-servers vlan-id=10
add interface=ether2 name=vlan20-desktop vlan-id=20
add interface=ether2 name=vlan90-wifi-private vlan-id=90
add interface=ether2 name=vlan201-cctv vlan-id=201

# Configuración de bridge
/interface bridge
add name=bridge-campo-b

/interface bridge port
add bridge=bridge-campo-b interface=wlan1
add bridge=bridge-campo-b interface=ether3
add bridge=bridge-campo-b interface=ether4
add bridge=bridge-campo-b interface=ether5
add bridge=bridge-campo-b interface=vlan10-servers
add bridge=bridge-campo-b interface=vlan20-desktop
add bridge=bridge-campo-b interface=vlan90-wifi-private
add bridge=bridge-campo-b interface=vlan201-cctv

# Configuración de direcciones IP
/ip address
add address=192.168.101.5/30 interface=bridge-campo-b comment="Campo B Station"
add address=10.4.10.1/24 interface=vlan10-servers comment="Servidores B"
add address=10.4.20.1/24 interface=vlan20-desktop comment="Escritorio B"
add address=10.4.90.1/24 interface=vlan90-wifi-private comment="WiFi Privada B"
add address=10.4.201.1/24 interface=vlan201-cctv comment="CCTV B"

# Configuración de DHCP Server local
/ip pool
add name=pool-vlan20-cb ranges=10.4.20.10-10.4.20.50
add name=pool-vlan90-cb ranges=10.4.90.10-10.4.90.50

/ip dhcp-server
add address-pool=pool-vlan20-cb disabled=no interface=vlan20-desktop name=dhcp-vlan20-cb
add address-pool=pool-vlan90-cb disabled=no interface=vlan90-wifi-private name=dhcp-vlan90-cb

/ip dhcp-server network
add address=10.4.20.0/24 dns-server=10.1.10.5 gateway=10.4.20.1
add address=10.4.90.0/24 dns-server=10.1.10.5 gateway=10.4.90.1

# Configuración de ruta por defecto
/ip route
add dst-address=0.0.0.0/0 gateway=192.168.101.1 comment="Default via Campo A"

# Configuración básica de firewall
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.0.0.0/8
add action=accept chain=input protocol=icmp
add action=drop chain=input

add action=accept chain=forward

# Configuración de NTP
/system ntp client
set enabled=yes primary-ntp=10.1.10.5

# Configuración de SNMP
/snmp
set enabled=yes contact="admin@agrotech.com" location="Campo B - Centro Datos"
```

#### A.5 RB951-CC-01 (Estación Campo C)

```routeros
# Configuración inicial del sistema
/system identity
set name=agrotech-cc-st

# Configuración de wireless en modo station
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz country=argentina \
    disabled=no frequency=2412 mode=station-bridge ssid=agrotech-campo-c \
    wireless-protocol=802.11 wps-mode=disabled

# Configuración de seguridad wireless
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys \
    wpa2-pre-shared-key="Agr0t3chC4mp0Link2024!"

# Configuración de interfaces VLAN
/interface vlan
add interface=ether2 name=vlan20-desktop vlan-id=20
add interface=ether2 name=vlan90-wifi-private vlan-id=90
add interface=ether2 name=vlan201-cctv vlan-id=201

# Configuración de bridge
/interface bridge
add name=bridge-campo-c

/interface bridge port
add bridge=bridge-campo-c interface=wlan1
add bridge=bridge-campo-c interface=ether3
add bridge=bridge-campo-c interface=ether4
add bridge=bridge-campo-c interface=ether5
add bridge=bridge-campo-c interface=vlan20-desktop
add bridge=bridge-campo-c interface=vlan90-wifi-private
add bridge=bridge-campo-c interface=vlan201-cctv

# Configuración de direcciones IP
/ip address
add address=192.168.101.9/30 interface=bridge-campo-c comment="Campo C Station"
add address=10.5.20.1/24 interface=vlan20-desktop comment="Escritorio C"
add address=10.5.90.1/24 interface=vlan90-wifi-private comment="WiFi Privada C"
add address=10.5.201.1/24 interface=vlan201-cctv comment="CCTV C"

# Configuración de DHCP Server local
/ip pool
add name=pool-vlan20-cc ranges=10.5.20.10-10.5.20.50
add name=pool-vlan90-cc ranges=10.5.90.10-10.5.90.50

/ip dhcp-server
add address-pool=pool-vlan20-cc disabled=no interface=vlan20-desktop name=dhcp-vlan20-cc
add address-pool=pool-vlan90-cc disabled=no interface=vlan90-wifi-private name=dhcp-vlan90-cc

/ip dhcp-server network
add address=10.5.20.0/24 dns-server=10.1.10.5 gateway=10.5.20.1
add address=10.5.90.0/24 dns-server=10.1.10.5 gateway=10.5.90.1

# Configuración de ruta por defecto
/ip route
add dst-address=0.0.0.0/0 gateway=192.168.101.1 comment="Default via Campo A"

# Configuración básica de firewall
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.0.0.0/8
add action=accept chain=input protocol=icmp
add action=drop chain=input

add action=accept chain=forward

# Configuración de NTP
/system ntp client
set enabled=yes primary-ntp=10.1.10.5

# Configuración de SNMP
/snmp
set enabled=yes contact="admin@agrotech.com" location="Campo C - Galpon"
```

#### A.6 RB951-CA-02 (Access Point Interior)

```routeros
# Configuración inicial del sistema
/system identity
set name=agrotech-ca-ap

# Configuración de wireless como AP
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20mhz country=argentina \
    disabled=no frequency=2452 mode=ap-bridge ssid=AgroTech-WiFi \
    wireless-protocol=802.11 wps-mode=disabled

# Configuración de perfiles de seguridad para múltiples SSIDs
/interface wireless security-profiles
add authentication-types=wpa2-psk group-ciphers=aes-ccm mode=dynamic-keys name=wifi-private \
    unicast-ciphers=aes-ccm wpa2-pre-shared-key="Agr0T3chWiFi2024!"

add authentication-types=wpa2-psk group-ciphers=aes-ccm mode=dynamic-keys name=wifi-guest \
    unicast-ciphers=aes-ccm wpa2-pre-shared-key="Gu3st2024!"

# Configuración de SSID adicional para invitados
/interface wireless
add disabled=no master-interface=wlan1 multicast-buffering=disabled name=wlan-guest \
    security-profile=wifi-guest ssid=AgroTech-Guest wds-cost-range=0 wds-default-cost=0 \
    wps-mode=disabled

# Configurar perfil de seguridad para SSID principal
/interface wireless
set [ find default-name=wlan1 ] security-profile=wifi-private

# Configuración de interfaces VLAN
/interface vlan
add interface=ether2 name=vlan90-wifi-private vlan-id=90
add interface=ether2 name=vlan96-wifi-guest vlan-id=96

# Configuración de bridge separados para aislamiento
/interface bridge
add name=bridge-private
add name=bridge-guest

/interface bridge port
add bridge=bridge-private interface=wlan1
add bridge=bridge-private interface=vlan90-wifi-private
add bridge=bridge-private interface=ether3
add bridge=bridge-private interface=ether4

add bridge=bridge-guest interface=wlan-guest  
add bridge=bridge-guest interface=vlan96-wifi-guest
add bridge=bridge-guest interface=ether5

# Configuración de direcciones IP
/ip address
add address=10.3.90.1/24 interface=bridge-private comment="WiFi Privada"
add address=10.3.96.1/24 interface=bridge-guest comment="WiFi Invitados"

# Configuración de DHCP para ambas redes
/ip pool
add name=pool-wifi-private ranges=10.3.90.50-10.3.90.200
add name=pool-wifi-guest ranges=10.3.96.10-10.3.96.200

/ip dhcp-server
add address-pool=pool-wifi-private disabled=no interface=bridge-private name=dhcp-wifi-private
add address-pool=pool-wifi-guest disabled=no interface=bridge-guest name=dhcp-wifi-guest

/ip dhcp-server network
add address=10.3.90.0/24 dns-server=10.1.10.5 gateway=10.3.90.1
add address=10.3.96.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=10.3.96.1

# Configuración de firewall para aislamiento de invitados
/ip firewall filter
add action=accept chain=input connection-state=established,related
add action=accept chain=input src-address=10.3.90.0/24
add action=accept chain=input protocol=icmp
add action=drop chain=input src-address=10.3.96.0/24
add action=drop chain=input

add action=accept chain=forward connection-state=established,related
add action=accept chain=forward src-address=10.3.90.0/24
add action=drop chain=forward src-address=10.3.96.0/24 dst-address=10.0.0.0/8
add action=accept chain=forward src-address=10.3.96.0/24
add action=accept chain=forward

# Configuración de NTP
/system ntp client
set enabled=yes primary-ntp=10.3.90.1

# Configuración de SNMP
/snmp
set enabled=yes contact="admin@agrotech.com" location="Campo A - AP Interior"
```

### Anexo B: Capa de Seguridad y Gestión de Identidades

#### B.1 Política de Seguridad General

**Principios de Seguridad:**
1. **Defensa en profundidad:** Múltiples capas de protección
2. **Principio de menor privilegio:** Acceso mínimo necesario
3. **Segregación de redes:** Aislamiento por función
4. **Autenticación fuerte:** WPA2-Enterprise mínimo
5. **Encriptación:** AES-256 para todos los enlaces

#### B.2 Configuración de Certificados Digitales

```routeros
# Generar CA interna
/certificate
add name=ca-template common-name=AgroTech-CA days-valid=3650 key-usage=key-cert-sign,crl-sign

# Firmar certificado CA
/certificate sign ca-template ca-crl-host=10.1.10.5 name=AgroTech-CA

# Generar certificados para cada dispositivo
/certificate
add name=agrotech-lp-gw-template common-name=agrotech-lp-gw days-valid=365 \
    key-usage=digital-signature,key-encipherment

/certificate sign agrotech-lp-gw-template ca=AgroTech-CA name=agrotech-lp-gw-cert
```

#### B.3 Configuración IPSec Site-to-Site

```routeros
# Configuración IPSec entre sitios principales
/ip ipsec proposal
add name=agrotech-proposal auth-algorithms=sha256 enc-algorithms=aes-256-cbc \
    lifetime=8h pfs-group=modp2048

/ip ipsec peer
add address=192.168.100.20/32 local-address=192.168.100.10 name=peer-magdalena \
    secret="Agr0t3chIPSec2024!"

/ip ipsec policy
add disabled=no dst-address=10.2.0.0/16 peer=peer-magdalena proposal=agrotech-proposal \
    src-address=10.1.0.0/16 tunnel=yes
```

#### B.4 Configuración RADIUS para Autenticación Centralizada

```routeros
# Servidor RADIUS (en servidor principal)
/radius
add address=10.1.10.5 secret="R4d1usS3cr3t2024!" service=wireless

# Configuración de perfil de seguridad con RADIUS
/interface wireless security-profiles
add authentication-types=wpa2-eap eap-methods=eap-tls mode=dynamic-keys \
    name=enterprise-profile radius-mac-authentication=yes
```

### Anexo C: Respaldo y Continuidad de Servicio

#### C.1 Script de Respaldo Automático

```routeros
# Script de backup automático
/system script
add name=backup-config owner=admin policy=read,write,test source=\
"# Backup automatico de configuracion\r\
\n/system backup save name=(\"backup-\" . [/system clock get date] . \".backup\")\r\
\n/export file=(\"config-\" . [/system clock get date] . \".rsc\")\r\
\n:log info \"Backup realizado exitosamente\""

# Programar backup diario
/system scheduler
add interval=1d name=daily-backup on-event=backup-config start-date=jan/01/1970 \
    start-time=02:00:00
```

#### C.2 Configuración de Watchdog

```routeros
# Watchdog para monitoreo de conectividad
/tool netwatch
add host=8.8.8.8 interval=30s timeout=5s up-script=\
"/log info \"Internet connectivity OK\"" down-script=\
"/log error \"Internet connectivity FAILED\"; /interface ethernet reset ether1"

add host=192.168.100.20 interval=60s timeout=10s up-script=\
"/log info \"Magdalena link OK\"" down-script=\
"/log error \"Magdalena link FAILED\"; /interface wireless reset wlan1"
```

#### C.3 Configuración de Failover

```routeros
# Configuración de rutas de respaldo
/ip route
add dst-address=0.0.0.0/0 gateway=192.168.100.1 distance=2 comment="Backup route"

# Script de failover automático
/system script
add name=failover-script source=\
":if ([/ping 8.8.8.8 count=3] = 0) do={
    /ip route enable [find comment=\"Backup route\"]
    /log error \"Failover activated\"
}"
```

### Anexo D: Monitoreo y Observabilidad

#### D.1 Configuración SNMP Avanzada

```routeros
# Configuración SNMP con comunidades personalizadas
/snmp community
add name=agrotech-ro read-access=yes write-access=no addresses=10.1.10.0/24

/snmp
set contact="NOC AgroTech <noc@agrotech.com>" enabled=yes location="Red Principal" \
    trap-community=agrotech-trap trap-version=2
```

#### D.2 Sistema de Logging Centralizado

```routeros
# Configuración de syslog remoto
/system logging action
add name=remote-log remote=10.1.10.6 remote-port=514 target=remote

/system logging
add action=remote-log topics=wireless,info
add action=remote-log topics=system,error,critical
add action=remote-log topics=firewall
```

#### D.3 Scripts de Monitoreo

```routeros
# Script de monitoreo de recursos
/system script
add name=resource-monitor source=\
":local cpuLoad [/system resource get cpu-load]
:local freeMemory [/system resource get free-memory]
:local totalMemory [/system resource get total-memory]
:local memoryUsage (100 - (($freeMemory * 100) / $totalMemory))

:if (\$cpuLoad > 80) do={
    /log warning \"High CPU usage: \$cpuLoad%\"
}

:if (\$memoryUsage > 85) do={
    /log warning \"High memory usage: \$memoryUsage%\"
}"

# Programar monitoreo cada 5 minutos
/system scheduler
add interval=5m name=resource-check on-event=resource-monitor start-time=startup
```

### Anexo E: Análisis de Situación y Troubleshooting

#### E.1 Problemas Comunes de Radioenlaces

**E.1.1 Baja Señal/Desconexiones Intermitentes**

*Síntomas:*
- RSSI por debajo de -85dBm
- Pérdida de paquetes >5%
- Desconexiones frecuentes

*Diagnóstico:*
```routeros
# Verificar señal y calidad
/interface wireless print stats

# Monitorear canal para interferencias
/interface wireless scan 0

# Verificar alineación
/tool ping size=1500 count=100
```

*Soluciones:*
1. **Realineación de antenas:** Usar herramientas de alineación
2. **Cambio de canal:** Evitar interferencias
3. **Ajuste de potencia:** Optimizar según distancia
4. **Verificar cables:** Revisar pérdidas en conectores

**E.1.2 Problemas de VLAN**

*Síntomas:*
- Dispositivos no obtienen IP de VLAN correcta
- Tráfico de diferentes VLANs se mezcla
- No hay comunicación entre sitios

*Diagnóstico:*
```routeros
# Verify VLAN configuration
/interface vlan print detail

# Check bridge port assignments
/interface bridge port print

# Monitor VLAN traffic
/tool sniffer quick interface=ether2 duration=30
```

*Soluciones:*
1. **Verificar tagging:** Confirmar configuración 802.1Q
2. **Revisar bridge ports:** Asegurar asignación correcta
3. **Validar DHCP:** Confirmar pools y networks
4. **Firewall rules:** Verificar reglas de forwarding

**E.1.3 Problemas de Throughput**

*Síntomas:*
- Velocidad por debajo de lo esperado
- Latencia alta (>50ms)
- Timeouts en aplicaciones

*Diagnóstico:*
```routeros
# Bandwidth test between sites
/tool bandwidth-test address=192.168.101.5 duration=60s

# Check wireless registration table
/interface wireless registration-table print

# Monitor CPU and memory usage
/system resource print
```

*Soluciones:*
1. **Optimizar wireless:** Ajustar frame size, agregación
2. **QoS implementation:** Priorizar tráfico crítico
3. **Hardware upgrade:** Considerar equipos de mayor capacidad
4. **Channel bonding:** Usar canales de 40MHz si es posible

#### E.2 Procedimientos de Troubleshooting

**E.2.1 Metodología de Diagnóstico**

1. **Verificación de capas OSI:**
   - Capa 1: Conectividad física, antenas, cables
   - Capa 2: Enlaces wireless, bridges, VLANs
   - Capa 3: Ruteo, direccionamiento IP
   - Capa 4: Puertos, servicios

2. **Herramientas de diagnóstico:**
```routeros
# Conectividad básica
/tool ping address=destination count=100 size=1500

# Traceroute para identificar saltos
/tool traceroute address=destination

# Monitoreo de interfaces
/interface monitor-traffic interface=wlan1 duration=30

# Análisis de protocolos
/tool sniffer quick interface=bridge1 duration=60
```

3. **Logs de sistema:**
```routeros
# Ver logs recientes
/log print where topics~"wireless|system|firewall"

# Logs específicos de wireless
/log print where topics~"wireless" and time>today

# Filtrar por severidad
/log print where topics~"error|critical"
```

**E.2.2 Scripts de Diagnóstico Automático**

```routeros
# Script integral de diagnóstico
/system script
add name=network-health-check source=\
":local pingResult [/tool ping address=8.8.8.8 count=3]
:local linkTest [/tool ping address=192.168.100.20 count=3]
:local cpuLoad [/system resource get cpu-load]
:local uptime [/system resource get uptime]

:put \"=== NETWORK HEALTH CHECK ===\"
:put \"Internet connectivity: \$pingResult/3 packets\"
:put \"Magdalena link: \$linkTest/3 packets\"
:put \"CPU Load: \$cpuLoad%\"
:put \"Uptime: \$uptime\"

/interface wireless print stats
/system resource print"
```

#### E.3 Procedimientos de Recuperación

**E.3.1 Recuperación de Configuración**

```routeros
# Restaurar desde backup
/system backup load name=backup-2024-xx-xx.backup

# Importar configuración específica
/import file=config-2024-xx-xx.rsc

# Reset a configuración por defecto (último recurso)
/system reset-configuration no-defaults=yes keep-users=yes
```

**E.3.2 Recuperación de Enlaces**

```routeros
# Reset completo de interfaz wireless
/interface wireless reset wlan1

# Reconfiguración rápida de enlace
/interface wireless set wlan1 ssid=agrotech-campo-link frequency=2437 \
mode=station-bridge disabled=no

# Verificación de reconexión
/interface wireless registration-table print
```

---

## Conclusiones

La implementación de esta infraestructura de radioenlaces para la empresa agrotech representa una solución integral que combina tecnología probada, protocolos de seguridad robustos y metodologías de ingeniería sólidas. El uso de equipos MikroTik RB951ui-2HnD permite una implementación costo-efectiva sin comprometer la funcionalidad o seguridad requerida.

La arquitectura propuesta garantiza la conectividad necesaria para las operaciones distribuidas, manteniendo la segregación de servicios mediante VLANs y asegurando la integridad de los datos a través de múltiples capas de seguridad.

---

## Referencias

1. MikroTik. (2024). *RouterBoard RB951ui-2HnD User Manual*
2. IEEE. (2020). *802.11n-2009 Standard for Wireless LAN*  
3. IEEE. (2014). *802.1Q-2014 Standard for VLANs*
4. RFC 2547. (1999). *BGP/MPLS IP Virtual Private Networks*
5. RFC 4271. (2006). *A Border Gateway Protocol 4 (BGP-4)*