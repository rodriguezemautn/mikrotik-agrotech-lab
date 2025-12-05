# Análisis y Validación de la Configuración Actual de MikroTik (Archivos .rsc)

Se ha realizado un análisis exhaustivo de los archivos de configuración (`.rsc`) proporcionados para los dispositivos MikroTik. La implementación actual presenta una estructura de red bien definida, pero con algunas **inconsistencias y puntos críticos** que deben ser validados y corregidos para asegurar la funcionalidad completa de la topología.

## 1. Resumen de Inconsistencias y Puntos Críticos

| Componente | Configuración Actual | Inconsistencia/Punto Crítico |
| :--- | :--- | :--- |
| **VLANs de Cliente (C-VLANs)** | 10, 20, 90, 96, 201 | Se están transportando **todas** las VLANs (incluyendo 10, 20, 201) a través del Q-in-Q, lo cual es **innecesario** y puede ser un riesgo de seguridad si no se requiere acceso a la VLAN 10 (Servidores) o 201 (CCTV) desde el campo. |
| **VLAN de Servicio (S-VLAN)** | VLAN 4000 | Se utiliza la VLAN 4000 como S-VLAN, en lugar de la VLAN 500 propuesta en el diseño inicial. Esto es solo un cambio de ID, pero debe ser consistente. |
| **VLAN de Gestión** | VLAN 999 (10.200.1.0/24) | Se utiliza la VLAN 999 para la gestión. **MK01** tiene IPs de Gateway duplicadas (ej. 192.168.10.1) en interfaces locales (`vlan10-local`) y Q-in-Q (`qinq-vlan10`), lo que causará problemas de enrutamiento. |
| **Radioenlaces PtP/PtMP** | Protocolo **NV2** y modo **Bridge** | Correcto. Se utiliza el modo bridge para el transporte transparente de VLANs, y NV2 para optimizar el rendimiento. |
| **DHCP** | Servidores DHCP en **MK01** para todas las VLANs. | Correcto. Se centraliza el DHCP en MK01. Sin embargo, **MK02** no tiene configurado el **DHCP Relay**, lo que impedirá que los clientes detrás de MK02 obtengan IP de MK01. |
| **MTU** | 1600 en interfaces físicas, 1590 en interfaces VLAN. | Correcto. El aumento del MTU es necesario para acomodar las etiquetas VLAN adicionales (Q-in-Q requiere 4 bytes extra, 1500 + 4 + 4 = 1508). Un MTU de 1590 es adecuado para el transporte. |

## 2. Análisis Detallado por Dispositivo

### 2.1. MK01-agrotech-lp-gw (La Plata Gateway)

| Configuración | Estado | Observación |
| :--- | :--- | :--- |
| **Q-in-Q** | Implementado | Utiliza `s-vlan-4000` sobre `ether2-isp`. Encapsula **VLANs 10, 20, 90, 96, 201, 999**. |
| **Inconsistencia VLANs** | Crítica | Se están transportando VLANs que no deberían cruzar el enlace (10, 20, 201). **Solo 90, 96 y 999 (Gestión) deberían ser encapsuladas** si el objetivo es solo extender el Wi-Fi y la gestión al campo. |
| **Direcciones IP** | Crítica | IPs de Gateway duplicadas (ej. `192.168.10.1/24`) asignadas a interfaces locales (`vlan10-local`) y a interfaces Q-in-Q (`qinq-vlan10`). Esto crea un conflicto de enrutamiento. **Solo una debe ser el Gateway.** |
| **Firewall** | Correcto | Reglas de seguridad bien definidas, incluyendo aislamiento para la VLAN 96 (Guest). |
| **Scripts** | Correcto | Scripts de monitoreo y backup implementados, incluyendo un `full-topology-check` que valida la conectividad de gestión. |

### 2.2. MK02-agrotech-mg-ap (Magdalena Ciudad AP/Q-in-Q Decapsulator)

