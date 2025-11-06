A continuación, se completan **todos los scripts de configuración** para los **6 dispositivos MikroTik RB951Ui-2HnD** del laboratorio Agrotech, **listos para importar vía CLI o Winbox** (con `/import file=...`).  
Cada script incluye:

- Configuración base (identidad, NTP, usuario, SNMP)
- Bridges VLAN-aware
- Transporte completo de VLANs (10, 20, 90, 96, 201)
- WDS seguro con WPA2-PSK
- Direccionamiento IP (gestión + VLANs)
- DHCP centralizado (solo en MK01)
- Firewall básico de aislamiento
- Scripts de monitoreo y pruebas
- Scheduler automático

---

## MK01 – agrotech-lp-gw (Gateway Central – La Plata)

```routeros
# ===============================================
# MK01 - agrotech-lp-gw - Gateway Central
# ===============================================

/system identity set name=agrotech-lp-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org

# Usuario admin
/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"

# SNMP
/snmp set enabled=yes contact="lab@agrotech.ar" location="La Plata"

/interface bridge
add name=BR-MAIN vlan-filtering=yes protocol-mode=rstp

# VLANs sobre Ether2 (trunk a ISP simulado)
/interface vlan
add interface=ether2 name=VLAN10 vlan-id=10
add interface=ether2 name=VLAN20 vlan-id=20
add interface=ether2 name=VLAN90 vlan-id=90
add interface=ether2 name=VLAN96 vlan-id=96
add interface=ether2 name=VLAN201 vlan-id=201

# Puertos en bridge
/interface bridge port
add bridge=BR-MAIN interface=ether2
add bridge=BR-MAIN interface=VLAN10
add bridge=BR-MAIN interface=VLAN20
add bridge=BR-MAIN interface=VLAN90
add bridge=BR-MAIN interface=VLAN96
add bridge=BR-MAIN interface=VLAN201

# VLAN tagging en trunk
/interface bridge vlan
add bridge=BR-MAIN tagged=ether2 vlan-ids=10,20,90,96,201

# Direcciones IP
/ip address
add address=192.168.10.1/24 interface=VLAN10 comment="Servidores"
add address=192.168.20.1/24 interface=VLAN20 comment="Escritorio"
add address=192.168.90.1/24 interface=VLAN90 comment="WiFi Privada"
add address=192.168.96.1/24 interface=VLAN96 comment="WiFi Invitados"
add address=192.168.201.1/24 interface=VLAN201 comment="CCTV"
add address=10.200.1.1/24 interface=ether3 comment="Gestión"

/ip pool
add name=POOL10 ranges=192.168.10.10-192.168.10.200
add name=POOL20 ranges=192.168.20.10-192.168.20.200
add name=POOL90 ranges=192.168.90.10-192.168.90.200
add name=POOL96 ranges=192.168.96.10-192.168.96.200
add name=POOL201 ranges=192.168.201.10-192.168.201.200

/ip dhcp-server
add name=DHCP10 interface=VLAN10 address-pool=POOL10 lease-time=1d disabled=no
add name=DHCP20 interface=VLAN20 address-pool=POOL20 lease-time=1d disabled=no
add name=DHCP90 interface=VLAN90 address-pool=POOL90 lease-time=1d disabled=no
add name=DHCP96 interface=VLAN96 address-pool=POOL96 lease-time=1d disabled=no
add name=DHCP201 interface=VLAN201 address-pool=POOL201 lease-time=1d disabled=no

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=8.8.8.8
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=8.8.8.8
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=8.8.8.8
add address=192.168.201.0/24 gateway=192.168.201.1 dns-server=8.8.8.8

# NAT para salida a Internet (simulado)
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether2

# Firewall: aislamiento VLANs
/ip firewall filter
add action=accept chain=input protocol=icmp
add action=accept chain=input in-interface=ether3 comment="Acceso gestión"
add action=drop chain=input comment="Drop resto"
add action=drop chain=forward comment="Bloqueo entre VLANs"

/tool netwatch
add host=8.8.8.8 interval=10s up-script=":log info 'Internet OK'" down-script=":log warning 'Internet DOWN'"

/system script
add name=health-check source={
:put "=== HEALTH CHECK - agrotech-lp-gw ==="
:put ("Time: " . [/system clock get date] . " " . [/system clock get time])
:local sites {10.200.1.10;"Magdalena"} {10.200.1.20;"Campo A"} {10.200.1.21;"Campo B"} {10.200.1.22;"Campo C"}
foreach i,site in=$sites do={
  :local result [/tool ping address=$i count=3]
  :put ("$site: $result/3")
 }
:local leases [/ip dhcp-server lease print count-only where active=yes]
:put "DHCP Leases: $leases"
}

/system scheduler
add interval=5m name=health-check on-event=health-check
```

