### Análisis de los Resultados del Script "full-network-test"


#### Resumen Tabular de Resultados (de Code Execution)
Usé Python para extraer y tabular pings (OK si >0 respuestas, FAIL si 100% loss; RTT avg donde aplica). Tabla de management VLAN 999:

| IP (Dispositivo)    | MK01 (La Plata) | MK02 (Magdalena) | MK03 (Campo Master) | MK04 (Centro Datos) | MK05 (Galpón) | MK06 (AP Extra) |
|---------------------|-----------------|------------------|---------------------|---------------------|---------------|-----------------|
| 10.200.1.1 (MK01)   | OK (0ms)       | OK (0ms)        | FAIL (100%)        | FAIL (100%)        | FAIL (100%)  | FAIL (100%)    |
| 10.200.1.10 (MK02)  | OK (0ms)       | OK (0ms)        | OK (9ms)           | OK (49ms)          | OK (8ms)     | OK (14ms)      |
| 10.200.1.20 (MK03)  | OK (224ms, 50% loss) | FAIL (100%)   | OK (0ms)           | OK (4ms)           | OK (2ms)     | OK (9ms)       |
| 10.200.1.21 (MK04)  | FAIL (100%)    | OK (41ms, 50% loss) | FAIL (100%)      | OK (0ms)           | OK (4ms)     | OK (8ms)       |
| 10.200.1.22 (MK05)  | FAIL (100%)    | FAIL (100%)     | OK (5ms)           | OK (18ms)          | OK (0ms)     | OK (8ms)       |
| 10.200.1.25 (MK06)  | FAIL (100%)    | OK (18ms, 50% loss) | OK (5ms)       | OK (12ms)          | OK (20ms)    | OK (0ms)       |
| 10.200.1.50 (SXT-MG)| FAIL (100%)    | OK (1ms, 50% loss) | OK (29ms)        | OK (16ms)          | OK (20ms)    | OK (17ms)      |
| 10.200.1.51 (SXT-CA)| FAIL (100%)    | OK (28ms, 50% loss) | OK (0ms)       | OK (13ms)          | OK (7ms)     | OK (7ms)       |
| **OK Total**        | **3/8**        | **6/8**         | **6/8**            | **7/8**            | **7/8**      | **7/8**        |
| **Internet (DNS)**  | OK (9-10ms)    | FAIL (100%)     | FAIL (100%)        | FAIL (100%)        | FAIL (100%)  | FAIL (100%)    |
| **VLAN Gateways**   | All OK         | All OK (unexpected) | All FAIL       | All FAIL           | All FAIL     | All FAIL       |
| **Uptime/CPU/Mem**  | 9h/7%/99MB     | 2h/7%/100MB     | 9h/4%/97MB         | 9h/6%/100MB        | 9h/6%/102MB  | 9h/4%/102MB    |

- **Observaciones Generales:**
  - **Management VLAN 999:** Cobertura parcial. Sitios locales responden bien (bajo RTT <10ms), pero cross-sitio fallan o tienen pérdida (50-100%). Desde La Plata (MK01), solo ~38% éxito; desde Campo, ~88% éxito intra-Campo pero FAIL a MK01.
  - **VLAN Gateways:** Alcanzables solo en MK01/MK02 (loopback/local). En MK03-06, FAIL esperado (backup no activo). En MK02, "Alcanzable" es anómalo – posible loop en bridge o ruta estática permitiendo acceso a gateways de MK01 via Q-in-Q.
  - **Internet:** Solo OK en MK01 (WAN directo). FAIL en todos los demás – indica NAT/firewall en MK01 no forwarding correctamente, o rutas default fallando en remotos.
  - **Sistema/Interfaces:** Estable (uptime ~9h en la mayoría, CPU <7%, mem >97MB). Tráfico moderado (MBs acumulados), sin overload. MK02 uptime bajo (2h) sugiere reboot reciente.

#### Identificación de Problemas y Causas Probables
Basado en outputs, topología (diagrama confirma PTP 8km como bottleneck), y web search (forum.mikrotik.com: NV2 loss común por interferencia 2.4GHz, distancia mal configurada – aquí 8000m OK, pero chequea Fresnel zone; fixes: Ajusta tx-power, cambia freq si ruido).

1. **Alta Pérdida en Enlace PTP (8km, SXT-MG/CA):**
   - Evidencia: Desde MK01/MK02, FAIL/50% loss a Campo (MK03-06). Desde Campo, FAIL a MK01 pero OK a SXTs/MK02 (tráfico upstream falla más).
   - Causas: Interferencia rural (maquinaria agro, 2.4GHz saturado), alineación antenas pobre, multipath (campo abierto), o obstrucción Fresnel. RTT alto (224ms en MK01 a MK03) indica congestión/retries en NV2.
   - Impacto: Rompe end-to-end para VLANs 10/20/90 (pings entre PCs en La Plata-Campo fallarían similarmente).

2. **Fallos en Internet desde Remotos:**
   - Evidencia: DNS FAIL en MK02-06 (timeout).
   - Causas: Ruta default via 10.200.1.1 OK, pero posible firewall drop en MK01 (chain=forward no permite), NAT masq solo local, o MTU/MSS issues en Q-in-Q (1590 configurado, pero clamp-to-pmtu podría fallar en lossy links).
   - Impacto: Sitios remotos sin WAN; solo intra-VLAN.

3. **Pérdidas Parciales (50%):**
   - Evidencia: Muchos pings con 1/2 respuestas (ej. MK02 a MK04: 50% loss, 41ms).
   - Causas: Inestabilidad wireless (NV2 sensible a noise-floor >-95dBm), o buffer overflow en RB951 (CPU baja).