| Configuración | Estado | Observación |
| :--- | :--- | :--- |
| **Q-in-Q** | Implementado | Desencapsula correctamente la `s-vlan-4000-in` en las C-VLANs. |
| **DHCP Relay** | **Ausente** | No se encontró configuración de `ip dhcp-relay`. Los clientes conectados a MK02 no podrán obtener IP de MK01. |
| **Radioenlace** | **Ausente** | No se encontró configuración de radioenlace (wlan1) en este dispositivo. El diagrama original muestra que MK02 se conecta al SXT-MG. La configuración de MK02 solo tiene `ether1-to-sxt` en el bridge, asumiendo que el SXT-MG está conectado a `ether1`. |
| **Rutas** | Correcto | Rutas estáticas definidas hacia las redes corporativas (192.168.x.x/24) a través de `10.200.1.1` (MK01). |

### 2.3. SXT-MG-PTP-AP (PtP AP) y SXT-CA-PTP-Station (PtP Station)

| Configuración | Estado | Observación |
| :--- | :--- | :--- |
| **Rol** | **Invertido** | **SXT-MG** está configurado como **AP** (`mode=ap-bridge`), y **SXT-CA** como **Station** (`mode=station-bridge`). **Esto es correcto** según la lógica de que el tráfico viene de MK02 (Magdalena Ciudad) y va hacia MK03 (Campo). |
| **Protocolo** | Correcto | Uso de `wireless-protocol=nv2` para optimizar el enlace. |
| **VLANs** | Correcto | Ambos están configurados como **Bridge L2 transparente** (`BR-PTP` con `vlan-filtering=yes`) y transportan todas las VLANs (10, 20, 90, 96, 201, 999) de forma etiquetada. |
| **Conexión** | Crítica | **SXT-MG** está configurado como AP, pero el diagrama original sugiere que MK02 es el punto de inicio del radioenlace. La configuración actual implica que **MK02 está conectado por cable al SXT-MG**, y el SXT-MG es el AP del PtP. Esto es una implementación válida, pero **SXT-MG** debería estar configurado como **Station Bridge** si MK02 es el punto de acceso. **La configuración actual es: MK02 (Q-in-Q Decap) -> SXT-MG (PtP AP) -> SXT-CA (PtP Station) -> MK03 (Campo GW).** |

### 2.4. MK03-agrotech-ca-gw (Magdalena Campo Gateway/PtMP AP)

| Configuración | Estado | Observación |
| :--- | :--- | :--- |
| **Conexión** | Crítica | El `ether1-ptp` (Trunk from SXT-CA) está en el `BR-CAMPO`. **SXT-CA** está configurado como **Station**, lo que significa que MK03 es el destino final del PtP. Sin embargo, el diagrama original sugiere que MK03 es el **Gateway de Campo**, lo que implica que debería tener la inteligencia de enrutamiento y DHCP Relay. |
| **VLANs** | Crítica | Se están creando interfaces locales para VLAN 10 y 20 (`ether4-servers`, `ether5-desktop`) con PVIDs 10 y 20, respectivamente. **Esto es incorrecto** si el objetivo es que los clientes obtengan IP de MK01. Además, **no hay DHCP Relay** configurado. |
| **PtMP** | Correcto | Configurado como **AP Master** (`wlan1` en `ap-bridge` con `wds-mode=dynamic` y `wireless-protocol=nv2`). |

### 2.5. MK04, MK05, MK06 (Estaciones PtMP)

| Configuración | Estado | Observación |
| :--- | :--- | :--- |
| **PtMP** | Correcto | Configurado como **Station Bridge** (`mode=station-bridge` con `wds-mode=dynamic` y `wireless-protocol=nv2`). |
| **VLANs** | Crítica | Se están creando PVIDs (ej. PVID 10 en `ether4-servers` de MK04) y PVID 20 en MK05. **Esto es incorrecto** si se espera que los clientes obtengan IP de MK01 a través de DHCP Relay. Además, **no hay DHCP Relay** configurado. |
| **VLAN 201** | Crítica | MK04 y MK05 tienen PVID 201 en `ether5-cctv`. La VLAN 201 es de CCTV y solo existe en La Plata. Transportarla al campo es innecesario y potencialmente un error de diseño. |

