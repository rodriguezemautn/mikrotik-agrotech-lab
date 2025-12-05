# ============================================================================
# MK01 - CORRECCIÓN Y AJUSTE DHCP PRIMARIO v2
# ============================================================================
# Ejecutar en MK01-agrotech-lp-gw
# ============================================================================

# --- PASO 1: Limpiar IPs huérfanas (sin interfaz) ---
:put ">>> Limpiando IPs huerfanas..."

# Mostrar IPs actuales
/ip address print

# Las IPs con comment "remoto via Q-in-Q" que no tienen interfaz válida
# deben eliminarse manualmente. Verificar con:
# /ip address print detail
# Y eliminar las que tengan interface="" o interface no existente

# --- PASO 2: Ajustar pools DHCP (rango primario) ---
:put ">>> Ajustando pools DHCP..."

/ip pool set [find name=pool-vlan10] ranges=192.168.10.100-192.168.10.149
/ip pool set [find name=pool-vlan20] ranges=192.168.20.100-192.168.20.149
/ip pool set [find name=pool-vlan90] ranges=192.168.90.100-192.168.90.149
/ip pool set [find name=pool-vlan96] ranges=192.168.96.100-192.168.96.149
/ip pool set [find name=pool-vlan201] ranges=192.168.201.100-192.168.201.149

# --- PASO 3: Limpiar DHCP servers huérfanos ---
:put ">>> Limpiando DHCP servers huerfanos..."

# Eliminar los que tienen interface vacía
/ip dhcp-server remove [find where interface=""]

# --- PASO 4: Agregar scripts de verificación ---
/system script remove [find name=ver-dhcp]
/system script add name=ver-dhcp owner=admin source={
:put "=== DHCP STATUS MK01 ==="
/ip dhcp-server print
:put ""
:put ">>> Leases activos por VLAN:"
:foreach srv in=[/ip dhcp-server find] do={
    :local name [/ip dhcp-server get $srv name]
    :local count [:len [/ip dhcp-server lease find where server=$name status=bound]]
    :put ("  $name: $count leases")
}
:put "=== END ==="
}

/system script remove [find name=ver-pools]
/system script add name=ver-pools owner=admin source={
:put "=== DHCP POOLS MK01 ==="
/ip pool print
:put "=== END ==="
}

/system script remove [find name=test-vlans]
/system script add name=test-vlans owner=admin source={
:put "=== TEST VLANS MK01 ==="
:put ""
:put ">>> Ping a equipos remotos (VLAN 999):"
:foreach t in={"10.200.1.10";"10.200.1.20";"10.200.1.21";"10.200.1.22";"10.200.1.25"} do={
    :local r [/ping $t count=2]
    :put ("  $t: " . [:pick "FAIL" "OK  " ($r > 0) (($r > 0) + 4)])
}
:put ""
:put ">>> Ping a internet:"
:local inet [/ping 8.8.8.8 count=2]
:put ("  8.8.8.8: " . [:pick "FAIL" "OK  " ($inet > 0) (($inet > 0) + 4)])
:put "=== END ==="
}

:put ""
:put "=== CORRECCIÓN MK01 COMPLETADA ==="
:put ""
:put "Comandos de verificacion:"
:put "  /system script run ver-dhcp"
:put "  /system script run ver-pools"
:put "  /system script run test-vlans"
