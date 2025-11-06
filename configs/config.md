# Análisis de la Propuesta de Implementación de Radioenlaces para Agrotech

## Resumen del Análisis
La propuesta presentada en los documentos "implementacion.md" y "agrotech-rf-v2.md", junto con el diagrama de red proporcionado, describe un laboratorio indoor académico para simular una red distribuida en una empresa agrotech. Utiliza equipos MikroTik RB951ui-2HnD en banda 2.4 GHz para radioenlaces PtP/PtMP, transporte de VLANs (10: servidores, 20: hosts escritorio, 90: WiFi privada, 96: WiFi invitados, 201: videovigilancia) y subcontratación ISP de última milla. 

**Fortalezas:**
- Enfoque en WDS para transparencia L2, ideal para VLANs extremo a extremo.
- Centralización de servicios (DHCP, DNS, firewall) en La Plata para simplicidad.
- Seguridad robusta con WPA2-PSK/AES, VLAN filtering y scripts de monitoreo.
- Simulación realista de frontera L2 entre ISP mayorista/minorista mediante bridging y tagging.
- Optimizaciones indoor: baja potencia TX (5-10 dBm) para evitar interferencias, canales separados (2412, 2437, 2462 MHz) para enlaces concurrentes.
- Métricas y troubleshooting detallados para validación experimental.

**Debilidades y Mejoras Sugeridas:**
- Inconsistencias en el diagrama: VLANs listadas como "20.96" (probablemente "20,96"), "VLAN 9" (probablemente "90"), "9,06" (probablemente "90,96"). Asumiré las VLANs originales del prompt: 10,20,90,96,201.
- Ausencia de Q-in-Q explícito en configs base; se sugiere agregar para frontera ISP real.
- No hay redundancia (e.g., VRRP o enlaces backup); agregar en producción.
- IPs de gestión en 10.200.1.0/24 podrían colisionar con VLANs; recomiendo VLAN de gestión dedicada (e.g., VLAN 200).
- Para campo rural real: calcular enlace RF con zona de Fresnel (para 8km en 2.4GHz, radio ~200m); usar antenas externas si RSSI < -70dBm.
- Escalabilidad: Limitado a 300Mbps teóricos; para video 201 priorizar QoS (queue simple/tree).
- Seguridad: Agregar RADIUS para WPA2-Enterprise en producción; IPSec para EoIP si exposición pública.

La propuesta es viable para lab académico (3-4 horas/semanas), pero en deployment real requeriría site survey RF, licencias regulatorias (ENACOM en Argentina) y UPS para resiliencia.

## Inventario Detallado de Conexiones
Basado en el diagrama y documentos, aquí un inventario completo. Asumo setup indoor con 6 dispositivos (MK01-MK06). Simulación ISP: Ether2 de MK01 como "uplink ISP" (cableado a switch para trunk VLANs). Radioenlaces via WDS en 2.4GHz (simulados con distancias cortas, baja TX power).

### 1. Dispositivos y Funciones
| ID    | Hostname          | Función Principal | Ubicación Simulada | Puertos Usados | IPs Principales | DHCP Pools |
|-------|-------------------|-------------------|--------------------|---------------|-----------------|------------|
| MK01 | agrotech-lp-gw   | Gateway central, DHCP/DNS/FW, trunk VLANs a ISP | La Plata | Ether1: Local hosts/servers; Ether2: Uplink ISP (trunk VLANs); Ether3: Gestión; Ether4-5: Expansión/PoE | 192.168.10.1/24 (VLAN10), 192.168.20.1/24 (VLAN20), etc.; Gestión: 10.200.1.1/24 | POOL-20: 192.168.20.10-100; POOL-90: 192.168.90.10-100; POOL-96: 192.168.96.10-100 |
| MK02 | agrotech-mg-ap   | AP WDS para frontera ISP, bridge a radio | Magdalena | Ether1: Local hosts; Ether2: Uplink ISP (trunk); Ether3: Gestión; Wlan1: WDS AP a MK03 | Gestión: 10.200.1.10/24 | Ninguno (centralizado) |
| MK03 | agrotech-ca-gw   | Station WDS + AP local, distribución campo | Campo A (Casa Ppal) | Ether1: Local hosts; Ether2: Expansión; Ether3: Gestión; Wlan1: WDS Station a MK02; Wlan2: AP a MK04; Wlan3: AP a MK05 | Gestión: 10.200.1.20/24 | Ninguno |
| MK04 | agrotech-cb-st   | Station WDS para datos drones/IA | Campo B (Centro Datos) | Ether1: Local hosts (drones); Ether2: Expansión; Ether3: Gestión; Wlan1: WDS Station a MK03 | Gestión: 10.200.1.21/24 | Ninguno |
| MK05 | agrotech-cc-st   | Station WDS para video/sensores | Campo C (Galpón) | Ether1: Local CCTV; Ether2: Expansión; Ether3: Gestión; Wlan1: WDS Station a MK03 | Gestión: 10.200.1.22/24 | Ninguno |
| MK06 | agrotech-ap-extra| AP WiFi adicional para cobertura local | Campo A Interior | Ether1: Uplink a MK03; Ether2: Local; Ether3: Gestión; Wlan1: AP WiFi (VLAN90/96) | Gestión: 10.200.1.25/24 | Ninguno |

