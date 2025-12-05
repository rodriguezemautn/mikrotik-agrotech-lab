# ============================================================================
# AGROTECH - DHCP DISTRIBUIDO CON FAILOVER
# ============================================================================
#
# ESTRATEGIA:
# - MK01: DHCP Primario (responde inmediatamente)
# - MK03: DHCP Secundario (delay 2s, responde si MK01 no responde)
# - MK04: DHCP Terciario (delay 4s, último recurso)
#
# RANGOS IP POR VLAN:
# ┌─────────┬─────────────────────┬─────────────────────┬─────────────────────┐
# │  VLAN   │   MK01 (Primario)   │  MK03 (Secundario)  │  MK04 (Terciario)   │
# ├─────────┼─────────────────────┼─────────────────────┼─────────────────────┤
# │   10    │   .100 - .129       │   .130 - .159       │   .160 - .180       │
# │   20    │   .100 - .129       │   .130 - .159       │   .160 - .180       │
# │   90    │   .100 - .129       │   .130 - .159       │   .160 - .180       │
# │   96    │   .100 - .129       │   .130 - .159       │   .160 - .180       │
# │  201    │   .100 - .129       │   .130 - .159       │   .160 - .180       │
# │  999    │   .10 - .19 (MK01)  │   .20 - .29 (reserv)│   (no DHCP)         │
# └─────────┴─────────────────────┴─────────────────────┴─────────────────────┘
#
# GATEWAY ÚNICO: 192.168.x.1 (MK01) para todas las VLANs de datos
# GATEWAY MGMT:  10.200.1.1 (MK01)
#
# ============================================================================


# ############################################################################
# MK01 - DHCP PRIMARIO (Gateway Central)
# ############################################################################

# === EJECUTAR EN MK01 ===

# 1. Limpiar DHCP servers huérfanos (sin interface)
/ip dhcp-server remove [find where interface=""]

# 2. Actualizar pools con rangos primarios
/ip pool
set [find name=pool-vlan10] ranges=192.168.10.100-192.168.10.129
set [find name=pool-vlan20] ranges=192.168.20.100-192.168.20.129
set [find name=pool-vlan90] ranges=192.168.90.100-192.168.90.129
set [find name=pool-vlan96] ranges=192.168.96.100-192.168.96.129
set [find name=pool-vlan201] ranges=192.168.201.100-192.168.201.129

# 3. Agregar pool para VLAN 999 (Management)
/ip pool add name=pool-vlan999 ranges=10.200.1.10-10.200.1.19 comment="Pool VLAN 999 - Management"

# 4. Agregar DHCP server para VLAN 999
/ip dhcp-server add name=dhcp-vlan999 interface=vlan999-mgmt address-pool=pool-vlan999 lease-time=1d disabled=no

# 5. Agregar network para VLAN 999
/ip dhcp-server network add address=10.200.1.0/24 gateway=10.200.1.1 dns-server=10.200.1.1 comment="VLAN 999 - Management"

# 6. Verificar DHCP servers activos
/ip dhcp-server print

# 7. Limpiar IPs duplicadas (remover las que no tienen interface)
/ip address remove [find where interface=""]


# ############################################################################
# MK03 - DHCP SECUNDARIO (Campo Gateway)
# ############################################################################

# === EJECUTAR EN MK03 ===

# 1. Corregir gateways (cambiar de .254 a .1)
/ip dhcp-server network
set [find address=192.168.10.0/24] gateway=192.168.10.1 dns-server=192.168.10.1,8.8.8.8
set [find address=192.168.20.0/24] gateway=192.168.20.1 dns-server=192.168.20.1,8.8.8.8
set [find address=192.168.90.0/24] gateway=192.168.90.1 dns-server=192.168.90.1,8.8.8.8
set [find address=192.168.96.0/24] gateway=192.168.96.1 dns-server=192.168.96.1,8.8.8.8
set [find address=192.168.201.0/24] gateway=192.168.201.1 dns-server=192.168.201.1

# 2. Actualizar pools con rangos secundarios
/ip pool
set [find name=pool-vlan10-local] ranges=192.168.10.130-192.168.10.159
set [find name=pool-vlan20-local] ranges=192.168.20.130-192.168.20.159
set [find name=pool-vlan90-local] ranges=192.168.90.130-192.168.90.159
set [find name=pool-vlan96-local] ranges=192.168.96.130-192.168.96.159
set [find name=pool-vlan201-local] ranges=192.168.201.130-192.168.201.159

# 3. Crear DHCP servers con delay (2 segundos)
# Primero remover los existentes si hay
/ip dhcp-server remove [find where name~"local"]

# Crear nuevos con delay
/ip dhcp-server
add name=dhcp-vlan10-backup interface=vlan10-dhcp address-pool=pool-vlan10-local \
    lease-time=1h delay-threshold=2s disabled=no comment="DHCP Backup VLAN 10"
add name=dhcp-vlan20-backup interface=vlan20-dhcp address-pool=pool-vlan20-local \
    lease-time=1h delay-threshold=2s disabled=no comment="DHCP Backup VLAN 20"
add name=dhcp-vlan90-backup interface=vlan90-dhcp address-pool=pool-vlan90-local \
    lease-time=8h delay-threshold=2s disabled=no comment="DHCP Backup VLAN 90"