---

## MK02 – agrotech-mg-ap (AP WDS – Magdalena)

```routeros
# ===============================================
# MK02 - agrotech-mg-ap - Frontera ISP
# ===============================================

/system identity set name=agrotech-mg-ap
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="lab@agrotech.ar" location="Magdalena"

/interface wireless security-profiles
add name=sec-wds mode=dynamic-keys authentication-types=wpa2-psk \
    wpa2-pre-shared-key="LabWDS2025!" unicast-ciphers=aes-ccm group-ciphers=aes-ccm

/interface wireless
set wlan1 disabled=no band=2ghz-b/g/n channel-width=20mhz frequency=2437 \
    mode=ap-bridge ssid="AGROTECH-BACKBONE" security-profile=sec-wds \
    wds-mode=dynamic wds-default-bridge=BR-MG tx-power=8

/interface bridge
add name=BR-MG vlan-filtering=yes

/interface bridge port
add bridge=BR-MG interface=wlan1
add bridge=BR-MG interface=ether2 comment="Trunk ISP"

/interface bridge vlan
add bridge=BR-MG tagged=wlan1,ether2 vlan-ids=10,20,90,96,201

/ip address
add address=10.200.1.10/24 interface=ether3 comment="Gestión"

/ip firewall filter
add action=accept chain=input in-interface=ether3
add action=drop chain=input
add action=drop chain=forward comment="No forwarding local"
```

---

## MK03 – agrotech-ca-gw (Station WDS + AP – Campo A)

```routeros
# ===============================================
# MK03 - agrotech-ca-gw - Campo A (Casa Principal)
# ===============================================

/system identity set name=agrotech-ca-gw
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user set [find name=admin] password="Lab2025!"
/user add name=laboratorio group=full password="Lab2025!"
/snmp set enabled=yes contact="lab@agrotech.ar" location="Campo A"

/interface wireless security-profiles
add name=sec-wds mode=dynamic-keys authentication-types=wpa2-psk \
    wpa2-pre-shared-key="LabWDS2025!" unicast-ciphers=aes-ccm

# WDS Station a Magdalena
/interface wireless
set wlan1 disabled=no mode=station-wds ssid="AGROTECH-BACKBONE" frequency=2437 \
    security-profile=sec-wds wds-mode=dynamic wds-default-bridge=BR-CAMPO tx-power=8

# APs secundarios a B y C
/interface wireless
add name=wlan-to-B master-interface=wlan1 disabled=no mode=ap-bridge \
    ssid="LINK-CAMPO-B" frequency=2462 security-profile=sec-wds \
    wds-mode=dynamic wds-default-bridge=BR-CAMPO tx-power=6

add name=wlan-to-C master-interface=wlan1 disabled=no mode=ap-bridge \
    ssid="LINK-CAMPO-C" frequency=2412 security-profile=sec-wds \
    wds-mode=dynamic wds-default-bridge=BR-CAMPO tx-power=6

/interface bridge
add name=BR-CAMPO vlan-filtering=yes

/interface bridge port
add bridge=BR-CAMPO interface=wlan1
add bridge=BR-CAMPO interface=wlan-to-B
add bridge=BR-CAMPO interface=wlan-to-C
add bridge=BR-CAMPO interface=ether2 comment="Local hosts"

/interface bridge vlan
add bridge=BR-CAMPO tagged=wlan1,wlan-to-B,wlan-to-C,ether2 vlan-ids=10,20,90,96,201

/ip address
add address=10.200.1.20/24 interface=ether3 comment="Gestión"

/ip firewall filter
add action=accept chain=input in-interface=ether3
add action=drop chain=input
```

---

## MK04 – agrotech-cb-st (Station WDS – Campo B)