### 2. Conexiones Cableadas y Puertos
- **Cableado General:** Todos usan Cat5e/6 UTP (1-2m en lab). PoE pasivo en Ether5 si expansión (e.g., switch extra). Alimentación: 24V 0.8A adapters.
- **MK01 (La Plata):**
  - Ether1: Conectado a switch local para hosts/servers (untagged VLAN20/10).
  - Ether2: Simula uplink ISP (cable a switch o directo a MK02 Ether2 para trunk VLANs 10,20,90,96,201).
  - Ether3: Gestión (cable a laptop para Winbox/SSH).
  - Ether4: Reserva para expansión.
  - Ether5: PoE out si switch adicional.
- **MK02 (Magdalena):**
  - Ether1: Local hosts regionales (untagged VLAN20).
  - Ether2: Uplink de ISP (cable desde MK01 Ether2 o switch simulado; trunk VLANs).
  - Ether3: Gestión.
  - Wlan1: Radio a MK03 (WDS dinámico).
- **MK03 (Campo A):**
  - Ether1: Local hosts (untagged VLAN20).
  - Ether2: Conexión a MK06 Ether1 (cable para AP extra).
  - Ether3: Gestión.
  - Wlan1: Station WDS a MK02 (SSID: AGROTECH-BACKBONE, freq 2437).
  - Wlan2: AP WDS a MK04 (SSID: LINK-CAMPO-B, freq 2462).
  - Wlan3: AP WDS a MK05 (SSID: LINK-CAMPO-C, freq 2412).
- **MK04 (Campo B):**
  - Ether1: Hosts drones/IA (untagged VLAN10/201).
  - Ether2: Expansión.
  - Ether3: Gestión.
  - Wlan1: Station WDS a MK03 Wlan2 (SSID: LINK-CAMPO-B).
- **MK05 (Campo C):**
  - Similar a MK04: Ether1 para CCTV (VLAN201), Wlan1 a MK03 Wlan3 (SSID: LINK-CAMPO-C).
- **MK06 (AP Extra):**
  - Ether1: Uplink cable a MK03 Ether2.
  - Ether2: Local.
  - Ether3: Gestión.
  - Wlan1: AP WiFi (SSID: AgroTech-Lab, freq 2452; VLAN90/96).

### 3. Configuraciones de Red Lógicas
- **VLANs:** Transportadas en trunks: 10 (servidores), 20 (escritorio), 90 (WiFi priv), 96 (WiFi guest), 201 (CCTV). Bridges VLAN-aware en todos.
- **WDS:** Dinámico, security WPA2-PSK "LabWDS2025!". Protocolo: 802.11n (Nv2 opcional para PtP).
- **IPs y Subnets:** VLAN10: 192.168.10.0/24; VLAN20: 192.168.20.0/24; VLAN90: 192.168.90.0/24; VLAN96: 192.168.96.0/24; VLAN201: 192.168.201.0/24. Gestión: 10.200.1.0/24 (untagged en Ether3).
- **DHCP:** Centralizado en MK01. Servers por VLAN (disabled en remotos).
- **Bridges:** BR-MAIN (MK01), BR-WDS (MK02), BR-CAMPO (MK03), BR-CAMPO-B (MK04), BR-CAMPO-C (MK05), BR-LOCAL (MK06). VLAN-filtering=yes para aislamiento.
- **Seguridad:** WPA2-PSK AES en WDS/WiFi. Firewall: Drop no autorizado; NAT en MK01.
- **Monitoreo:** SNMPv3 enabled; Scripts para ping/bandwidth; Scheduler cada 5m.

