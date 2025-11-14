## 📊 ANÁLISIS TÉCNICO INTEGRAL - PROYECTO AGROTECH


### ✅ **COHERENCIA DOCUMENTACIÓN vs TOPOLOGÍA**

**Validación positiva:**
- La topología PDF coincide correctamente con la arquitectura descrita en el documento
- Los 6 dispositivos MikroTik están claramente identificados
- Las distancias (50km PTP, 8km entrada campo, 2km/1.5km PTMP) son consistentes
- El esquema de VLANs (10, 20, 90, 96, 201) está bien definido
- Red de gestión 10.200.1.0/24 correctamente documentada

**Observaciones críticas identificadas:**

### 🔴 **GAPS Y PUNTOS CRÍTICOS PARA LABORATORIO**

#### 1. **Q-in-Q: Falta especificación de S-VLAN**
```
Problema: El documento menciona "S-VLAN 201" pero la topología muestra VLAN 201 como CCTV
```
**Corrección necesaria:**
- **S-VLAN (Service VLAN)**: Debe ser diferente, ejemplo: **VLAN 4000**
- **C-VLANs (Customer VLANs)**: 10, 20, 90, 96, 201 ✓

**Configuración RouterOS 6.44-6.49:**
```routeros
# En MK01 (La Plata) - ether2 hacia ISP Mayorista
/interface vlan
add name=qinq-transport interface=ether2 vlan-id=4000 use-service-tag=yes

# Agregar C-VLANs dentro de la S-VLAN
/interface vlan
add name=vlan10-qinq interface=qinq-transport vlan-id=10
add name=vlan20-qinq interface=qinq-transport vlan-id=20
add name=vlan90-qinq interface=qinq-transport vlan-id=90
add name=vlan96-qinq interface=qinq-transport vlan-id=96
add name=vlan201-qinq interface=qinq-transport vlan-id=201
```

#### 2. **MTU 1590: Validación de toda la cadena**

**Puntos críticos:**
```
[MK01-ether2] --Q-in-Q--> [Switch L2] --Q-in-Q--> [MK02-ether2] ---> [SXT-MG] --PTP--> [SXT-CA] ---> [WDS]
    ↑                                                ↑                     ↑                              ↑
 MTU 1590                                        MTU 1590            MTU 1590?                      MTU 1590?
```

**Configuración completa MTU/L2MTU:**
```routeros
# En TODOS los dispositivos de la cadena troncal
/interface ethernet
set [ find where name~"ether[12]" ] l2mtu=1600 mtu=1590

# En interfaces wireless (SXT y PTMP)
/interface wireless
set [ find ] mtu=1590 l2mtu=1600

# Clamp MSS para TCP
/ip firewall mangle
add chain=forward protocol=tcp tcp-flags=syn \
    action=change-mss new-mss=clamp-to-pmtu comment="MSS Clamp Q-in-Q"
```

#### 3. **WDS + VLAN Filtering: Limitación crítica en 2.4GHz**

⚠️ **ALERTA IMPORTANTE para RouterOS 6.x:**
```
En RB951ui-2HnD (AR9344 chipset) con 2.4GHz:
- WDS funciona correctamente
- PERO: VLAN filtering en wireless puede causar drops de frames
- Solución: Usar bridge VLAN filtering en lugar de wireless-specific filtering
```

**Configuración recomendada:**
```routeros
# En MK03 (AP Master PTMP)
/interface wireless
set wlan1 mode=ap-bridge ssid=agrotech-ptmp \
    frequency=2437 channel-width=20mhz \
    wds-mode=static wds-default-bridge=bridge-local \
    security-profile=wpa2-psk

# NO usar wireless.vlan-mode, usar bridge VLAN filtering
/interface bridge
add name=bridge-local vlan-filtering=yes

/interface bridge port
add bridge=bridge-local interface=wlan1
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=ether5

/interface bridge vlan
add bridge=bridge-local vlan-ids=10,20,90,96,201 tagged=wlan1,ether1
add bridge=bridge-local vlan-ids=90,96 untagged=ether4,ether5
```

#### 4. **Direccionamiento de gestión: Falta gateway y VLAN**

**Problema identificado:**
```
IPs de gestión: 10.200.1.x/24
Pero: ¿En qué VLAN viajan? ¿Cómo se enrutan?
```