## 3. Plan de Pruebas de Conectividad de Extremo a Extremo

Para validar la topología y las correcciones necesarias, se propone el siguiente plan de pruebas, centrado en la accesibilidad de la red de gestión y el transporte de las VLANs de cliente.

### 3.1. Pruebas de Gestión (VLAN 999 - 10.200.1.0/24)

**Objetivo:** Verificar la accesibilidad de todos los dispositivos MikroTik desde el punto de gestión central (Área IT, conectado a MK02).

| Origen | Destino | Prueba | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| **Área IT (MK02)** | MK01 (10.200.1.1) | `ping` | Éxito (Valida Q-in-Q de Gestión) |
| **Área IT (MK02)** | SXT-MG (10.200.1.50) | `ping` | Éxito (Valida cable a SXT) |
| **Área IT (MK02)** | SXT-CA (10.200.1.51) | `ping` | Éxito (Valida PtP) |
| **Área IT (MK02)** | MK03 (10.200.1.20) | `ping` | Éxito (Valida PtP y cable a MK03) |
| **Área IT (MK02)** | MK04/05/06 (10.200.1.21/22/25) | `ping` | Éxito (Valida PtMP) |

### 3.2. Pruebas de Transporte de VLANs (VLAN 90/96)

**Objetivo:** Verificar que los clientes remotos obtienen IP del DHCP de MK01 y tienen conectividad de Capa 3.

| Origen | Destino | VLAN | Prueba | Resultado Esperado |
| :--- | :--- | :--- | :--- | :--- |
| **Cliente Wi-Fi (MK04)** | MK01 (192.168.90.1) | 90 | Obtener IP por DHCP | IP en rango 192.168.90.x |
| **Cliente Wi-Fi (MK04)** | MK01 (192.168.90.1) | 90 | `ping` | Éxito (Valida PtMP, PtP, Q-in-Q, DHCP Relay) |
| **Cliente Wi-Fi (MK05)** | MK01 (192.168.96.1) | 96 | Obtener IP por DHCP | IP en rango 192.168.96.x |
| **Cliente Wi-Fi (MK05)** | WAN (Internet) | 96 | `ping` | Éxito (Valida conectividad a Internet) |

### 3.3. Pruebas de Aislamiento

**Objetivo:** Verificar que la VLAN 96 (Guest) está aislada de las redes corporativas (192.168.x.x/16).

| Origen | Destino | VLAN | Prueba | Resultado Esperado |
| :--- | :--- | :--- | :--- | :--- |
| **Cliente Wi-Fi (MK04)** | Servidor (192.168.10.x) | 96 | `ping` | **Fallo** (Bloqueado por Firewall en MK01) |

## 4. Conclusiones y Próximos Pasos

El análisis de la configuración revela que la estructura básica de Q-in-Q y radioenlaces está implementada, pero con **errores críticos** en la asignación de IPs de Gateway en MK01 y la **ausencia de DHCP Relay** en los dispositivos remotos.

**Próximo Paso:** Se requiere la corrección de estas inconsistencias antes de realizar las pruebas de conectividad. Se debe:
1.  Corregir la duplicidad de IPs de Gateway en MK01.
2.  Implementar el DHCP Relay en MK02, MK03, MK04, MK05 y MK06.
3.  Ajustar la configuración de VLANs en MK01 para encapsular solo las VLANs necesarias (90, 96, 999).
4.  Ajustar los PVIDs en los puertos de acceso de MK03, MK04, MK05 y MK06 para que los clientes obtengan las VLANs 90/96 etiquetadas o sin etiquetar según el diseño.
5.  Revisar la configuración de los SXTs para asegurar que el transporte de VLANs sea correcto.

Se recomienda al usuario realizar las correcciones y luego proceder con el plan de pruebas.
```