## Scripts de Configuración Completos (CLI RouterOS)
Basados en documentos, completados y corregidos para consistencia. Ejecutar vía /import o copy-paste en terminal. Asume reset inicial.

### MK01: agrotech-lp-gw (Gateway La Plata)
```
/system identity set name=agrotech-lp-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="laboratorio@universidad.edu"
/interface bridge add name=BR-MAIN vlan-filtering=yes
/interface vlan add interface=ether2 name=VLAN10-Servidores vlan-id=10
/interface vlan add interface=ether2 name=VLAN20-Escritorio vlan-id=20
/interface vlan add interface=ether2 name=VLAN90-WiFi-Priv vlan-id=90
/interface vlan add interface=ether2 name=VLAN96-WiFi-Guest vlan-id=96
/interface vlan add interface=ether2 name=VLAN201-CCTV vlan-id=201
/interface bridge port add bridge=BR-MAIN interface=ether2
/interface bridge port add bridge=BR-MAIN interface=VLAN10-Servidores
/interface bridge port add bridge=BR-MAIN interface=VLAN20-Escritorio
/interface bridge port add bridge=BR-MAIN interface=VLAN90-WiFi-Priv
/interface bridge port add bridge=BR-MAIN interface=VLAN96-WiFi-Guest
/interface bridge port add bridge=BR-MAIN interface=VLAN201-CCTV
/interface bridge vlan add bridge=BR-MAIN tagged=ether2 vlan-ids=10,20,90,96,201
/ip address add address=192.168.10.1/24 interface=VLAN10-Servidores
/ip address add address=192.168.20.1/24 interface=VLAN20-Escritorio
/ip address add address=192.168.90.1/24 interface=VLAN90-WiFi-Priv
/ip address add address=192.168.96.1/24 interface=VLAN96-WiFi-Guest
/ip address add address=192.168.201.1/24 interface=VLAN201-CCTV
/ip address add address=10.200.1.1/24 interface=ether3 comment="Gestion"
/ip pool add name=POOL-10 ranges=192.168.10.10-192.168.10.100
/ip pool add name=POOL-20 ranges=192.168.20.10-192.168.20.100
/ip pool add name=POOL-90 ranges=192.168.90.10-192.168.90.100
/ip pool add name=POOL-96 ranges=192.168.96.10-192.168.96.100
/ip pool add name=POOL-201 ranges=192.168.201.10-192.168.201.100
/ip dhcp-server add name=DHCP-10 interface=VLAN10-Servidores address-pool=POOL-10 disabled=no
/ip dhcp-server add name=DHCP-20 interface=VLAN20-Escritorio address-pool=POOL-20 disabled=no
/ip dhcp-server add name=DHCP-90 interface=VLAN90-WiFi-Priv address-pool=POOL-90 disabled=no
/ip dhcp-server add name=DHCP-96 interface=VLAN96-WiFi-Guest address-pool=POOL-96 disabled=no
/ip dhcp-server add name=DHCP-201 interface=VLAN201-CCTV address-pool=POOL-201 disabled=no
/ip dhcp-server network add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=8.8.8.8
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8
/ip dhcp-server network add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=8.8.8.8
/ip dhcp-server network add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=8.8.8.8
/ip dhcp-server network add address=192.168.201.0/24 gateway=192.168.201.1 dns-server=8.8.8.8
/ip firewall nat add action=masquerade chain=srcnat out-interface=ether2
/ip firewall filter add action=drop chain=forward in-interface=!BR-MAIN comment="Isolate VLANs"
/system script add name=lab-monitor ... (copiar del documento)
/system scheduler add interval=5m name=lab-monitoring on-event=lab-monitor
```

