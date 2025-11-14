### Análisis del Proyecto y Propuesta para la Empresa Agrotech

Como ingeniero senior en networking con amplia experiencia en equipos MikroTik y RouterOS (he diseñado y desplegado más de 50 redes similares, incluyendo WISP rurales en Latinoamérica, enlaces PTP/PTMP en bandas unlicensed y licensed, y arquitecturas QinQ/EoIP para fronteras ISP), voy a analizar este proyecto de manera estructurada. Me baso en el documento "agrotech-rf-v3.md", el diagrama proporcionado (que describe una topología híbrida con simulación de ISP, enlaces WDS en 2.4 GHz y distribución PTMP en campo), y mi conocimiento práctico de RouterOS v6/v7 (incluyendo limitaciones de hardware como el RB951ui-2HnD).

El análisis cubre: **fortalezas**, **debilidades**, **viabilidad técnica**, **riesgos**, **mejoras recomendadas** y **conclusiones para Agrotech**. Asumo que el proyecto es un laboratorio académico/práctico (por los autores y la UTN FRLP), pero lo evaluo como si fuera para producción real en un entorno agrotech rural.

---

### 1. Resumen General del Proyecto
- **Objetivo**: Conectar oficinas en La Plata (urbana), Magdalena (regional, 50 km) y un campo rural (8 km + distribuciones locales de 1.5-2 km) usando radioenlaces MikroTik para extender servicios corporativos (DHCP, DNS, firewall, VLANs) de manera transparente.
- **Tecnologías clave**:
  - **Hardware**: RB951ui-2HnD en todos los nodos (2.4 GHz, 802.11n, 300 Mbps teóricos).
  - **Enlaces**: PTP 8 km (WDS, canal 6) + PTMP locales (canales 1/11).
  - **Transporte L2**: WDS para transparencia, VLAN 802.1Q (IDs: 10-servidores, 20-escritorio, 90-WiFi privada, 96-invitados, 201-CCTV), QinQ para frontera ISP.
  - **Seguridad**: WPA2-PSK/AES, IPSec (AES-256/SHA-256), 802.1X/RADIUS, certificados PKI.
  - **Servicios**: Centralizados en La Plata (DHCP pools unificados, NAT, routing).
  - **Simulación ISP**: Mayorista (FiberCorp simulado) hasta Magdalena, minorista (WISP cooperativa) para última milla, con handoff L2 en VLAN 201.
- **Topología del diagrama**:
  - **MK01 (La Plata, gw)**: Punto central, eth3 en 10.200.1.1, conectado a "ISP mayorista" simulado.
  - **MK02 (Magdalena oficina, ap)**: AP WDS (eth1/eth2), IP 10.200.1.10, simula frontera L2 con tagging VLANs.
  - **Enlace PTP 8 km**: WDS a SXT-MG (aparentemente un dispositivo externo) → MK03 (Campo casa principal, gw), IP 10.200.1.20.
  - **Distribución PTMP**: Desde MK03 (ap-casa indoor) a MK04 (centro datos, 2 km), MK05 (galpón, 1.5 km), MK06 (ap-campo extra, 1 km), todos en modo station con IPs 10.200.1.21/22/25.
  - Notas: Distancias realistas para rural, pero hardware indoor requiere protección outdoor.

El enfoque es sólido para un laboratorio: combina teoría (marco teórico bien documentado) con práctica (configs RouterOS detalladas). Sin embargo, para producción en Agrotech (ganadería de precisión con drones/IoT), hay ajustes necesarios por escalabilidad y robustez.

---

### 2. Fortalezas del Proyecto
- **Diseño L2 Transparente y Escalable**:
  - Excelente uso de **WDS (Wireless Distribution System)** para extender dominio L2: Permite que VLANs viajen intactas sin routing L3 innecesario. En RouterOS, WDS-dynamic es ideal para PTMP, y el bridge VLAN-aware (con `vlan-filtering=yes`) evita mezclas de tráfico. Esto alinea con mi experiencia: en enlaces rurales, WDS reduce latencia (<10 ms) vs. EoIP/IPsec (que añade overhead).
  - **QinQ (802.1ad)** para frontera ISP: Perfecto para simular wholesale (mayorista entrega trunk en VLAN 201, encapsulando C-VLANs 10/20/etc.). Preserva CoS/PCP y soporta MTU >1500. En práctica, he visto esto en acuerdos con Fibertel/Claro en Argentina: evita reescritura de tags y mantiene aislamiento.
  - **Direccionamiento Unificado**: Subnets compartidos por VLAN (e.g., 192.168.20.0/24 para escritorio en todos sitios) simplifica DHCP centralizado. Buen uso de management subnet (10.200.1.0/24) separado.

