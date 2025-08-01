# Laboratorio: Radioenlaces WDS y Transporte de VLANs - MikroTik RB951ui-2HnD

## Objetivo

Implementar y validar en ambiente de laboratorio indoor la **conectividad de red distribuida** para una empresa agrotech mediante radioenlaces punto a punto, utilizando **transporte transparente de VLANs** sobre tecnología **WDS (Wireless Distribution System)** con equipos MikroTik RB951ui-2HnD.

## Situación Problemática

Una empresa de producción ganadera con tecnología de precisión requiere conectividad de red entre múltiples ubicaciones geográficamente distribuidas:

### Ubicaciones y Distancias
- **Oficinas Centrales (La Plata)** ↔ **Oficina Regional (Magdalena)** → 50km vía ISPs
- **Magdalena** ↔ **Campo de Producción** → 8km sin infraestructura de fibra
- **Campo:** Distribución interna entre Casa Principal (A), Centro de Datos Drones (B) y Galpón/Corrales (C)

### Requerimientos de Red
- **5 VLANs corporativas** transportadas de extremo a extremo:
  - VLAN 10: Servidores ERP/Base de Datos
  - VLAN 20: Estaciones de trabajo administrativas  
  - VLAN 90: WiFi personal autorizado
  - VLAN 96: WiFi invitados
  - VLAN 201: Videovigilancia y drones

- **Servicios centralizados** desde La Plata (DHCP, DNS, Firewall, NAT)
- **Frontera L2** entre ISP mayorista y ISP minorista local
- **Conectividad 24/7** para operaciones críticas de monitoreo de ganado

### Desafíos Técnicos
1. **Transporte transparente** de VLANs sobre múltiples saltos inalámbricos
2. **Interoperabilidad ISP** con handoff en frontera de capa 2
3. **Segmentación de tráfico** manteniendo servicios centralizados
4. **Performance** adecuado para aplicaciones de IA y videovigilancia

## Conceptos Técnicos a Desarrollar

### 1. WDS (Wireless Distribution System)
**Implementación:** Extensión de dominio L2 sobre radioenlaces
- **AP WDS** en Magdalena para distribución hacia campo
- **Station WDS** en Campo A con capacidad de redistribución
- **Bridge transparente** que preserva información de VLANs
- **Topología en estrella** desde Campo A hacia B y C

### 2. VLAN Tagging y Bridging
**802.1Q Implementation:**
- **VLAN filtering** habilitado en bridges principales
- **Tagged interfaces** en enlaces troncales inalámbricos
- **Untagged access** en puertos de usuario final
- **VLAN-aware bridging** para forwarding inteligente

### 3. Frontera L2 ISP (Q-in-Q)
**Service Provider VLANs:**
- **VLAN 201** como trunk carrier para todas las VLANs cliente
- **Double tagging** para aislamiento entre clientes del ISP
- **Handoff transparente** entre ISP mayorista y minorista
- **EoIP tunneling** como alternativa de transporte

### 4. Servicios de Red Centralizados
**Arquitectura Hub-and-Spoke:**
- **DHCP Server** unificado con pools por ubicación
- **DNS forwarding** corporativo + resolución pública
- **Firewall policies** por VLAN con inter-VLAN routing controlado
- **NAT centralizado** para salida a Internet

### 5. Seguridad en Radioenlaces
**Multi-layer Security:**
- **WPA2-PSK** con AES-256 para cifrado de enlace
- **MAC Address filtering** en enlaces críticos (opcional)
- **Firewall granular** por VLAN y función
- **Management VLAN** separada (VLAN 200) para administración

### 6. Optimización RF para Indoor
**Parámetros de Radioenlace:**
- **Separación de frecuencias:** Canales 1, 6, 11 para evitar interferencia
- **Potencia controlada:** 5-10dBm para distancias cortas indoor
- **Channel width:** 20MHz para estabilidad
- **Frame aggregation** para mejor throughput

## Topología Implementada

```
[MK01: Gateway La Plata]
    ↓ (Cable + Switch simulando ISPs)
[MK02: AP WDS Magdalena] ←→ (2.4GHz Canal 6) ←→ [MK03: Station WDS Campo A]
                                                        ↓
                                    ┌─────────────────────────────────┐
                                    │                                 │
                        (Canal 11) ←→ [MK04: Station Campo B]     [MK05: Station Campo C] ←→ (Canal 1)
                                    │                                 │
                                    └─────── [MK06: AP Local] ────────┘
```

## Metodología de Validación

### Métricas de Conectividad WDS
- **Signal Strength (RSSI):** Medición de potencia recibida
- **Signal-to-Noise Ratio (SNR):** Calidad de señal vs ruido
- **Registration Table:** Verificación de enlaces WDS activos
- **Bridge MAC Table:** Validación de forwarding L2

### Métricas de Performance
- **Throughput:** Bandwidth test TCP/UDP entre extremos
- **Latency:** Ping tests con diferentes tamaños de frame
- **Packet Loss:** Medición de pérdidas bajo carga
- **Jitter:** Variación de latencia para aplicaciones tiempo-real

### Validación de VLANs
- **DHCP Success Rate:** Obtención de IP desde servidor central
- **Inter-VLAN Routing:** Comunicación controlada entre segmentos
- **VLAN Isolation:** Verificación de aislamiento (ej: VLAN 96 vs internas)
- **Broadcast Domain:** Validación de alcance de broadcasts por VLAN

### Pruebas de Servicios
- **DNS Resolution:** Resolución de nombres corporativos y públicos
- **Centralized Services:** Funcionamiento de servicios desde La Plata
- **NAT Functionality:** Salida a Internet desde todas las ubicaciones
- **Management Access:** Acceso SSH/WinBox desde red de gestión

## Equipos y Software

- **Hardware:** 6x MikroTik RB951ui-2HnD (AR9344 600MHz, 128MB RAM)
- **Software:** RouterOS 6.x
- **Management:** WinBox, SSH CLI
- **Monitoring:** SNMP, built-in tools (ping, torch, bandwidth-test)
- **Documentation:** Scripts de automatización y templates de medición