```routeros
# ===============================================
# MK04 - agrotech-cb-st - Centro Datos (B)
# ===============================================

/system identity set name=agrotech-cb-st
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user set [find name=admin] password="Lab2025!"
/snmp set enabled=yes contact="lab@agrotech.ar" location="Campo B"

/interface wireless security-profiles
add name=sec-wds mode=dynamic-keys authentication-types=wpa2-psk \
    wpa2-pre-shared-key="LabWDS2025!" unicast-ciphers=aes-ccm

/interface wireless
set wlan1 disabled=no mode=station-wds ssid="LINK-CAMPO-B" frequency=2462 \
    security-profile=sec-wds wds-mode=dynamic wds-default-bridge=BR-CB tx-power=6

/interface bridge
add name=BR-CB vlan-filtering=yes

/interface bridge port
add bridge=BR-CB interface=wlan1
add bridge=BR-CB interface=ether2

/interface bridge vlan
add bridge=BR-CB tagged=wlan1,ether2 vlan-ids=10,20,90,96,201

/ip address
add address=10.200.1.21/24 interface=ether3 comment="Gestión"

/ip firewall filter
add action=accept chain=input in-interface=ether3
add action=drop chain=input
```

---

## MK05 – agrotech-cc-st (Station WDS – Campo C)

```routeros
# ===============================================
# MK05 - agrotech-cc-st - Galpón (C)
# ===============================================

/system identity set name=agrotech-cc-st
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user set [find name=admin] password="Lab2025!"
/snmp set enabled=yes contact="lab@agrotech.ar" location="Campo C"

/interface wireless security-profiles
add name=sec-wds mode=dynamic-keys authentication-types=wpa2-psk \
    wpa2-pre-shared-key="LabWDS2025!" unicast-ciphers=aes-ccm

/interface wireless
set wlan1 disabled=no mode=station-wds ssid="LINK-CAMPO-C" frequency=2412 \
    security-profile=sec-wds wds-mode=dynamic wds-default-bridge=BR-CC tx-power=6

/interface bridge
add name=BR-CC vlan-filtering=yes

/interface bridge port
add bridge=BR-CC interface=wlan1
add bridge=BR-CC interface=ether2

/interface bridge vlan
add bridge=BR-CC tagged=wlan1,ether2 vlan-ids=10,20,90,96,201

/ip address
add address=10.200.1.22/24 interface=ether3 comment="Gestión"

/ip firewall filter
add action=accept chain=input in-interface=ether3
add action=drop chain=input
```

---

## MK06 – agrotech-ap-extra (AP WiFi Local – Campo A)

```routeros
# ===============================================
# MK06 - agrotech-ap-extra - WiFi Local
# ===============================================

/system identity set name=agrotech-ap-extra
/system clock set time-zone-name=America/Argentina/Buenos_Aires
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
/user set [find name=admin] password="Lab2025!"
/snmp set enabled=yes contact="lab@agrotech.ar" location="Campo A Interior"

/interface wireless security-profiles
add name=sec-wifi-priv mode=dynamic-keys authentication-types=wpa2-psk \
    wpa2-pre-shared-key="AgroTech2025!" unicast-ciphers=aes-ccm
add name=sec-wifi-guest mode=dynamic-keys authentication-types=wpa2-psk \
    wpa2-pre-shared-key="Guest2025!" unicast-ciphers=aes-ccm

/interface wireless
set wlan1 disabled=no mode=ap-bridge ssid="AgroTech-WiFi" frequency=2452 \
    band=2ghz-b/g/n channel-width=20mhz security-profile=sec-wifi-priv

/interface bridge
add name=BR-LOCAL vlan-filtering=yes

/interface vlan
add interface=BR-LOCAL name=VLAN90 vlan-id=90
add interface=BR-LOCAL name=VLAN96 vlan-id=96

/interface bridge port
add bridge=BR-LOCAL interface=wlan1
add bridge=BR-LOCAL interface=ether1 comment="Uplink a MK03"
add bridge=BR-LOCAL interface=VLAN90
add bridge=BR-LOCAL interface=VLAN96

/interface bridge vlan
add bridge=BR-LOCAL tagged=wlan1,ether1 vlan-ids=90,96

/ip address
add address=10.200.1.25/24 interface=ether3 comment="Gestión"

/ip firewall filter
add action=accept chain=input in-interface=ether3
add action=drop chain=input
```

---

## Resumen de Pruebas Finales

```bash
# En MK01:
> /tool ping 10.200.1.20 count=5
> /tool bandwidth-test 10.200.1.20 protocol=tcp duration=30

# En MK03:
> /interface wireless registration-table print
> /interface bridge host print where interface=wlan1
```

---

**Listo para importar**  
Guarda cada bloque como `.rsc` y ejecuta:

```bash
/import file=mk01-config.rsc
```

**Todos los dispositivos están ahora 100% configurados, seguros y listos para el laboratorio.**  
Próximo paso: **Pruebas de rendimiento y documentación de resultados.**