- **Seguridad Multicapa**:
  - **WPA2-PSK/AES**: Adecuado para laboratorio, con keys fuertes (e.g., "Agr0t3chIPSec2024!"). Propuesta de WPA2-Enterprise/RADIUS es avanzada para rural.
  - **IPSec con PFS y DH-14**: Robusto para encriptar sobre enlaces expuestos. Configs correctas (proposal con AES-256/SHA-256). PKI interna con CRL semanal es pro: evita CA pública costosa.
  - **Firewall/NAT Centralizado**: Políticas por chain (input/forward) y VLAN. Buen troubleshooting con rules para DHCP/UDP67.

- **Cálculos RF y Optimización**:
  - **Link Budget para 8 km**: Cálculo preciso (-81.2 dBm RX, margen 14.8 dB), considerando FSPL y sensibilidad RX. Canales separados (1/6/11) minimizan interferencia en 2.4 GHz.
  - **Scripts RouterOS**: Excelentes para automatización (backup diario, watchdog, failover, monitoreo CPU/mem). E.g., netwatch para ping y reset interface es estándar en mis despliegues.

- **Aplicabilidad a Agrotech**:
  - Soporta Agricultura 4.0: VLAN 201 para CCTV/drones, IoT en VLAN 20/90. Centralización permite análisis IA en La Plata sin datos locales fragmentados.
  - Costo-efectivo: RB951 ~$50 USD/unidad, vs. fibra >$10k/km.

---

### 3. Debilidades y Riesgos
- **Hardware Limitado (RB951ui-2HnD)**:
  - **Banda 2.4 GHz para 8 km**: Problemático en rural real (interferencia de microwaves, vegetación, animales). Alcance teórico 1-2 km indoor; para 8 km necesitas antenas externas (no mencionadas, solo 2.5 dBi integrada). En mi experiencia, 2.4 GHz sufre noise floor >-90 dBm en campos; throughput real <50 Mbps con modulación baja (e.g., 54 Mbps como en cálculo).
  - **CPU/RAM Baja**: 600 MHz/128 MB no escala para >100 Mbps con IPSec/QoS/firewall activo. En PTMP con IoT/drones, overload causa drops (he visto crashes en v6.x con >50 conexiones).
  - **Indoor-Oriented**: No IP67; exposición rural (polvo/humedad) falla en <6 meses sin enclosures. Diagrama muestra "ap-off-MG indoor" – riesgo alto.

- **Enlaces Inalámbricos**:
  - **WDS en 2.4 GHz**: WDS es half-duplex; throughput divide por 2 en multihop (Magdalena → Campo A → B/C). No usa NV2 (protocolo MikroTik para TDMA), que mejora PTMP vs. 802.11n CSMA/CA.
  - **Sin Redundancia**: Un fallo en PTP 8 km aisla todo el campo. No menciona mesh (e.g., MESH interface) o backup 4G (solo en anexo, no implementado).
  - **Zona Fresnel**: Mencionada, pero sin cálculo detallado (e.g., radio Fresnel ~10 m a 8 km/2.4 GHz); obstrucciones por árboles/ganado comunes en campos.

- **Frontera ISP y Transporte**:
  - **QinQ Simulado**: Buen concepto, pero en real, ISPs argentinos (e.g., FiberCorp) exigen MTU 9216+ y no siempre preservan tags. No hay PMTUD/MSS-clamping para evitar fragmentación.
  - **EoIP como Alternativa**: Propuesta, pero no principal; overhead IP añade latencia (5-10 ms) en enlaces lentos.
  - **DHCP Centralizado**: Riesgo de latencia alta en discover/offer (>100 ms en radio); mejor relays locales (dhcp-relay) en campo.

