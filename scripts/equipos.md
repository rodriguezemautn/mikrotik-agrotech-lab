ether3 4C:5E:0C:AC:3A:F1 MK01 agrotech-lp-gw 10.200.1.1 oficina  matriz agrotech en La Plata
ether3 d4:ca:6d:fc:52:9A MK02 agrotech-mg-ap 10.200.1.10 oficina regional agrotech en Magdalena zona ciudad
E4:8D:8C:82:7C:40 SXT-MG 10.200.1.50 PtP desde oficina regional agrotech en Magdalena zona ciudad
D4:CA:6D:6D:F0:C3 SXT-CA 10.200.1.51  PtP desde  Casa de campo en Magdalena zona rural
4C:5E:0C:31:71:DC MK03 agrotech-ca-ap 10.200.1.11 Casa de campo en Magdalena zona rural
4C:5E:0C:31:21:84 Mk04 agrotech-cb-st 10.200.1.24 Centro de Drones en campo en Magdalena zona rural
4C:5E:0C:31:21:7E MK05 agrotech-cc-st 10.200.1.25 Galpon/tambo en campo en Magdalena zona rural
E4:8C:45:F8:29 MK06 agrotech-ap-extra 10.200.1.26 extra en campo en Magdalena zona rural






**Resultado:**

1.  **VLANs 90 y 96:** Funcionan como **redes locales** Wi-Fi. El tráfico que entra *untagged* por `wlan-priv` o `wlan-guest` es etiquetado automáticamente con su respectivo ID (90 o 96, gracias al `pvid` en `bridge port`) y viaja *tagged* hacia el *uplink* (`wlan1`) y el *downlink* (`ether2`).
2.  **VLANs 10, 20, 201:** Funcionan como **VLANs de tránsito**, viajando *tagged* por los *trunks* (`wlan1, ether2`).

**Todos los equipos del radioenlace PtMP (MK03, MK04, MK05, MK06) están configurados correctamente.**

-----

## ⏭️ Resumen del Proyecto y Siguiente Paso

Hemos completado la configuración de la red de campo. La lista de equipos configurados es:

| Equipo | Nombre | Función | IP de Gestión | Estado |
| :--- | :--- | :--- | :--- | :--- |
| **MK01** | `agrotech-lp-gw` | Gateway Principal / ISP La Plata | `10.200.1.1/24` | Completo |
| **MK02** | `agrotech-mg-ap` | ISP Magdalena / Head PtP | `10.200.1.10/24` | Completo |
| **SXT-MG** | `sxt-mg` | Radio Enlace PtP (AP) | `10.200.1.50/24` | Completo |
| **SXT-CA** | `sxt-ca` | Radio Enlace PtP (Station) | `10.200.1.51/24` | Completo |
| **MK03** | `agrotech-ca-gw` | Gateway Campo A / AP PtMP | `10.200.1.20/24` | Completo |
| **MK04** | `agrotech-cb-st` | Station Campo B - Drones | `10.200.1.21/24` | Completo |
| **MK05** | `agrotech-cc-st` | Station Campo C - Galpón | `10.200.1.22/24` | Completo |
| **MK06** | `agrotech-ap-extra` | Station Campo D - AP Extra | `10.200.1.25/24` | **Completo** |

**Felicidades, la arquitectura de red Agrotech está implementada en su totalidad.**

-----