add name=dhcp-vlan96-backup interface=vlan96-dhcp address-pool=pool-vlan96-local \
    lease-time=1h delay-threshold=2s disabled=no comment="DHCP Backup VLAN 96"
add name=dhcp-vlan201-backup interface=vlan201-dhcp address-pool=pool-vlan201-local \
    lease-time=1d delay-threshold=2s disabled=no comment="DHCP Backup VLAN 201"

# 4. Remover IPs locales .254 (ya no las necesitamos como gateway)
# NOTA: Mantener solo para que el equipo tenga IP en cada VLAN
# pero los clientes usarán gateway .1 (MK01)

# 5. Verificar configuración
/ip dhcp-server print
/ip dhcp-server network print


# ############################################################################
# MK04 - DHCP TERCIARIO (Centro de Datos - Opcional)
# ############################################################################

# === EJECUTAR EN MK04 ===

# 1. Crear VLANs para DHCP (si no existen)
/interface vlan
add name=vlan10-local interface=BR-CAMPO vlan-id=10 comment="VLAN 10 para DHCP"
add name=vlan20-local interface=BR-CAMPO vlan-id=20 comment="VLAN 20 para DHCP"

# 2. Crear pools terciarios
/ip pool
add name=pool-vlan10-tertiary ranges=192.168.10.160-192.168.10.180 comment="Pool terciario VLAN 10"
add name=pool-vlan20-tertiary ranges=192.168.20.160-192.168.20.180 comment="Pool terciario VLAN 20"

# 3. Crear DHCP servers con delay mayor (4 segundos)
/ip dhcp-server
add name=dhcp-vlan10-tertiary interface=vlan10-local address-pool=pool-vlan10-tertiary \
    lease-time=1h delay-threshold=4s disabled=no comment="DHCP Terciario VLAN 10"
add name=dhcp-vlan20-tertiary interface=vlan20-local address-pool=pool-vlan20-tertiary \
    lease-time=1h delay-threshold=4s disabled=no comment="DHCP Terciario VLAN 20"

# 4. Agregar networks
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1,8.8.8.8 comment="VLAN 10"
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1,8.8.8.8 comment="VLAN 20"


# ############################################################################
# VERIFICACIÓN DE DHCP DISTRIBUIDO
# ############################################################################

# === Script de verificación (agregar a todos los equipos) ===

/system script add name=check-dhcp-status owner=admin source={
:put "=== DHCP SERVER STATUS ==="
:put ""
:put ">>> Servers:"
/ip dhcp-server print
:put ""
:put ">>> Leases activos:"
/ip dhcp-server lease print where status=bound
:put ""
:put ">>> Pools:"
/ip pool print
:put "=== END ==="
}


# ############################################################################
# TEST DE CONECTIVIDAD END-TO-END
# ############################################################################

# === Script de test completo (agregar a MK01) ===

/system script add name=test-full-connectivity owner=admin source={
:put "=============================================="
:put "=== TEST CONECTIVIDAD END-TO-END AGROTECH ==="
:put "=============================================="
:put ""

# Test VLAN 999 (Management)
:put ">>> VLAN 999 - Management:"
:foreach ip in={"10.200.1.10";"10.200.1.20";"10.200.1.21";"10.200.1.22";"10.200.1.25";"10.200.1.50";"10.200.1.51"} do={
    :local r [/ping $ip count=2]
    :if ($r > 0) do={:put ("  $ip: OK")} else={:put ("  $ip: FAIL")}
}

:put ""
:put ">>> VLAN 10 - Servers (si hay clientes):"
/ip dhcp-server lease print where server~"vlan10"

:put ""
:put ">>> VLAN 20 - Desktop (si hay clientes):"
/ip dhcp-server lease print where server~"vlan20"

:put ""
:put "=== FIN TEST ==="
}


# ############################################################################
# NOTAS IMPORTANTES
# ############################################################################
#
# 1. DELAY THRESHOLD:
#    - MK01: 0s (responde inmediatamente)
#    - MK03: 2s (espera 2 segundos antes de responder)
#    - MK04: 4s (espera 4 segundos, último recurso)
#
# 2. COMPORTAMIENTO:
#    - Cliente envía DHCP Discover
#    - MK01 responde primero (si está disponible)
#    - Si MK01 no responde en 2s, MK03 responde
#    - Si MK03 tampoco responde en 4s, MK04 responde
#
# 3. GATEWAY ÚNICO:
#    - Todos los DHCP servers entregan gateway 192.168.x.1 (MK01)
#    - Esto asegura que el tráfico siempre pase por MK01 para NAT
#
# 4. SI MK01 ESTÁ CAÍDO:
#    - Los clientes obtienen IP de MK03 o MK04
#    - PERO no tendrán salida a Internet (gateway caído)
#    - Para resolver esto, MK03 debería activar NAT local (ver netwatch)
#
# 5. LEASE TIME:
#    - VLANs de datos: 1h (para rápida reasignación)
#    - VLAN 90 WiFi: 8h
#    - VLAN 201 CCTV: 1d (cámaras estáticas)
#
# ############################################################################