**Solución propuesta:**
```routeros
# Crear VLAN 99 para gestión (nueva)
/interface vlan
add name=vlan99-mgmt interface=bridge-local vlan-id=99

# IP de gestión en cada equipo
/ip address
add address=10.200.1.X/24 interface=vlan99-mgmt

# Gateway hacia MK01
/ip route
add dst-address=0.0.0.0/0 gateway=10.200.1.1
```

#### 5. **Seguridad WPA2: Falta especificación de algoritmo**

**Configuración completa security profile:**
```routeros
/interface wireless security-profiles
add name=wpa2-psk \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="ClaveSegura2024!AgroTech"

# Para PTP (SXT)
add name=wpa2-ptp \
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm \
    group-ciphers=aes-ccm \
    wpa2-pre-shared-key="PTP-50km-SecureLink-2024!"
```

### 📋 **VALIDACIÓN DE REQUERIMIENTOS**

| ID | Requerimiento | Estado | Observaciones |
|---|---|---|---|
| RF-01 | Conectividad E2E | ✅ | OK con routing correcto |
| RF-02 | Segregación 5 VLANs | ⚠️ | Falta VLAN gestión (99) |
| RF-03 | Transporte L2 Q-in-Q | ⚠️ | S-VLAN no definida claramente |
| RF-04 | Servicios centralizados | ✅ | OK con DHCP relay |
| RF-05 | NAT centralizado | ✅ | OK en MK01 |
| RNF-01 | WPA2-PSK/WPA3 | ⚠️ | WPA3 no soportado en 6.49 |
| RNF-02 | Firewall L3 | ✅ | Implementable |
| RNF-03 | SNMP/NTP/Logging | ✅ | OK |
| RNF-04 | MTU 1590 | ⚠️ | Requiere validación en SXT |

### 🎯 **ARQUITECTURA CORREGIDA PARA LABORATORIO**

```
PROPUESTA DE S-VLAN:
─────────────────────────────────────────────────────────────
Segmento              │  Tecnología        │  Encapsulamiento
─────────────────────────────────────────────────────────────
MK01-ether2           │  802.1ad Q-in-Q    │  S-VLAN 4000 + C-VLANs
  ↓
Switch L2 (ISP Mayor) │  Transparente L2   │  Mantiene doble tag
  ↓
MK02-ether2           │  802.1ad Q-in-Q    │  Desencapsula S-VLAN
  ↓
SXT-MG (ether1)       │  802.1Q estándar   │  Solo C-VLANs
  ↓
[Radioenlace 50km]    │  WPA2 + 802.11n    │  Frame WiFi + C-VLANs
  ↓
SXT-CA (ether1)       │  802.1Q estándar   │  Solo C-VLANs
  ↓
MK04-eth1             │  WDS Transparente  │  Bridge L2
  ↓
MK03 (PTMP Master)    │  WDS + VLAN Filter │  Bridge VLAN filtering
  ↓
MK05/MK06 (Stations)  │  WDS Client        │  Reciben todas VLANs
─────────────────────────────────────────────────────────────
```

### 🔧 **PLAN DE IMPLEMENTACIÓN LABORATORIO**

**FASE 1: Configuración Base (Día 1)**
1. Reset factory todos los equipos
2. Actualizar a RouterOS 6.49.17 (última estable 6.x)
3. Configurar IPs de gestión VLAN 99
4. Habilitar SSH, deshabilitar telnet/MAC-telnet
5. Backup inicial

**FASE 2: Q-in-Q La Plata ↔ Magdalena (Día 2)**
1. Configurar MK01 con S-VLAN 4000 en ether2
2. Configurar MK02 con S-VLAN 4000 en ether2
3. Validar con `/tool sniffer` capturando doble tag
4. Test de ping entre VLANs

**FASE 3: Radioenlace PTP (Día 3)**
1. Configurar SXT-MG y SXT-CA como PTP
2. Alinear con atenuadores (simula 50km)
3. Validar throughput mínimo 50Mbps
4. Configurar cifrado WPA2

**FASE 4: WDS PTMP Campo (Día 4)**
1. Configurar MK03 como AP Master
2. Configurar MK05/MK06 como WDS Stations
3. Implementar bridge VLAN filtering
4. Test de conectividad todas las VLANs

**FASE 5: Servicios y Seguridad (Día 5)**
1. DHCP Server en MK01 con pools por VLAN
2. DHCP Relay en todos los equipos remotos
3. Firewall rules por VLAN
4. NAT en MK01

---
