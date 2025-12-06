# 🌾 AgroTech Network Infrastructure
## Resumen Ejecutivo - Versión 051225

---

### 📍 Resumen de Red

| Característica | Valor |
|----------------|-------|
| **Sitios** | 3 (La Plata, Magdalena, Campo) |
| **Dispositivos** | 8 MikroTik |
| **VLANs** | 6 (10, 20, 90, 96, 201, 999) |
| **Enlace PTP** | 8 km (2.4GHz NV2) |
| **PTMP Stations** | 3 |
| **RouterOS** | 6.49.19 |

---

### 🗺️ Topología

```
LA PLATA                    MAGDALENA                         CAMPO
┌─────────┐                ┌─────────┐     8km PTP      ┌─────────┐
│  MK01   │───ISP/Trunk───▶│  MK02   │◀───────────────▶│  MK03   │
│ Gateway │                │  Hub    │    SXT-MG/CA    │  PTMP   │
│ DHCP-1° │                │ Q-in-Q  │                 │ DHCP-2° │
└─────────┘                └─────────┘                 └────┬────┘
                                                            │ PTMP
                                          ┌─────────────────┼─────────────────┐
                                          ▼                 ▼                 ▼
                                     ┌─────────┐       ┌─────────┐       ┌─────────┐
                                     │  MK04   │       │  MK05   │       │  MK06   │
                                     │ Centro  │       │ Galpón  │       │ AP-Ext  │
                                     │ Datos   │       │ Tambo   │       │         │
                                     └─────────┘       └─────────┘       └─────────┘
```

---

### 📋 Direccionamiento IP

#### Red de Management (VLAN 999)
| Dispositivo | IP | Ubicación |
|-------------|-----|-----------|
| MK01 | 10.200.1.1 | La Plata - Gateway |
| MK02 | 10.200.1.10 | Magdalena - Hub |
| MK03 | 10.200.1.20 | Campo - Gateway |
| MK04 | 10.200.1.21 | Campo - Centro Datos |
| MK05 | 10.200.1.22 | Campo - Galpón |
| MK06 | 10.200.1.25 | Campo - AP Extra |
| SXT-MG | 10.200.1.50 | Magdalena - PTP AP |
| SXT-CA | 10.200.1.51 | Campo - PTP Station |

#### Segmentos de Red
| VLAN | Red | Propósito | DHCP Pool MK01 | DHCP Pool MK03 |
|------|-----|-----------|----------------|----------------|
| 10 | 192.168.10.0/24 | Servers | .100-.129 | .150-.199 |
| 20 | 192.168.20.0/24 | Desktop | .100-.129 | .150-.199 |
| 90 | 192.168.90.0/24 | WiFi Privada | .100-.129 | .150-.199 |
| 96 | 192.168.96.0/24 | WiFi Guest | .100-.129 | .150-.199 |
| 201 | 192.168.201.0/24 | CCTV | .100-.129 | .150-.199 |
| 999 | 10.200.1.0/24 | Management | .10-.19 | — |

---

### 🔐 Credenciales WiFi

| SSID | Uso | Perfil | VLANs |
|------|-----|--------|-------|
| `Agrotech-Office-LP` | Oficina La Plata | agrotech-private | 90/96 |
| `Agrotech-PTMP-Campo` | Enlace PTMP | ptmp-campo | Trunk |
| `Agrotech-PTP-MG-CA` | Enlace PTP 8km | ptp-secure | Trunk |

---

### ⚡ Alta Disponibilidad

**DHCP Failover Automático:**
- **Primario**: MK01 (siempre activo)
- **Backup**: MK03 (activación automática si MK01 cae)
- **Monitoreo**: Netwatch cada 10 segundos
- **Sin conflictos**: Pools separados (.100-.129 vs .150-.199)

---

### 🚀 Despliegue Rápido

```bash
# 1. Reset del dispositivo
/system reset-configuration no-defaults=yes skip-backup=yes

# 2. Importar configuración
/import file=MKxx_051225_V7.rsc
```

**Orden recomendado:** MK01 → MK02 → SXT-MG → SXT-CA → MK03 → MK04 → MK05 → MK06

---

### 📊 Verificación Rápida

```routeros
# Desde MK01 - Test completo
/system script run test-full-connectivity

# Desde cualquier equipo - Ping a gateway
/ping 10.200.1.1 count=5

# Ver clientes PTMP (desde MK03)
/interface wireless registration-table print
```

---

### ⚠️ Puntos de Atención

1. **Enlace PTP 8km**: Sensible a interferencia 2.4GHz - monitorear CCQ
2. **MTU 1590**: Configurado para Q-in-Q, MSS clamping activo
3. **Guest VLAN 96**: Aislada de redes corporativas
4. **CCTV VLAN 201**: Sin acceso a Internet (solo red interna)

---

**Versión**: 051225_V7 | **Contacto**: protocolosinlambrica@gmail.com