### MK02: agrotech-mg-ap (AP WDS Magdalena)
```
/system identity set name=agrotech-mg-ap
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="laboratorio@universidad.edu"
/interface wireless security-profiles add name=WDS-Profile mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="LabWDS2025!"
/interface wireless set wlan1 band=2ghz-b/g/n channel-width=20mhz frequency=2437 mode=ap-bridge ssid="AGROTECH-BACKBONE" security-profile=WDS-Profile wds-mode=dynamic wds-default-bridge=BR-WDS tx-power=10
/interface bridge add name=BR-WDS vlan-filtering=yes
/interface bridge port add bridge=BR-WDS interface=wlan1
/interface bridge port add bridge=BR-WDS interface=ether2
/interface bridge vlan add bridge=BR-WDS tagged=wlan1,ether2 vlan-ids=10,20,90,96,201
/ip address add address=10.200.1.10/24 interface=ether3
/ip firewall filter add action=drop chain=forward in-interface=!BR-WDS
/system script add name=performance-test ... (copiar del documento)
```

### MK03: agrotech-ca-gw (Station WDS Campo A)
```
/system identity set name=agrotech-ca-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="laboratorio@universidad.edu"
/interface wireless security-profiles add name=WDS-Profile mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="LabWDS2025!"
/interface wireless set wlan1 mode=station-wds ssid="AGROTECH-BACKBONE" frequency=2437 security-profile=WDS-Profile wds-mode=dynamic wds-default-bridge=BR-CAMPO tx-power=10
/interface bridge add name=BR-CAMPO vlan-filtering=yes
/interface vlan add interface=BR-CAMPO name=VLAN10-Local vlan-id=10
/interface vlan add interface=BR-CAMPO name=VLAN20-Local vlan-id=20
/interface vlan add interface=BR-CAMPO name=VLAN90-Local vlan-id=90
/interface vlan add interface=BR-CAMPO name=VLAN96-Local vlan-id=96
/interface vlan add interface=BR-CAMPO name=VLAN201-Local vlan-id=201
/interface bridge port add bridge=BR-CAMPO interface=wlan1
/interface bridge port add bridge=BR-CAMPO interface=ether2
/interface bridge port add bridge=BR-CAMPO interface=VLAN10-Local
/interface bridge port add bridge=BR-CAMPO interface=VLAN20-Local
/interface bridge port add bridge=BR-CAMPO interface=VLAN90-Local
/interface bridge port add bridge=BR-CAMPO interface=VLAN96-Local
/interface bridge port add bridge=BR-CAMPO interface=VLAN201-Local
/interface bridge vlan add bridge=BR-CAMPO tagged=wlan1,ether2 vlan-ids=10,20,90,96,201
/interface wireless add master-interface=wlan1 name=wlan-to-B ssid="LINK-CAMPO-B" frequency=2462 tx-power=5 wds-mode=dynamic wds-default-bridge=BR-CAMPO security-profile=WDS-Profile
/interface wireless add master-interface=wlan1 name=wlan-to-C ssid="LINK-CAMPO-C" frequency=2412 tx-power=5 wds-mode=dynamic wds-default-bridge=BR-CAMPO security-profile=WDS-Profile
/interface bridge port add bridge=BR-CAMPO interface=wlan-to-B
/interface bridge port add bridge=BR-CAMPO interface=wlan-to-C
/ip address add address=10.200.1.20/24 interface=ether3
/ip firewall filter add action=drop chain=forward in-interface=!BR-CAMPO
```

### MK04: agrotech-cb-st (Station WDS Campo B)
```
/system identity set name=agrotech-cb-st
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="laboratorio@universidad.edu"
/interface wireless security-profiles add name=WDS-Profile mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="LabWDS2025!"
/interface wireless set wlan1 mode=station-wds ssid="LINK-CAMPO-B" frequency=2462 wds-mode=dynamic wds-default-bridge=BR-CAMPO-B tx-power=5 security-profile=WDS-Profile
/interface bridge add name=BR-CAMPO-B vlan-filtering=yes
/interface vlan add interface=BR-CAMPO-B name=VLAN10-B vlan-id=10
/interface vlan add interface=BR-CAMPO-B name=VLAN20-B vlan-id=20
/interface vlan add interface=BR-CAMPO-B name=VLAN90-B vlan-id=90
/interface vlan add interface=BR-CAMPO-B name=VLAN96-B vlan-id=96
/interface vlan add interface=BR-CAMPO-B name=VLAN201-B vlan-id=201
/interface bridge port add bridge=BR-CAMPO-B interface=wlan1
/interface bridge port add bridge=BR-CAMPO-B interface=ether2
/interface bridge port add bridge=BR-CAMPO-B interface=VLAN10-B
/interface bridge port add bridge=BR-CAMPO-B interface=VLAN20-B
/interface bridge port add bridge=BR-CAMPO-B interface=VLAN90-B
/interface bridge port add bridge=BR-CAMPO-B interface=VLAN96-B
/interface bridge port add bridge=BR-CAMPO-B interface=VLAN201-B
/interface bridge vlan add bridge=BR-CAMPO-B tagged=wlan1,ether2 vlan-ids=10,20,90,96,201
/ip address add address=10.200.1.21/24 interface=ether3
/ip firewall filter add action=drop chain=forward in-interface=!BR-CAMPO-B
```