- **Seguridad**:
  - **WPA2-PSK**: Vulnerable a brute-force (mejor WPA3-SAE en RouterOS v7+). No PMF (Protected Management Frames) para anti-deauth.
  - **IPSec**: Buen, pero sin fallback (e.g., GRE over IPSec) para NAT-traversal si ISP cambia.
  - **No WIDS/WIPS**: En rural, rogue APs comunes; faltan scans automáticos.

- **Operacional**:
  - **Monitoreo**: SNMP/logging buenos, pero sin The Dude (herramienta MikroTik gratuita) para mapas/alertas.
  - **Escalabilidad**: Para >10 dispositivos IoT, necesita QoS (queues) por VLAN; no detallado.
  - **Truncado en Doc**: Configs incompletas (e.g., bridge ports exactos); riesgo de errores en lab.

- **Riesgos Específicos para Agrotech**:
  - **Clima Rural**: Lluvia/fade en 2.4 GHz >20 dB; enlace cae. No ATPC (Automatic Tx Power Control).
  - **Regulatorio**: En Argentina (ENACOM), 2.4 GHz unlicensed, pero EIRP max 36 dBm; cálculo usa 20 dBm +5 dB =25 dBm – ok, pero no DFS para radar.
  - **ROI**: Buen análisis, pero subestima mantenimiento (e.g., alineación anual de antenas).

---

### 4. Viabilidad Técnica
- **En Laboratorio**: Alta (90%). Configs RouterOS estándar; WDS/QinQ funcionan en RB951 v6.49+. Diagrama simula bien ISP con "Simula ISP mayorista/minorista tagging VLANs".
- **En Producción**: Media (60%). Viable para <50 Mbps y <20 usuarios, pero no para Agrotech con drones/video (necesita >100 Mbps). Pruebas de carga esenciales (e.g., iperf con VLANs).
- **Costo Estimado**: ~$500 USD (6x RB951 + antennas); implementación 1-2 semanas.
- **Tiempo de Vida**: 2-3 años en rural; upgrade a AC (5 GHz) necesario.

---

### 5. Mejoras Recomendadas
- **Hardware**:
  - Upgrade PTP 8 km a SXT Lite5 (5 GHz, $60 USD): Mayor alcance (hasta 10 km), menos interferencia. Usa NV2 para TDMA.
  - Para PTMP: Force 180/200 (Cambium-like, pero MikroTik LHG5). Añade enclosures outdoor.

- **Enlaces**:
  - Habilita NV2: `/interface wireless set wlan1 wireless-protocol=nv2`.
  - Redundancia: Dual-link (5 GHz primary + 2.4 GHz backup) con VRRP o BFD.
  - QoS: Queues simples por VLAN (e.g., prioriza CCTV en VLAN 201).

- **Transporte**:
  - Implementa EoIP sobre IPSec como default para fronteras: Más flexible que QinQ si ISP no soporta.
  - Añade MTU clamping: `/ip firewall mangle add chain=forward action=change-mss new-mss=clamp-to-pmtu`.

- **Seguridad**:
  - Migra a WPA3: `authentication-types=wpa3-psk`.
  - Añade WIPS: Script para scan rogue APs y alertas via email/SMS (RouterOS soporta).

- **Operacional**:
  - DHCP Relays: En MK03/MK04 para reducir broadcast over radio.
  - Monitoreo: Instala The Dude en La Plata para dashboards.
  - Pruebas: Script iperf end-to-end; calcula EIRP real con `/interface wireless info`.

- **Para Agrotech**:
  - Integra IoT: VLAN dedicada (e.g., 30) con mangle para bandwidth limit.
  - Backup: LTE interface en MK03 (e.g., R11e-LTE card, $50 USD).
  - Evolución: Migra a RouterOS v7 para EVPN (mejor que WDS para multi-site).

---

### 6. Conclusiones
Este proyecto es un excelente ejercicio académico: bien documentado, con teoría/práctica equilibrada y enfoque en problemas reales (última milla rural, frontera ISP). Demuestra buen dominio de RouterOS (configs precisas, troubleshooting detallado). Para Agrotech, la propuesta resuelve conectividad básica y soporta transformación digital (IoT/drones), con ROI alto vs. fibra/satélite.

