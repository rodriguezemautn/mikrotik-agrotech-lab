# ============================================================================
# SCRIPT UNIVERSAL DE PRUEBA - AGROTECH NETWORK
# ============================================================================
# Copiar y ejecutar en cualquier MikroTik de la topología
# ============================================================================

/system script remove [find name=full-network-test]
/system script add name=full-network-test owner=admin source={

:put "╔══════════════════════════════════════════════════════════════════╗"
:put "║           AGROTECH NETWORK - TEST COMPLETO                       ║"
:put "╚══════════════════════════════════════════════════════════════════╝"
:put ""

# Identificar equipo local
:local identity [/system identity get name]
:local myip "unknown"
:foreach addr in=[/ip address find where interface~"vlan999"] do={
    :set myip [/ip address get $addr address]
}
:put ("Equipo: $identity")
:put ("IP: $myip")
:put ""

# ═══════════════════════════════════════════════════════════════════
:put "┌──────────────────────────────────────────────────────────────────┐"
:put "│ SECCIÓN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)                   │"
:put "└──────────────────────────────────────────────────────────────────┘"

:local mgmtdevices {
    "10.200.1.1"="MK01-Gateway";
    "10.200.1.10"="MK02-Hub";
    "10.200.1.20"="MK03-Campo";
    "10.200.1.21"="MK04-Datos";
    "10.200.1.22"="MK05-Galpon";
    "10.200.1.25"="MK06-Extra";
    "10.200.1.50"="SXT-MG";
    "10.200.1.51"="SXT-CA"
}

:local okcount 0
:local failcount 0

:foreach ip,name in=$mgmtdevices do={
    :local result [/ping $ip count=2 interval=500ms]
    :if ($result > 0) do={
        :put ("  ✓ $name ($ip) - OK")
        :set okcount ($okcount + 1)
    } else={
        :put ("  ✗ $name ($ip) - FAIL")
        :set failcount ($failcount + 1)
    }
}

:put ""
:put ("  Resultado: $okcount OK, $failcount FAIL")

# ═══════════════════════════════════════════════════════════════════
:put ""
:put "┌──────────────────────────────────────────────────────────────────┐"
:put "│ SECCIÓN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)             │"
:put "└──────────────────────────────────────────────────────────────────┘"

:local gateways {
    "192.168.10.1"="VLAN10-Servers";
    "192.168.20.1"="VLAN20-Desktop";
    "192.168.90.1"="VLAN90-Private";
    "192.168.96.1"="VLAN96-Guest";
    "192.168.201.1"="VLAN201-CCTV"
}

:foreach ip,name in=$gateways do={
    :local result [/ping $ip count=1 interval=500ms]
    :if ($result > 0) do={
        :put ("  ✓ $name ($ip) - Alcanzable")
    } else={
        :put ("  - $name ($ip) - No alcanzable (normal si no es gateway)")
    }
}

# ═══════════════════════════════════════════════════════════════════
:put ""
:put "┌──────────────────────────────────────────────────────────────────┐"
:put "│ SECCIÓN 3: CONECTIVIDAD INTERNET                                │"
:put "└──────────────────────────────────────────────────────────────────┘"

:local dns1 [/ping 8.8.8.8 count=2]
:local dns2 [/ping 1.1.1.1 count=2]

:if ($dns1 > 0) do={
    :put "  ✓ Google DNS (8.8.8.8) - OK"
} else={
    :put "  ✗ Google DNS (8.8.8.8) - FAIL"
}

:if ($dns2 > 0) do={
    :put "  ✓ Cloudflare DNS (1.1.1.1) - OK"
} else={
    :put "  ✗ Cloudflare DNS (1.1.1.1) - FAIL"
}

# ═══════════════════════════════════════════════════════════════════
:put ""
:put "┌──────────────────────────────────────────────────────────────────┐"
:put "│ SECCIÓN 4: ESTADO DEL SISTEMA                                   │"
:put "└──────────────────────────────────────────────────────────────────┘"

:local uptime [/system resource get uptime]
:local cpu [/system resource get cpu-load]
:local freemem ([/system resource get free-memory] / 1048576)

:put ("  Uptime: $uptime")
:put ("  CPU: $cpu%")
:put ("  Memoria libre: $freemem MB")

# ═══════════════════════════════════════════════════════════════════
:put ""
:put "┌──────────────────────────────────────────────────────────────────┐"
:put "│ SECCIÓN 5: INTERFACES PRINCIPALES                               │"
:put "└──────────────────────────────────────────────────────────────────┘"

:foreach iface in=[/interface find where type=ether running=yes] do={
    :local name [/interface get $iface name]
    :local rx ([/interface get $iface rx-byte] / 1048576)
    :local tx ([/interface get $iface tx-byte] / 1048576)
    :put ("  $name: RX=$rx MB, TX=$tx MB")
}

:put ""
:put "╔══════════════════════════════════════════════════════════════════╗"
:put "║                      FIN DEL TEST                                ║"
:put "╚══════════════════════════════════════════════════════════════════╝"
}

:put ""
:put "Script agregado. Ejecutar con:"
:put "  /system script run full-network-test"


# ============================================================================
# SCRIPT DE TRACEROUTE
# ============================================================================

/system script remove [find name=trace-to-all]
/system script add name=trace-to-all owner=admin source={
:put "=== TRACEROUTE A TODOS LOS EQUIPOS ==="
:put ""

:local targets {"10.200.1.1";"10.200.1.10";"10.200.1.20";"10.200.1.50"}

:foreach target in=$targets do={
    :put (">>> Traceroute a $target:")
    /tool traceroute $target count=1 timeout=2s
    :put ""
}

:put "=== END ==="
}

:put "Script de traceroute agregado. Ejecutar con:"
:put "  /system script run trace-to-all"