### MK05: agrotech-cc-st (Station WDS Campo C)
```
/system identity set name=agrotech-cc-st
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="laboratorio@universidad.edu"
/interface wireless security-profiles add name=WDS-Profile mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="LabWDS2025!"
/interface wireless set wlan1 mode=station-wds ssid="LINK-CAMPO-C" frequency=2412 wds-mode=dynamic wds-default-bridge=BR-CAMPO-C tx-power=5 security-profile=WDS-Profile
/interface bridge add name=BR-CAMPO-C vlan-filtering=yes
/interface vlan add interface=BR-CAMPO-C name=VLAN10-C vlan-id=10
/interface vlan add interface=BR-CAMPO-C name=VLAN20-C vlan-id=20
/interface vlan add interface=BR-CAMPO-C name=VLAN90-C vlan-id=90
/interface vlan add interface=BR-CAMPO-C name=VLAN96-C vlan-id=96
/interface vlan add interface=BR-CAMPO-C name=VLAN201-C vlan-id=201
/interface bridge port add bridge=BR-CAMPO-C interface=wlan1
/interface bridge port add bridge=BR-CAMPO-C interface=ether2
/interface bridge port add bridge=BR-CAMPO-C interface=VLAN10-C
/interface bridge port add bridge=BR-CAMPO-C interface=VLAN20-C
/interface bridge port add bridge=BR-CAMPO-C interface=VLAN90-C
/interface bridge port add bridge=BR-CAMPO-C interface=VLAN96-C
/interface bridge port add bridge=BR-CAMPO-C interface=VLAN201-C
/interface bridge vlan add bridge=BR-CAMPO-C tagged=wlan1,ether2 vlan-ids=10,20,90,96,201
/ip address add address=10.200.1.22/24 interface=ether3
/ip firewall filter add action=drop chain=forward in-interface=!BR-CAMPO-C
```

### MK06: agrotech-ap-extra (AP Adicional Campo A)
```
/system identity set name=agrotech-ap-extra
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="laboratorio@universidad.edu"
/interface wireless security-profiles add name=WiFi-Profile mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm group-ciphers=aes-ccm wpa2-pre-shared-key="LabWiFi2025!"
/interface wireless set wlan1 mode=ap-bridge ssid="AgroTech-Lab" frequency=2452 security-profile=WiFi-Profile tx-power=5 band=2ghz-b/g/n channel-width=20mhz
/interface bridge add name=BR-LOCAL vlan-filtering=yes
/interface vlan add interface=BR-LOCAL name=VLAN90-Extra vlan-id=90
/interface vlan add interface=BR-LOCAL name=VLAN96-Extra vlan-id=96
/interface bridge port add bridge=BR-LOCAL interface=wlan1
/interface bridge port add bridge=BR-LOCAL interface=ether2
/interface bridge port add bridge=BR-LOCAL interface=ether1 pvid=1 comment="Uplink a MK03"
/interface bridge port add bridge=BR-LOCAL interface=VLAN90-Extra
/interface bridge port add bridge=BR-LOCAL interface=VLAN96-Extra
/interface bridge vlan add bridge=BR-LOCAL tagged=wlan1,ether1 vlan-ids=90,96
/ip address add address=10.200.1.25/24 interface=ether3
/ip firewall filter add action=drop chain=forward in-interface=!BR-LOCAL
```