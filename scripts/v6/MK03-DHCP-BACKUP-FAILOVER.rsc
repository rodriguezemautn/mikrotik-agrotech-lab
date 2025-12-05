# ============================================================================
# MK03 - CONFIGURACIÓN DHCP BACKUP CON FAILOVER
# ============================================================================
# Ejecutar en MK03-agrotech-ca-gw
# ============================================================================

# --- PASO 1: Crear pools para rango BACKUP ---
:put ">>> Configurando pools BACKUP..."

/ip pool remove [find]
/ip pool
add name=pool-vlan10-backup ranges=192.168.10.150-192.168.10.199 comment="Backup VLAN 10"
add name=pool-vlan20-backup ranges=192.168.20.150-192.168.20.199 comment="Backup VLAN 20"
add name=pool-vlan90-backup ranges=192.168.90.150-192.168.90.199 comment="Backup VLAN 90"
add name=pool-vlan96-backup ranges=192.168.96.150-192.168.96.199 comment="Backup VLAN 96"
add name=pool-vlan201-backup ranges=192.168.201.150-192.168.201.199 comment="Backup VLAN 201"

# --- PASO 2: Crear DHCP servers BACKUP (deshabilitados) ---
:put ">>> Configurando DHCP servers BACKUP..."

/ip dhcp-server remove [find]
/ip dhcp-server
add name=dhcp-vlan10-backup interface=vlan10-dhcp address-pool=pool-vlan10-backup \
    lease-time=30m delay-threshold=2s disabled=yes \
    comment="BACKUP - Se activa si MK01 cae"
add name=dhcp-vlan20-backup interface=vlan20-dhcp address-pool=pool-vlan20-backup \
    lease-time=30m delay-threshold=2s disabled=yes \
    comment="BACKUP - Se activa si MK01 cae"
add name=dhcp-vlan90-backup interface=vlan90-dhcp address-pool=pool-vlan90-backup \
    lease-time=30m delay-threshold=2s disabled=yes \
    comment="BACKUP - Se activa si MK01 cae"
add name=dhcp-vlan96-backup interface=vlan96-dhcp address-pool=pool-vlan96-backup \
    lease-time=30m delay-threshold=2s disabled=yes \
    comment="BACKUP - Se activa si MK01 cae"
add name=dhcp-vlan201-backup interface=vlan201-dhcp address-pool=pool-vlan201-backup \
    lease-time=30m delay-threshold=2s disabled=yes \
    comment="BACKUP - Se activa si MK01 cae"

# --- PASO 3: Configurar redes DHCP ---
:put ">>> Configurando redes DHCP..."

/ip dhcp-server network remove [find]
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1,8.8.8.8 \
    comment="VLAN 10 - Gateway en MK01"
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1,8.8.8.8 \
    comment="VLAN 20 - Gateway en MK01"
add address=192.168.90.0/24 gateway=192.168.90.1 dns-server=192.168.90.1,8.8.8.8 \
    comment="VLAN 90 - Gateway en MK01"
add address=192.168.96.0/24 gateway=192.168.96.1 dns-server=192.168.96.1,8.8.8.8 \
    comment="VLAN 96 - Gateway en MK01"
add address=192.168.201.0/24 gateway=192.168.201.1 dns-server=192.168.201.1 \
    comment="VLAN 201 - Gateway en MK01"

# --- PASO 4: Configurar Netwatch para failover automático ---
:put ">>> Configurando Netwatch failover..."

/tool netwatch remove [find]
/tool netwatch add \
    host=10.200.1.1 \
    interval=10s \
    timeout=3s \
    comment="Monitor MK01 - DHCP Failover" \
    up-script={
:log info "============================================"
:log info "MK01 ONLINE - Desactivando DHCP Backup"
:log info "============================================"
/ip dhcp-server set [find name~"backup"] disabled=yes
:log info "DHCP Backup desactivado"
:log info "MK01 es servidor DHCP primario"
} \
    down-script={
:log warning "============================================"
:log warning "MK01 OFFLINE - Activando DHCP Backup"
:log warning "============================================"
/ip dhcp-server set [find name~"backup"] disabled=no
:log warning "DHCP Backup ACTIVADO"
:log warning "MK03 es ahora servidor DHCP"
}

# --- PASO 5: Scripts de verificación ---
:put ">>> Agregando scripts de verificacion..."

/system script remove [find name=ver-failover]
/system script add name=ver-failover owner=admin source={
:put "=== FAILOVER STATUS MK03 ==="
:put ""

# Test MK01
:local mk01 [/ping 10.200.1.1 count=3]
:if ($mk01 > 0) do={
    :put "MK01 Status: ONLINE ($mk01/3 pings)"
    :put "Modo: NORMAL (DHCP en MK01)"
} else={
    :put "MK01 Status: OFFLINE"
    :put "Modo: FAILOVER (DHCP local activo)"
}

:put ""
:put ">>> DHCP Servers:"
/ip dhcp-server print

:put ""
:put ">>> Netwatch:"
/tool netwatch print

:put "=== END ==="
}

/system script remove [find name=test-failover]
/system script add name=test-failover owner=admin source={
:put "=== TEST FAILOVER MANUAL ==="
:put ""
:put ">>> Estado actual DHCP:"
/ip dhcp-server print where disabled=no
:put ""
:put ">>> Simular caida MK01 (activar DHCP backup):"
:put "    /ip dhcp-server set [find name~\"backup\"] disabled=no"
:put ""
:put ">>> Restaurar (desactivar DHCP backup):"
:put "    /ip dhcp-server set [find name~\"backup\"] disabled=yes"
:put "=== END ==="
}

/system script remove [find name=ver-leases]
/system script add name=ver-leases owner=admin source={
:put "=== DHCP LEASES MK03 ==="
:local total [:len [/ip dhcp-server lease find]]
:local bound [:len [/ip dhcp-server lease find where status=bound]]
:put ("Total: $total, Activos: $bound")
:put ""
/ip dhcp-server lease print where status=bound
:put "=== END ==="
}

:put ""
:put "=== CONFIGURACIÓN MK03 COMPLETADA ==="
:put ""
:put "Comandos de verificacion:"
:put "  /system script run ver-failover"
:put "  /system script run ver-leases"
:put "  /system script run test-failover"
:put ""
:put "NOTA: Los DHCP servers estan DESHABILITADOS"
:put "      Se activaran automaticamente si MK01 cae"
