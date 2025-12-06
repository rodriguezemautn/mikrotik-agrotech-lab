# 🌾 AgroTech Network Infrastructure
## Documentación Técnica Completa - Versión 051225_V7

---

## 📑 Tabla de Contenidos

1. [Resumen General](#1-resumen-general)
2. [Arquitectura de Red](#2-arquitectura-de-red)
3. [Esquema de VLANs](#3-esquema-de-vlans)
4. [Documentación por Dispositivo](#4-documentación-por-dispositivo)
5. [Enlaces Inalámbricos](#5-enlaces-inalámbricos)
6. [Sistema DHCP Distribuido](#6-sistema-dhcp-distribuido)
7. [Seguridad y Firewall](#7-seguridad-y-firewall)
8. [Scripts de Monitoreo](#8-scripts-de-monitoreo)
9. [Procedimientos de Despliegue](#9-procedimientos-de-despliegue)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Resumen General

### 1.1 Descripción del Proyecto

Red corporativa multi-sitio para empresa agroindustrial con sede central en La Plata y operaciones de campo en zona rural de Magdalena (Provincia de Buenos Aires, Argentina).

### 1.2 Especificaciones Técnicas

| Parámetro | Especificación |
|-----------|----------------|
| **Plataforma** | MikroTik RouterOS 6.49.19 |
| **Hardware Core** | RB951Ui-2HnD (6 unidades) |
| **Hardware PTP** | SXT G-2HnD (2 unidades) |
| **Protocolo Wireless** | NV2 (propietario MikroTik) |
| **Banda RF** | 2.4 GHz (2400-2483.5 MHz) |
| **Encapsulación WAN** | Q-in-Q (IEEE 802.1ad) |
| **Protocolo L2** | IEEE 802.1Q VLAN Tagging |

### 1.3 Inventario de Equipos

| ID | Modelo | Serial Number | Software ID | Ubicación |
|----|--------|---------------|-------------|-----------|
| MK01 | RB951Ui-2HnD | 558304337A4F | LLBU-WG2H | La Plata |
| MK02 | RB951Ui-2HnD | 4AC902473E00 | ZFXZ-LQ9Z | Magdalena Ciudad |
| MK03 | RB951Ui-2HnD | 4AC9041BDB96 | 3JKZ-AQ07 | Campo A |
| MK04 | RB951Ui-2HnD | 4AC904BEAE7D | 9TDR-2B2W | Campo - Centro Datos |
| MK05 | RB951Ui-2HnD | 4AC904BA91D8 | UXS0-IHTB | Campo - Galpón |
| MK06 | RB951Ui-2HnD | 6433050CA0B0 | GCUB-ETCR | Campo - AP Extra |
| SXT-MG | SXT G-2HnD | 5A9505C44A45 | QRX6-0SS9 | Magdalena - Torre |
| SXT-CA | SXT G-2HnD | 41FE02CC65CB | NNNW-EHRR | Campo - Torre |

---

## 2. Arquitectura de Red

### 2.1 Diagrama de Topología Completo

```
                                    INTERNET
                                        │
                                        │ PPPoE/DHCP
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              LA PLATA - SEDE CENTRAL                             │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                         MK01-agrotech-lp-gw                               │   │
│  │                      RB951Ui-2HnD (10.200.1.1)                            │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────────────┐   │   │
│  │  │ ether1  │ ether2  │ ether3  │ ether4  │ ether5  │     wlan1       │   │   │
│  │  │  WAN    │ ISP/Trk │  MGMT   │  VLAN10 │ VLAN201 │  AP (90/96)     │   │   │
│  │  └────┬────┴────┬────┴────┬────┴────┬────┴────┬────┴────────┬────────┘   │   │
│  │       │         │         │         │         │             │            │   │
│  └───────│─────────│─────────│─────────│─────────│─────────────│────────────┘   │
│          │         │         │         │         │             │                │
│       Internet   Trunk    Laptop    Servers    CCTV      WiFi Corp            │
└──────────────────────│──────────────────────────────────────────────────────────┘
                       │
                       │ Q-in-Q VLAN 4000 / Direct Trunk
                       │ (VLANs: 10,20,90,96,201,999)
                       ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           MAGDALENA CIUDAD - HUB                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                         MK02-agrotech-mg-ap                               │   │
│  │                      RB951Ui-2HnD (10.200.1.10)                           │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────────────┐   │   │
│  │  │ ether1  │ ether2  │ ether3  │ ether4  │ ether5  │     wlan1       │   │   │
│  │  │ To SXT  │ ISP/Trk │  MGMT   │  Local  │  Local  │   Reserved      │   │   │
│  │  └────┬────┴────┬────┴────┬────┴─────────┴─────────┴─────────────────┘   │   │
│  │       │         │         │                                              │   │
│  └───────│─────────│─────────│──────────────────────────────────────────────┘   │
│          │                   │                                                  │
│          │                 Laptop                                               │
└──────────│──────────────────────────────────────────────────────────────────────┘
           │
           │ Trunk VLANs
           ▼
    ┌──────────────┐
    │   SXT-MG     │
    │ PTP AP       │
    │ 10.200.1.50  │
    └──────┬───────┘
           │
           │ ═══════════════════════════════════════════════
           │         ENLACE PTP 8 KM - 2437 MHz NV2
           │ ═══════════════════════════════════════════════
           │
    ┌──────┴───────┐
    │   SXT-CA     │
    │ PTP Station  │
    │ 10.200.1.51  │
    └──────┬───────┘
           │
           │ Trunk VLANs
           ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CAMPO A - OPERACIONES                               │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                         MK03-agrotech-ca-gw                               │   │
│  │                      RB951Ui-2HnD (10.200.1.20)                           │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────────────┐   │   │
│  │  │ ether1  │ ether2  │ ether3  │ ether4  │ ether5  │     wlan1       │   │   │
│  │  │From SXT │  Spare  │  MGMT   │ VLAN10  │ VLAN20  │   PTMP AP       │   │   │
│  │  └────┬────┴─────────┴────┬────┴────┬────┴────┬────┴────────┬────────┘   │   │
│  │       │                   │         │         │             │            │   │
│  └───────│───────────────────│─────────│─────────│─────────────│────────────┘   │
│          │                   │         │         │             │                │
│      From PTP             Laptop    Servers  Desktop    PTMP Master            │
│                                                              │                  │
│                          ┌───────────────────────────────────┤                  │
│                          │               │                   │                  │
│                          ▼               ▼                   ▼                  │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                       │
│  │     MK04      │  │     MK05      │  │     MK06      │                       │
│  │ Centro Datos  │  │    Galpón     │  │   AP Extra    │                       │
│  │  10.200.1.21  │  │  10.200.1.22  │  │  10.200.1.25  │                       │
│  │               │  │               │  │               │                       │
│  │ eth4: VLAN10  │  │ eth4: VLAN20  │  │ eth4: Trunk   │                       │
│  │ eth5: VLAN201 │  │ eth5: VLAN201 │  │   (90/96)     │                       │
│  │  (Servers)    │  │  (Desktop)    │  │  (WiFi APs)   │                       │
│  │  (CCTV)       │  │  (CCTV)       │  │               │                       │
│  └───────────────┘  └───────────────┘  └───────────────┘                       │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Flujo de Tráfico

```
                    TRÁFICO CORPORATIVO
    ┌──────────────────────────────────────────────────────┐
    │                                                      │
    │  PC en MK04        Servidor en MK01                  │
    │  VLAN 10           VLAN 10                           │
    │  192.168.10.160    192.168.10.50                     │
    │       │                  ▲                           │
    │       ▼                  │                           │
    │  MK04 (Bridge)           │                           │
    │       │                  │                           │
    │       ▼ (PTMP)           │                           │
    │  MK03 (Bridge)           │                           │
    │       │                  │                           │
    │       ▼ (Ethernet)       │                           │
    │  SXT-CA (Bridge)         │                           │
    │       │                  │                           │
    │       ▼ (8km PTP)        │                           │
    │  SXT-MG (Bridge)         │                           │
    │       │                  │                           │
    │       ▼ (Ethernet)       │                           │
    │  MK02 (Bridge L2)        │                           │
    │       │                  │                           │
    │       ▼ (Q-in-Q/Trunk)   │                           │
    │  MK01 (Router) ──────────┘                           │
    │       │                                              │
    │  Routing entre VLANs / NAT a Internet                │
    │                                                      │
    └──────────────────────────────────────────────────────┘
```

---

## 3. Esquema de VLANs

### 3.1 Definición de VLANs

| VLAN ID | Nombre | Red | Gateway | Propósito |
|---------|--------|-----|---------|-----------|
| 10 | Servers | 192.168.10.0/24 | 192.168.10.1 | Servidores, NAS, infraestructura crítica |
| 20 | Desktop | 192.168.20.0/24 | 192.168.20.1 | Estaciones de trabajo, PCs administrativos |
| 90 | WiFi-Private | 192.168.90.0/24 | 192.168.90.1 | Dispositivos móviles corporativos |
| 96 | WiFi-Guest | 192.168.96.0/24 | 192.168.96.1 | Invitados, dispositivos no confiables |
| 201 | CCTV | 192.168.201.0/24 | 192.168.201.1 | Cámaras IP, DVR/NVR |
| 999 | Management | 10.200.1.0/24 | 10.200.1.1 | Administración de equipos de red |
| 4000 | S-VLAN | — | — | Encapsulación Q-in-Q (solo MK01↔MK02) |

### 3.2 Matriz de VLANs por Dispositivo

| Dispositivo | VLAN 10 | VLAN 20 | VLAN 90 | VLAN 96 | VLAN 201 | VLAN 999 |
|-------------|---------|---------|---------|---------|----------|----------|
| MK01 | ✅ L3 GW | ✅ L3 GW | ✅ L3 GW | ✅ L3 GW | ✅ L3 GW | ✅ L3 GW |
| MK02 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L3 |
| SXT-MG | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L3 |
| SXT-CA | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L3 |
| MK03 | ✅ L2+DHCP | ✅ L2+DHCP | ✅ L2+DHCP | ✅ L2+DHCP | ✅ L2+DHCP | ✅ L3 |
| MK04 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L3 |
| MK05 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L3 |
| MK06 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L2 | ✅ L3 |

**Leyenda:** L2 = Bridge transparente | L3 = IP asignada | GW = Gateway/Router | DHCP = Servidor DHCP backup

### 3.3 Asignación de Puertos por VLAN

#### MK01 - Gateway Principal
| Puerto | VLAN | Modo | Función |
|--------|------|------|---------|
| ether1-wan | — | — | WAN Internet |
| ether2-isp | All | Tagged | Trunk Q-in-Q/ISP |
| ether3-mgmt | 999 | Untagged | Acceso management |
| ether4-local | 10 | Untagged | Servidores locales |
| ether5-local | 201 | Untagged | CCTV local |
| wlan1 | 90/96 | Tagged | AP WiFi corporativo |

#### MK02 - Hub Magdalena
| Puerto | VLAN | Modo | Función |
|--------|------|------|---------|
| ether1-to-sxt | All | Tagged | Trunk a SXT-MG |
| ether2-isp | All | Tagged | Trunk desde MK01 |
| ether3-mgmt | 999 | Untagged | Acceso management |
| ether4-local | All | Tagged | Puerto local opcional |
| ether5-local | All | Tagged | Puerto local opcional |

#### MK03 - Gateway Campo
| Puerto | VLAN | Modo | Función |
|--------|------|------|---------|
| ether1-ptp | All | Tagged | Trunk desde SXT-CA |
| ether2-spare | — | — | Reservado |
| ether3-mgmt | 999 | Untagged | Acceso management |
| ether4-servers | 10 | Untagged | Servidores campo |
| ether5-desktop | 20 | Untagged | Desktop campo |
| wlan1 | All | Tagged | PTMP Master |

#### MK04 - Centro de Datos
| Puerto | VLAN | Modo | Función |
|--------|------|------|---------|
| wlan1 | All | Tagged | PTMP Station |
| ether3-mgmt | 999 | Untagged | Acceso management |
| ether4-servers | 10 | Untagged | Servidores/Drones |
| ether5-cctv | 201 | Untagged | Cámaras |

#### MK05 - Galpón
| Puerto | VLAN | Modo | Función |
|--------|------|------|---------|
| wlan1 | All | Tagged | PTMP Station |
| ether3-mgmt | 999 | Untagged | Acceso management |
| ether4-desktop | 20 | Untagged | Estaciones trabajo |
| ether5-cctv | 201 | Untagged | Cámaras |

#### MK06 - AP Extra
| Puerto | VLAN | Modo | Función |
|--------|------|------|---------|
| wlan1 | All | Tagged | PTMP Station |
| ether3-mgmt | 999 | Untagged | Acceso management |
| ether4-trunk | 90/96/999 | Tagged | Trunk para APs externos |

---

## 4. Documentación por Dispositivo

### 4.1 MK01 - Gateway Principal La Plata

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | MK01-agrotech-lp-gw |
| **Modelo** | RB951Ui-2HnD |
| **IP Management** | 10.200.1.1/24 |
| **Rol** | Gateway central, DHCP primario, NAT, Firewall |
| **SNMP Location** | La Plata - Gateway Central |

#### Configuración de Interfaces
```
/interface ethernet
ether1-wan      - WAN Internet (DHCP Client)
ether2-isp      - Trunk Q-in-Q hacia MK02 (MTU 1590)
ether3-mgmt     - Management local (VLAN 999 untagged)
ether4-local    - Servidores (VLAN 10 untagged)
ether5-local    - CCTV (VLAN 201 untagged)

/interface wireless
wlan1           - AP "Agrotech-Office-LP" (VLANs 90/96)
```

#### Bridge y VLANs
```
Bridge: BR-LOCAL (vlan-filtering=yes)
├── ether2-isp (tagged: 10,20,90,96,201,999,4000)
├── ether3-mgmt (untagged: 999)
├── ether4-local (untagged: 10)
├── ether5-local (untagged: 201)
└── wlan1 (tagged: 90,96)
```

#### Direccionamiento IP
| Interface | IP | Red |
|-----------|-----|-----|
| vlan10-local | 192.168.10.1/24 | Servers |
| vlan20-local | 192.168.20.1/24 | Desktop |
| vlan90-local | 192.168.90.1/24 | WiFi Private |
| vlan96-local | 192.168.96.1/24 | WiFi Guest |
| vlan201-local | 192.168.201.1/24 | CCTV |
| vlan999-mgmt | 10.200.1.1/24 | Management |

#### DHCP Servers
| Server | Pool | Rango | Lease Time |
|--------|------|-------|------------|
| dhcp-vlan10 | pool-vlan10 | .100-.129 | 1h |
| dhcp-vlan20 | pool-vlan20 | .100-.129 | 1h |
| dhcp-vlan90 | pool-vlan90 | .100-.129 | 8h |
| dhcp-vlan96 | pool-vlan96 | .100-.129 | 1h |
| dhcp-vlan201 | pool-vlan201 | .100-.129 | 1d |
| dhcp-vlan999 | pool-vlan999 | .10-.19 | 1d |

#### Servicios Adicionales
- **DNS**: Recursivo (8.8.8.8, 1.1.1.1), cache 4MB
- **NTP**: Cliente (200.23.1.7, 200.23.1.1)
- **SNMP**: v2, comunidad configurada
- **Email**: SMTP Gmail para alertas
- **Backup**: Automático diario 03:00

#### Scripts Disponibles
| Script | Función |
|--------|---------|
| `check-qinq` | Verificar estado encapsulación Q-in-Q |
| `check-connectivity` | Ping a equipos remotos |
| `full-topology-check` | Test completo + alertas email |
| `check-dhcp-status` | Estado servidores y leases DHCP |
| `test-full-connectivity` | Test end-to-end por VLAN |

---

### 4.2 MK02 - Hub Q-in-Q Magdalena

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | MK02-agrotech-mg-ap |
| **Modelo** | RB951Ui-2HnD |
| **IP Management** | 10.200.1.10/24 |
| **Rol** | Desencapsulador Q-in-Q, Bridge L2 |
| **SNMP Location** | Magdalena Ciudad - Hub Q-in-Q |

#### Configuración de Interfaces
```
/interface ethernet
ether1-to-sxt   - Trunk hacia SXT-MG (MTU 1590)
ether2-isp      - Trunk desde MK01 (MTU 1590)
ether3-mgmt     - Management local (VLAN 999 untagged)
ether4-local    - Puerto local opcional (trunk)
ether5-local    - Puerto local opcional (trunk)
```

#### Arquitectura de Bridges
```
BR-TRANSPORT (vlan-filtering=no)
├── ether2-isp (trunk desde MK01)
└── ether1-to-sxt (trunk hacia SXT-MG)

BR-MGMT-ACCESS (vlan-filtering=yes)
└── ether3-mgmt (VLAN 999 untagged)

BR-MGMT-UNION (une VLAN 999 de diferentes orígenes)
├── vlan999-access (desde BR-MGMT-ACCESS)
├── vlan999-local (desde BR-LOCAL-OPTIONAL)
└── vlan999-transport (desde BR-TRANSPORT)

BR-LOCAL-OPTIONAL (puertos locales opcionales)
├── ether4-local
└── ether5-local
```

#### VLAN Especial S-VLAN 4000
```
s-vlan-4000-transport
├── Interface: ether2-isp
├── VLAN ID: 4000
├── MTU: 1590
└── Función: Desencapsula Q-in-Q, C-VLANs pasan intactas
```

#### Scripts Disponibles
| Script | Función |
|--------|---------|
| `check-qinq-transport` | Estado transporte Q-in-Q |
| `ping-topology-test` | Test conectividad todos los nodos |
| `check-bridges` | Estado de todos los bridges |
| `quick-diag` | Diagnóstico rápido (CPU, mem, pings) |
| `traffic-monitor` | Tráfico en interfaces principales |

---

### 4.3 SXT-MG - PTP AP Magdalena

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | SXT-MG-PTP-AP |
| **Modelo** | SXT G-2HnD |
| **IP Management** | 10.200.1.50/24 |
| **Rol** | Access Point enlace PTP 8km |
| **SNMP Location** | Magdalena - PtP AP (8km to Campo) |

#### Configuración Wireless
| Parámetro | Valor |
|-----------|-------|
| **Mode** | ap-bridge |
| **SSID** | Agrotech-PTP-MG-CA (oculto) |
| **Frequency** | 2437 MHz (Canal 6) |
| **Protocol** | NV2 |
| **Distance** | 8000m |
| **WDS** | Static |
| **Security** | WPA2-PSK (ptp-secure) |
| **ANI** | AP and Client Mode |
| **TX Power** | All rates fixed |

#### Bridge Configuration
```
BR-PTP (protocol-mode=none, vlan-filtering=yes)
├── ether1-trunk (tagged: 10,20,90,96,201,999)
└── wlan1 (tagged: 10,20,90,96,201,999)
```

#### Scripts Disponibles
| Script | Función |
|--------|---------|
| `check-ptp-status` | Estado general enlace PTP |
| `check-signal` | Señal y calidad de clientes |
| `check-throughput` | Test bandwidth a SXT-CA |

---

### 4.4 SXT-CA - PTP Station Campo

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | SXT-CA-PTP-Station |
| **Modelo** | SXT G-2HnD |
| **IP Management** | 10.200.1.51/24 |
| **Rol** | Station enlace PTP 8km |
| **SNMP Location** | Campo - PtP Station (8km from Magdalena) |

#### Configuración Wireless
| Parámetro | Valor |
|-----------|-------|
| **Mode** | station-bridge |
| **SSID** | Agrotech-PTP-MG-CA |
| **Frequency** | 2437 MHz (Canal 6) |
| **Protocol** | NV2 |
| **Distance** | 8000m |
| **WDS** | Static |
| **Security** | WPA2-PSK (ptp-secure) |
| **Scan List** | 2437 (fijo) |

#### Bridge Configuration
```
BR-PTP (protocol-mode=none, vlan-filtering=yes)
├── ether1-trunk (tagged: 10,20,90,96,201,999)
└── wlan1 (tagged: 10,20,90,96,201,999)
```

#### Scripts Disponibles
| Script | Función |
|--------|---------|
| `check-connection-status` | Estado conexión a SXT-MG |
| `check-signal` | Métricas de señal detalladas |
| `bw-test-to-mg` | Test bandwidth hacia SXT-MG |

---

### 4.5 MK03 - Gateway Campo / PTMP Master

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | MK03-agrotech-ca-gw |
| **Modelo** | RB951Ui-2HnD |
| **IP Management** | 10.200.1.20/24 |
| **Rol** | Gateway secundario, DHCP backup, PTMP Master |
| **SNMP Location** | Campo A - PTMP AP Gateway |

#### Configuración de Interfaces
```
/interface ethernet
ether1-ptp      - Trunk desde SXT-CA (MTU 1590)
ether2-spare    - Reservado
ether3-mgmt     - Management local (VLAN 999 untagged)
ether4-servers  - Servidores (VLAN 10 untagged)
ether5-desktop  - Desktop (VLAN 20 untagged)

/interface wireless
wlan1           - PTMP AP Master "Agrotech-PTMP-Campo"
```

#### Configuración Wireless PTMP
| Parámetro | Valor |
|-----------|-------|
| **Mode** | ap-bridge |
| **SSID** | Agrotech-PTMP-Campo |
| **Frequency** | 2462 MHz (Canal 11) |
| **Protocol** | NV2 |
| **Distance** | Indoors |
| **WDS** | Dynamic |
| **Security** | WPA2-PSK (ptmp-campo) |

#### Bridge Configuration
```
BR-CAMPO (vlan-filtering=yes)
├── ether1-ptp (tagged: 10,20,90,96,201,999)
├── ether3-mgmt (untagged: 999)
├── ether4-servers (untagged: 10)
├── ether5-desktop (untagged: 20)
└── wlan1 (tagged: 10,20,90,96,201,999)
```

#### DHCP Backup (Failover)
| Server | Pool | Rango | Estado |
|--------|------|-------|--------|
| dhcp-vlan10-backup | pool-vlan10-backup | .150-.199 | Disabled (auto) |
| dhcp-vlan20-backup | pool-vlan20-backup | .150-.199 | Disabled (auto) |
| dhcp-vlan90-backup | pool-vlan90-backup | .150-.199 | Disabled (auto) |
| dhcp-vlan96-backup | pool-vlan96-backup | .150-.199 | Disabled (auto) |
| dhcp-vlan201-backup | pool-vlan201-backup | .150-.199 | Disabled (auto) |

#### IPs Locales (Emergencia)
| Interface | IP | Función |
|-----------|-----|---------|
| vlan10-dhcp | 192.168.10.254/24 | Gateway backup VLAN 10 |
| vlan20-dhcp | 192.168.20.254/24 | Gateway backup VLAN 20 |
| vlan90-dhcp | 192.168.90.254/24 | Gateway backup VLAN 90 |
| vlan96-dhcp | 192.168.96.254/24 | Gateway backup VLAN 96 |
| vlan201-dhcp | 192.168.201.254/24 | Gateway backup VLAN 201 |

#### Netwatch Failover
```routeros
/tool netwatch
host=10.200.1.1 interval=10s timeout=3s
down-script: Activa DHCP backup servers
up-script: Desactiva DHCP backup servers
```

#### Scripts Disponibles
| Script | Función |
|--------|---------|
| `check-ptmp-clients` | Clientes PTMP registrados |
| `check-vlans` | Estado VLANs en bridge |
| `ping-test-all` | Test conectividad |
| `full-topology-check` | Test completo + alertas |
| `check-autonomous-mode` | Verificar modo failover |
| `ver-failover` | Estado actual failover |
| `test-failover` | Simular caída MK01 |
| `ver-leases` | Leases DHCP activos |

---

### 4.6 MK04 - Centro de Datos Campo

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | MK04-agrotech-cd-st |
| **Modelo** | RB951Ui-2HnD |
| **IP Management** | 10.200.1.21/24 |
| **Rol** | Station PTMP, acceso local |
| **SNMP Location** | Campo - Centro de Datos/Drones |

#### Configuración de Interfaces
```
/interface ethernet
ether3-mgmt     - Management (VLAN 999 untagged)
ether4-servers  - Servidores/Drones (VLAN 10 untagged)
ether5-cctv     - Cámaras (VLAN 201 untagged)

/interface wireless
wlan1           - PTMP Station "Agrotech-PTMP-Campo"
```

#### Bridge Configuration
```
BR-CAMPO (vlan-filtering=yes)
├── wlan1 (tagged: 10,20,90,96,201,999)
├── ether3-mgmt (untagged: 999)
├── ether4-servers (untagged: 10)
└── ether5-cctv (untagged: 201)
```

---

### 4.7 MK05 - Galpón/Tambo

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | MK05-agrotech-cc-st |
| **Modelo** | RB951Ui-2HnD |
| **IP Management** | 10.200.1.22/24 |
| **Rol** | Station PTMP, acceso local |
| **SNMP Location** | Campo - Galpon/Corrales/Tambo |

#### Configuración de Interfaces
```
/interface ethernet
ether3-mgmt     - Management (VLAN 999 untagged)
ether4-desktop  - Estaciones trabajo (VLAN 20 untagged)
ether5-cctv     - Cámaras (VLAN 201 untagged)

/interface wireless
wlan1           - PTMP Station "Agrotech-PTMP-Campo"
```

#### Bridge Configuration
```
BR-CAMPO (vlan-filtering=yes)
├── wlan1 (tagged: 10,20,90,96,201,999)
├── ether3-mgmt (untagged: 999)
├── ether4-desktop (untagged: 20)
└── ether5-cctv (untagged: 201)
```

---

### 4.8 MK06 - AP Extra

#### Información General
| Parámetro | Valor |
|-----------|-------|
| **Identity** | MK06-agrotech-ap-extra |
| **Modelo** | RB951Ui-2HnD |
| **IP Management** | 10.200.1.25/24 |
| **Rol** | Station PTMP, trunk para APs WiFi externos |
| **SNMP Location** | Campo - AP Extra |

#### Configuración de Interfaces
```
/interface ethernet
ether3-mgmt     - Management (VLAN 999 untagged)
ether4-trunk    - Trunk VLANs 90/96/999 (tagged)

/interface wireless
wlan1           - PTMP Station "Agrotech-PTMP-Campo"
```

#### Bridge Configuration
```
BR-CAMPO (vlan-filtering=yes)
├── wlan1 (tagged: 10,20,90,96,201,999)
├── ether3-mgmt (untagged: 999)
└── ether4-trunk (tagged: 90,96,999)
```

---

## 5. Enlaces Inalámbricos

### 5.1 Enlace PTP 8km (Magdalena ↔ Campo)

#### Especificaciones
| Parámetro | Valor |
|-----------|-------|
| **Distancia** | ~8 km |
| **Frecuencia** | 2437 MHz (Canal 6, 2.4GHz) |
| **Protocolo** | NV2 |
| **Equipos** | SXT G-2HnD |
| **Antena** | Integrada 10dBi 60° |
| **WDS Mode** | Static |
| **SSID** | Agrotech-PTP-MG-CA |
| **Seguridad** | WPA2-PSK |

#### Configuración Radio
| Parámetro | SXT-MG (AP) | SXT-CA (Station) |
|-----------|-------------|------------------|
| Mode | ap-bridge | station-bridge |
| SSID | Agrotech-PTP-MG-CA | Agrotech-PTP-MG-CA |
| Hide SSID | Yes | N/A |
| Frequency | 2437 | 2437 |
| Scan List | Default | 2437 |
| Distance | 8000 | 8000 |
| ANI | ap-and-client-mode | ap-and-client-mode |
| TX Power | all-rates-fixed | all-rates-fixed |
| Default Forwarding | No | No |

#### Cálculo de Enlace (Estimado)
```
Free Space Path Loss (2437 MHz, 8km):
FSPL = 20*log10(8) + 20*log10(2437) + 32.44 = 111.2 dB

Link Budget:
TX Power (SXT): +30 dBm (1W EIRP típico Argentina)
TX Antenna Gain: +10 dBi
RX Antenna Gain: +10 dBi
Cable Loss: -1 dB (integrado)
Path Loss: -111.2 dB
────────────────────────────
Señal esperada: ~ -62 dBm

Sensibilidad RX (MCS7): -78 dBm
Margen: ~16 dB ✓
```

#### Verificación de Enlace
```routeros
# En SXT-MG (AP):
/interface wireless registration-table print detail
/interface wireless monitor wlan1 once

# En SXT-CA (Station):
/system script run check-signal
```

### 5.2 Red PTMP Campo

#### Especificaciones
| Parámetro | Valor |
|-----------|-------|
| **Frecuencia** | 2462 MHz (Canal 11, 2.4GHz) |
| **Protocolo** | NV2 |
| **Master** | MK03 |
| **Stations** | MK04, MK05, MK06 |
| **WDS Mode** | Dynamic |
| **SSID** | Agrotech-PTMP-Campo |
| **Seguridad** | WPA2-PSK |

#### Topología PTMP
```
              MK03 (AP Master)
                   │
         ┌─────────┼─────────┐
         ▼         ▼         ▼
       MK04      MK05      MK06
     (Station) (Station) (Station)
```

#### Separación de Canales
```
PTP Link:  Canal 6  (2437 MHz)  ████████████
PTMP Link: Canal 11 (2462 MHz)              ████████████

Separación: 25 MHz (mínimo recomendado en 2.4GHz)
```

#### Verificación PTMP
```routeros
# En MK03 (Master):
/interface wireless registration-table print
/system script run check-ptmp-clients

# En Stations (MK04/05/06):
/interface wireless monitor wlan1 once
```

---

## 6. Sistema DHCP Distribuido

### 6.1 Arquitectura

```
┌────────────────────────────────────────────────────────────────────┐
│                      CLIENTE DHCP                                  │
│                           │                                        │
│                           ▼                                        │
│                    DHCP DISCOVER                                   │
│                    (Broadcast L2)                                  │
│                           │                                        │
│              ┌────────────┴────────────┐                          │
│              ▼                         ▼                          │
│    ┌─────────────────┐       ┌─────────────────┐                  │
│    │    MK01         │       │    MK03         │                  │
│    │  DHCP PRIMARIO  │       │  DHCP BACKUP    │                  │
│    │  (Siempre ON)   │       │  (Netwatch)     │                  │
│    │                 │       │                 │                  │
│    │ Pool: .100-.129 │       │ Pool: .150-.199 │                  │
│    │ delay: 0s       │       │ delay: 2s       │                  │
│    └────────┬────────┘       └────────┬────────┘                  │
│             │                         │                           │
│             │  DHCP OFFER             │  DHCP OFFER               │
│             │  (llega primero)        │  (llega 2s después)       │
│             ▼                         │                           │
│       CLIENTE ACEPTA                  │                           │
│       IP de MK01                      ▼                           │
│       (.100-.129)               (descartado)                      │
└────────────────────────────────────────────────────────────────────┘
```

### 6.2 Pools DHCP

#### MK01 - Primario
| VLAN | Pool | Rango | Gateway | Lease |
|------|------|-------|---------|-------|
| 10 | pool-vlan10 | 192.168.10.100-129 | .1 | 1h |
| 20 | pool-vlan20 | 192.168.20.100-129 | .1 | 1h |
| 90 | pool-vlan90 | 192.168.90.100-129 | .1 | 8h |
| 96 | pool-vlan96 | 192.168.96.100-129 | .1 | 1h |
| 201 | pool-vlan201 | 192.168.201.100-129 | .1 | 1d |
| 999 | pool-vlan999 | 10.200.1.10-19 | .1 | 1d |

#### MK03 - Backup
| VLAN | Pool | Rango | Gateway | Lease |
|------|------|-------|---------|-------|
| 10 | pool-vlan10-backup | 192.168.10.150-199 | .1 | 1h |
| 20 | pool-vlan20-backup | 192.168.20.150-199 | .1 | 1h |
| 90 | pool-vlan90-backup | 192.168.90.150-199 | .1 | 8h |
| 96 | pool-vlan96-backup | 192.168.96.150-199 | .1 | 1h |
| 201 | pool-vlan201-backup | 192.168.201.150-199 | .1 | 1d |

### 6.3 Mecanismo de Failover

```routeros
# Configuración Netwatch en MK03
/tool netwatch add \
    host=10.200.1.1 \
    interval=10s \
    timeout=3s \
    up-script={
        :log info "MK01 ONLINE - Desactivando DHCP Backup"
        /ip dhcp-server set [find name~"backup"] disabled=yes
    } \
    down-script={
        :log warning "MK01 OFFLINE - Activando DHCP Backup"
        /ip dhcp-server set [find name~"backup"] disabled=no
    }
```

### 6.4 Verificación DHCP

```routeros
# En MK01 - Ver estado
/system script run check-dhcp-status

# En MK03 - Ver failover
/system script run ver-failover

# En cualquier dispositivo - Ver leases
/ip dhcp-server lease print where status=bound
```

---

## 7. Seguridad y Firewall

### 7.1 Reglas Firewall MK01

#### Chain INPUT
| # | Acción | Descripción | Match |
|---|--------|-------------|-------|
| 1 | accept | Conexiones establecidas | state=established,related |
| 2 | accept | ICMP Echo Request | icmp-options=8:0 |
| 3 | accept | Desde VLAN Management | src=10.200.1.0/24 |
| 4 | accept | Desde VLANs Corporativas | src=192.168.0.0/16 |
| 5 | log | Log dropped | prefix="DROP-INPUT:" |
| 6 | drop | Resto | — |

#### Chain FORWARD
| # | Acción | Descripción | Match |
|---|--------|-------------|-------|
| 1 | accept | Conexiones establecidas | state=established,related |
| 2 | fasttrack | Fast-track established | state=established,related |
| 3 | drop | Paquetes inválidos | state=invalid |
| 4 | accept | CCTV → Servers | src=201, dst=10 |
| 5 | accept | Servers → CCTV | src=10, dst=201 |
| 6 | drop | Guest → Corporativo | src=96, dst=192.168.0.0/16 |
| 7 | drop | Corporativo → Guest | src=192.168.0.0/16, dst=96 |
| 8 | accept | Guest → Internet | src=96, out=ether1-wan |
| 9 | drop | CCTV → Internet | src=201, dst=!192.168.0.0/16 |
| 10 | accept | Inter-VLAN | src=192.168.0.0/16, dst=192.168.0.0/16 |
| 11 | accept | Corporativo → Internet | src=192.168.0.0/16, out=ether1-wan |
| 12 | log | Log dropped | prefix="DROP-FORWARD:" |
| 13 | drop | Resto | — |

### 7.2 Matriz de Comunicación

| Origen \ Destino | VLAN 10 | VLAN 20 | VLAN 90 | VLAN 96 | VLAN 201 | Internet |
|------------------|---------|---------|---------|---------|----------|----------|
| **VLAN 10** | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| **VLAN 20** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **VLAN 90** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **VLAN 96** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **VLAN 201** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |

### 7.3 Perfiles de Seguridad Wireless

| Perfil | Uso | Auth | Clave |
|--------|-----|------|-------|
| ptp-secure | Enlace PTP 8km | WPA2-PSK | PtP.Magdalena.Campo.2025!Secure |
| ptmp-campo | Red PTMP Campo | WPA2-PSK | PtMP.Campo.AgroTech.2025!Secure |
| agrotech-private | WiFi Corporativa | WPA2-PSK | AgroTech.Secure.Private.2025! |
| agrotech-guest | WiFi Invitados | WPA2-PSK | AgroTech.Guest.2025! |

### 7.4 Servicios Deshabilitados

En todos los dispositivos:
- Telnet (tcp/23)
- FTP (tcp/21)
- API (tcp/8728)
- API-SSL (tcp/8729)

MAC-Server limitado a interface-list MGMT.

---

## 8. Scripts de Monitoreo

### 8.1 Scripts Globales

#### full-topology-check (MK01)
```routeros
# Ejecuta ping a todos los dispositivos
# Envía alerta por email si alguno está offline
# Scheduled: cada 1 hora
```

#### ping-topology-test (MK02)
```routeros
# Test conectividad desde hub
# Verifica: MK01, SXT-MG, SXT-CA, MK03, MK04, MK05, MK06
# Scheduled: cada 1 hora
```

### 8.2 Scripts de Diagnóstico

| Script | Dispositivo | Función |
|--------|-------------|---------|
| check-qinq | MK01 | Estado encapsulación Q-in-Q |
| check-qinq-transport | MK02 | Estado transporte Q-in-Q |
| check-bridges | MK02 | Estado de todos los bridges |
| check-ptp-status | SXT-MG | Estado enlace PTP |
| check-signal | SXT-MG/CA | Métricas señal wireless |
| check-ptmp-clients | MK03 | Clientes PTMP registrados |
| check-connection | MK04/05/06 | Estado conexión PTMP |

### 8.3 Scripts de Verificación DHCP

| Script | Dispositivo | Función |
|--------|-------------|---------|
| check-dhcp-status | MK01 | Estado servidores DHCP |
| ver-failover | MK03 | Estado failover DHCP |
| test-failover | MK03 | Simular caída MK01 |
| ver-leases | MK03 | Leases DHCP activos |

### 8.4 Ejecución de Scripts

```routeros
# Ejecutar script manualmente
/system script run <nombre-script>

# Ver scripts disponibles
/system script print

# Ver log de ejecución
/log print where topics~"script"
```

---

## 9. Procedimientos de Despliegue

### 9.1 Pre-requisitos

1. **Hardware verificado**: Todos los equipos MikroTik encendidos y accesibles
2. **Cableado**: UTP Cat5e mínimo, conectores verificados
3. **Acceso físico**: Para configuración inicial via MAC-Winbox
4. **Archivos**: Configuraciones .rsc disponibles

### 9.2 Reset de Equipos

```routeros
# Opción 1: Via consola
/system reset-configuration no-defaults=yes skip-backup=yes

# Opción 2: Botón físico
# Mantener RESET durante boot hasta que el LED parpadee
```

### 9.3 Orden de Despliegue

```
FASE 1: Core
├── 1. MK01 (Gateway central)
└── 2. MK02 (Hub Magdalena)

FASE 2: Enlace PTP
├── 3. SXT-MG (AP - lado Magdalena)
└── 4. SXT-CA (Station - lado Campo)

FASE 3: Campo
├── 5. MK03 (Gateway campo / PTMP Master)
├── 6. MK04 (PTMP Station - Centro Datos)
├── 7. MK05 (PTMP Station - Galpón)
└── 8. MK06 (PTMP Station - AP Extra)
```

### 9.4 Importación de Configuración

```routeros
# 1. Conectar via MAC-Winbox al equipo reseteado

# 2. Subir archivo .rsc via Files

# 3. Importar configuración
/import file=MKxx_051225_V7.rsc

# 4. Verificar importación
/log print

# 5. Verificar identidad
/system identity print
```

### 9.5 Verificación Post-Despliegue

```routeros
# 1. Verificar IP management
/ip address print

# 2. Verificar conectividad básica
/ping 10.200.1.1 count=5

# 3. Verificar VLANs
/interface vlan print
/interface bridge vlan print

# 4. Verificar wireless (si aplica)
/interface wireless print
/interface wireless registration-table print

# 5. Test completo (desde MK01)
/system script run test-full-connectivity
```

---

## 10. Troubleshooting

### 10.1 Problemas Comunes

#### Sin conectividad a sitio remoto

```routeros
# 1. Verificar enlace PTP
# En SXT-MG:
/interface wireless registration-table print

# 2. Verificar bridges
# En MK02:
/interface bridge port print
/interface bridge host print

# 3. Verificar VLANs
/interface bridge vlan print
```

#### DHCP no asigna IPs

```routeros
# 1. Verificar servidor activo
/ip dhcp-server print

# 2. Verificar pool disponible
/ip pool print

# 3. Verificar network
/ip dhcp-server network print

# 4. Verificar VLAN tagging
/interface bridge vlan print where vlan-ids=<vlan>
```

#### Pérdida de paquetes en enlace PTP

```routeros
# En SXT-MG o SXT-CA:
/interface wireless monitor wlan1

# Métricas a revisar:
# - signal-strength: > -70 dBm ideal
# - tx-ccq: > 80% ideal
# - noise-floor: < -95 dBm ideal
```

### 10.2 Comandos de Diagnóstico

```routeros
# Estado general del sistema
/system resource print

# Interfaces y tráfico
/interface print stats

# Log del sistema
/log print

# Conexiones activas
/ip firewall connection print

# ARP table
/ip arp print

# MAC addresses en bridge
/interface bridge host print

# Rutas activas
/ip route print where active=yes
```

### 10.3 Contacto de Soporte

- **Email**: protocolosinlambrica@gmail.com
- **SNMP**: Habilitado en todos los dispositivos
- **Log Prefix**: MK01, MK02, MK03, etc.

---

## Apéndice A: Archivos de Configuración

| Archivo | Dispositivo | Tamaño Aprox |
|---------|-------------|--------------|
| MK01_051225_V7.rsc | MK01-agrotech-lp-gw | 335 líneas |
| MK02_051225_V7.rsc | MK02-agrotech-mg-ap | 336 líneas |
| MK03_051225_V7.rsc | MK03-agrotech-ca-gw | 295 líneas |
| MK04_051225_V7.rsc | MK04-agrotech-cd-st | 129 líneas |
| MK05_051225_V7.rsc | MK05-agrotech-cc-st | 110 líneas |
| MK06_051225_V7.rsc | MK06-agrotech-ap-extra | 147 líneas |
| SXTMG_051225_V7.rsc | SXT-MG-PTP-AP | 138 líneas |
| SXTCA_051225_V7.rsc | SXT-CA-PTP-Station | 117 líneas |

---

## Apéndice B: Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| V7 | 2025-12-05 | Documentación completa, correcciones MK02 bridge |
| V6 | 2025-11-28 | Implementación DHCP failover |
| V5 | 2025-11-24 | Configuración Q-in-Q |
| V4 | 2025-11-20 | Setup inicial PTMP |
| V3 | 2025-11-15 | Configuración PTP 8km |
| V2 | 2025-11-10 | VLANs corporativas |
| V1 | 2025-11-01 | Setup inicial |

---

**Documento generado**: 2025-12-05  
**Versión**: 051225_V7  
**Autor**: Protocolos Inalámbricos  
**Contacto**: protocolosinlambrica@gmail.com
