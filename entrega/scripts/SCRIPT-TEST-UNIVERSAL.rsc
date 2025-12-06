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



----


[admin@MK01-agrotech-lp-gw] > system script run full-network-test
           AGROTECH NETWORK - TEST COMPLETO
Equipo: MK01-agrotech-lp-gw
IP: 10.200.1.1/24
 SECCIN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.1 56 64 0ms
    1 10.200.1.1 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK01-Gateway (10.200.1.1) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.10 56 64 0ms
    1 10.200.1.10 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK02-Hub (10.200.1.10) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.20 56 64 224ms
    1 10.200.1.20 timeout
    sent=2 received=1 packet-loss=50% min-rtt=224ms avg-rtt=224ms max-rtt=224ms
   MK03-Campo (10.200.1.20) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.21 timeout
    1 10.200.1.21 timeout
    sent=2 received=0 packet-loss=100%
   MK04-Datos (10.200.1.21) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.22 timeout
    1 10.200.1.22 timeout
    sent=2 received=0 packet-loss=100%
   MK05-Galpon (10.200.1.22) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.25 timeout
    1 10.200.1.25 timeout
    sent=2 received=0 packet-loss=100%
   MK06-Extra (10.200.1.25) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.50 timeout
    1 10.200.1.50 timeout
    sent=2 received=0 packet-loss=100%
   SXT-MG (10.200.1.50) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.51 timeout
    1 10.200.1.51 timeout
    sent=2 received=0 packet-loss=100%
   SXT-CA (10.200.1.51) - FAIL
  Resultado: 3 OK, 5 FAIL
 SECCIN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.10.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN10-Servers (192.168.10.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.20.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN20-Desktop (192.168.20.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.201.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN201-CCTV (192.168.201.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.90.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN90-Private (192.168.90.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.96.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN96-Guest (192.168.96.1) - Alcanzable
 SECCIN 3: CONECTIVIDAD INTERNET
  SEQ HOST SIZE TTL TIME STATUS
    0 8.8.8.8 56 249 10ms
    1 8.8.8.8 56 249 10ms
    sent=2 received=2 packet-loss=0% min-rtt=10ms avg-rtt=10ms max-rtt=10ms
  SEQ HOST SIZE TTL TIME STATUS
    0 1.1.1.1 56 249 10ms
    1 1.1.1.1 56 249 9ms
    sent=2 received=2 packet-loss=0% min-rtt=9ms avg-rtt=9ms max-rtt=10ms
   Google DNS (8.8.8.8) - OK
   Cloudflare DNS (1.1.1.1) - OK
 SECCIN 4: ESTADO DEL SISTEMA
  Uptime: 09:32:32
  CPU: 7%
  Memoria libre: 99 MB
 SECCIN 5: INTERFACES PRINCIPALES
  ether1-wan: RX=381 MB, TX=238 MB
  ether2-isp: RX=43 MB, TX=12 MB
  ether4-local: RX=215 MB, TX=355 MB
                      FIN DEL TEST
 
[admin@MK02-agrotech-mg-ap] > system script run full-network-test
           AGROTECH NETWORK - TEST COMPLETO
Equipo: MK02-agrotech-mg-ap
IP: unknown
 SECCIN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.1 56 64 0ms
    1 10.200.1.1 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK01-Gateway (10.200.1.1) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.10 56 64 0ms
    1 10.200.1.10 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK02-Hub (10.200.1.10) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.20 timeout
    1 10.200.1.20 timeout
    sent=2 received=0 packet-loss=100%
   MK03-Campo (10.200.1.20) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.21 56 64 41ms
    1 10.200.1.21 timeout
    sent=2 received=1 packet-loss=50% min-rtt=41ms avg-rtt=41ms max-rtt=41ms
   MK04-Datos (10.200.1.21) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.22 timeout
    1 10.200.1.22 timeout
    sent=2 received=0 packet-loss=100%
   MK05-Galpon (10.200.1.22) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.25 56 64 18ms
    1 10.200.1.25 timeout
    sent=2 received=1 packet-loss=50% min-rtt=18ms avg-rtt=18ms max-rtt=18ms
   MK06-Extra (10.200.1.25) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.50 56 64 1ms
    1 10.200.1.50 timeout
    sent=2 received=1 packet-loss=50% min-rtt=1ms avg-rtt=1ms max-rtt=1ms
   SXT-MG (10.200.1.50) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.51 56 64 28ms
    1 10.200.1.51 timeout
    sent=2 received=1 packet-loss=50% min-rtt=28ms avg-rtt=28ms max-rtt=28ms
   SXT-CA (10.200.1.51) - OK
  Resultado: 6 OK, 2 FAIL
 SECCIN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.10.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN10-Servers (192.168.10.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.20.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN20-Desktop (192.168.20.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.201.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN201-CCTV (192.168.201.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.90.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN90-Private (192.168.90.1) - Alcanzable
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.96.1 56 64 0ms
    sent=1 received=1 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   VLAN96-Guest (192.168.96.1) - Alcanzable
 SECCIN 3: CONECTIVIDAD INTERNET
  SEQ HOST SIZE TTL TIME STATUS
    0 8.8.8.8 timeout
    1 8.8.8.8 timeout
    sent=2 received=0 packet-loss=100%
  SEQ HOST SIZE TTL TIME STATUS
    0 1.1.1.1 timeout
    1 1.1.1.1 timeout
    sent=2 received=0 packet-loss=100%
   Google DNS (8.8.8.8) - FAIL
   Cloudflare DNS (1.1.1.1) - FAIL
 SECCIN 4: ESTADO DEL SISTEMA
  Uptime: 02:13:06
  CPU: 7%
  Memoria libre: 100 MB
 SECCIN 5: INTERFACES PRINCIPALES
  ether1-to-sxt: RX=92 MB, TX=29 MB
  ether2-isp: RX=9 MB, TX=27 MB
  ether3-mgmt: RX=31 MB, TX=256 MB
                      FIN DEL TEST
[admin@MK03-agrotech-ca-gw] /ip dhcp-server network> /system script run full-network-test
           AGROTECH NETWORK - TEST COMPLETO
Equipo: MK03-agrotech-ca-gw
IP: 10.200.1.20/24
 SECCIN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.1 timeout
    1 10.200.1.1 timeout
    sent=2 received=0 packet-loss=100%
   MK01-Gateway (10.200.1.1) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.10 56 64 11ms
    1 10.200.1.10 56 64 7ms
    sent=2 received=2 packet-loss=0% min-rtt=7ms avg-rtt=9ms max-rtt=11ms
   MK02-Hub (10.200.1.10) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.20 56 64 0ms
    1 10.200.1.20 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK03-Campo (10.200.1.20) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.21 timeout
    1 10.200.1.21 timeout
    sent=2 received=0 packet-loss=100%
   MK04-Datos (10.200.1.21) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.22 56 64 7ms
    1 10.200.1.22 56 64 3ms
    sent=2 received=2 packet-loss=0% min-rtt=3ms avg-rtt=5ms max-rtt=7ms
   MK05-Galpon (10.200.1.22) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.25 56 64 8ms
    1 10.200.1.25 56 64 3ms
    sent=2 received=2 packet-loss=0% min-rtt=3ms avg-rtt=5ms max-rtt=8ms
   MK06-Extra (10.200.1.25) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.50 56 64 35ms
    1 10.200.1.50 56 64 23ms
    sent=2 received=2 packet-loss=0% min-rtt=23ms avg-rtt=29ms max-rtt=35ms
   SXT-MG (10.200.1.50) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.51 56 64 0ms
    1 10.200.1.51 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   SXT-CA (10.200.1.51) - OK
  Resultado: 6 OK, 2 FAIL
 SECCIN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.10.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN10-Servers (192.168.10.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.20.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN20-Desktop (192.168.20.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.201.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN201-CCTV (192.168.201.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.90.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN90-Private (192.168.90.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.96.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN96-Guest (192.168.96.1) - No alcanzable (normal si no es gateway)
 SECCIN 3: CONECTIVIDAD INTERNET
  SEQ HOST SIZE TTL TIME STATUS
    0 8.8.8.8 timeout
    1 8.8.8.8 timeout
    sent=2 received=0 packet-loss=100%
  SEQ HOST SIZE TTL TIME STATUS
    0 1.1.1.1 timeout
    1 1.1.1.1 timeout
    sent=2 received=0 packet-loss=100%
   Google DNS (8.8.8.8) - FAIL
   Cloudflare DNS (1.1.1.1) - FAIL
 SECCIN 4: ESTADO DEL SISTEMA
  Uptime: 09:34:07
  CPU: 4%
  Memoria libre: 97 MB
 SECCIN 5: INTERFACES PRINCIPALES
  ether1-ptp: RX=26 MB, TX=78 MB
                      FIN DEL TEST
[admin@MK03-agrotech-ca-gw] /ip dhcp-server network>
 
[admin@MK04-agrotech-cd-st] > system script run full-network-test
           AGROTECH NETWORK - TEST COMPLETO
Equipo: MK04-agrotech-cd-st
IP: 10.200.1.21/24
 SECCIN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.1 timeout
    1 10.200.1.1 timeout
    sent=2 received=0 packet-loss=100%
   MK01-Gateway (10.200.1.1) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.10 56 64 61ms
    1 10.200.1.10 56 64 37ms
    sent=2 received=2 packet-loss=0% min-rtt=37ms avg-rtt=49ms max-rtt=61ms
   MK02-Hub (10.200.1.10) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.20 56 64 2ms
    1 10.200.1.20 56 64 7ms
    sent=2 received=2 packet-loss=0% min-rtt=2ms avg-rtt=4ms max-rtt=7ms
   MK03-Campo (10.200.1.20) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.21 56 64 0ms
    1 10.200.1.21 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK04-Datos (10.200.1.21) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.22 56 64 29ms
    1 10.200.1.22 56 64 7ms
    sent=2 received=2 packet-loss=0% min-rtt=7ms avg-rtt=18ms max-rtt=29ms
   MK05-Galpon (10.200.1.22) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.25 56 64 11ms
    1 10.200.1.25 56 64 14ms
    sent=2 received=2 packet-loss=0% min-rtt=11ms avg-rtt=12ms max-rtt=14ms
   MK06-Extra (10.200.1.25) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.50 56 64 21ms
    1 10.200.1.50 56 64 12ms
    sent=2 received=2 packet-loss=0% min-rtt=12ms avg-rtt=16ms max-rtt=21ms
   SXT-MG (10.200.1.50) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.51 56 64 13ms
    1 10.200.1.51 56 64 13ms
    sent=2 received=2 packet-loss=0% min-rtt=13ms avg-rtt=13ms max-rtt=13ms
   SXT-CA (10.200.1.51) - OK
  Resultado: 7 OK, 1 FAIL
 SECCIN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.10.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN10-Servers (192.168.10.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.20.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN20-Desktop (192.168.20.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.201.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN201-CCTV (192.168.201.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.90.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN90-Private (192.168.90.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.96.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN96-Guest (192.168.96.1) - No alcanzable (normal si no es gateway)
 SECCIN 3: CONECTIVIDAD INTERNET
  SEQ HOST SIZE TTL TIME STATUS
    0 8.8.8.8 timeout
    1 8.8.8.8 timeout
    sent=2 received=0 packet-loss=100%
  SEQ HOST SIZE TTL TIME STATUS
    0 1.1.1.1 timeout
    1 1.1.1.1 timeout
    sent=2 received=0 packet-loss=100%
   Google DNS (8.8.8.8) - FAIL
   Cloudflare DNS (1.1.1.1) - FAIL
 SECCIN 4: ESTADO DEL SISTEMA
  Uptime: 09:37:17
  CPU: 6%
  Memoria libre: 100 MB
 SECCIN 5: INTERFACES PRINCIPALES
  ether4-servers: RX=2 MB, TX=6 MB
                      FIN DEL TEST
[admin@MK04-agrotech-cd-st] >
 
[admin@MK05-agrotech-cc-st] > system script run full-network-test
           AGROTECH NETWORK - TEST COMPLETO
Equipo: MK05-agrotech-cc-st
IP: 10.200.1.22/24
 SECCIN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.1 timeout
    1 10.200.1.1 timeout
    sent=2 received=0 packet-loss=100%
   MK01-Gateway (10.200.1.1) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.10 56 64 7ms
    1 10.200.1.10 56 64 10ms
    sent=2 received=2 packet-loss=0% min-rtt=7ms avg-rtt=8ms max-rtt=10ms
   MK02-Hub (10.200.1.10) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.20 56 64 3ms
    1 10.200.1.20 56 64 2ms
    sent=2 received=2 packet-loss=0% min-rtt=2ms avg-rtt=2ms max-rtt=3ms
   MK03-Campo (10.200.1.20) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.21 56 64 4ms
    1 10.200.1.21 56 64 5ms
    sent=2 received=2 packet-loss=0% min-rtt=4ms avg-rtt=4ms max-rtt=5ms
   MK04-Datos (10.200.1.21) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.22 56 64 0ms
    1 10.200.1.22 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK05-Galpon (10.200.1.22) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.25 56 64 14ms
    1 10.200.1.25 56 64 27ms
    sent=2 received=2 packet-loss=0% min-rtt=14ms avg-rtt=20ms max-rtt=27ms
   MK06-Extra (10.200.1.25) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.50 56 64 37ms
    1 10.200.1.50 56 64 4ms
    sent=2 received=2 packet-loss=0% min-rtt=4ms avg-rtt=20ms max-rtt=37ms
   SXT-MG (10.200.1.50) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.51 56 64 10ms
    1 10.200.1.51 56 64 4ms
    sent=2 received=2 packet-loss=0% min-rtt=4ms avg-rtt=7ms max-rtt=10ms
   SXT-CA (10.200.1.51) - OK
  Resultado: 7 OK, 1 FAIL
 SECCIN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.10.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN10-Servers (192.168.10.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.20.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN20-Desktop (192.168.20.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.201.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN201-CCTV (192.168.201.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.90.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN90-Private (192.168.90.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.96.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN96-Guest (192.168.96.1) - No alcanzable (normal si no es gateway)
 SECCIN 3: CONECTIVIDAD INTERNET
  SEQ HOST SIZE TTL TIME STATUS
    0 8.8.8.8 timeout
    1 8.8.8.8 timeout
    sent=2 received=0 packet-loss=100%
  SEQ HOST SIZE TTL TIME STATUS
    0 1.1.1.1 timeout
    1 1.1.1.1 timeout
    sent=2 received=0 packet-loss=100%
   Google DNS (8.8.8.8) - FAIL
   Cloudflare DNS (1.1.1.1) - FAIL
 SECCIN 4: ESTADO DEL SISTEMA
  Uptime: 09:38:19
  CPU: 6%
  Memoria libre: 102 MB
 SECCIN 5: INTERFACES PRINCIPALES
  ether3-mgmt: RX=0 MB, TX=9 MB
                      FIN DEL TEST
[admin@MK06-agrotech-ap-extra] > system script run full-network-test
           AGROTECH NETWORK - TEST COMPLETO
Equipo: MK06-agrotech-ap-extra
IP: 10.200.1.25/24
 SECCIN 1: CONECTIVIDAD VLAN 999 (MANAGEMENT)
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.1 timeout
    1 10.200.1.1 timeout
    sent=2 received=0 packet-loss=100%
   MK01-Gateway (10.200.1.1) - FAIL
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.10 56 64 14ms
    1 10.200.1.10 56 64 15ms
    sent=2 received=2 packet-loss=0% min-rtt=14ms avg-rtt=14ms max-rtt=15ms
   MK02-Hub (10.200.1.10) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.20 56 64 13ms
    1 10.200.1.20 56 64 5ms
    sent=2 received=2 packet-loss=0% min-rtt=5ms avg-rtt=9ms max-rtt=13ms
   MK03-Campo (10.200.1.20) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.21 56 64 11ms
    1 10.200.1.21 56 64 6ms
    sent=2 received=2 packet-loss=0% min-rtt=6ms avg-rtt=8ms max-rtt=11ms
   MK04-Datos (10.200.1.21) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.22 56 64 8ms
    1 10.200.1.22 56 64 9ms
    sent=2 received=2 packet-loss=0% min-rtt=8ms avg-rtt=8ms max-rtt=9ms
   MK05-Galpon (10.200.1.22) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.25 56 64 0ms
    1 10.200.1.25 56 64 0ms
    sent=2 received=2 packet-loss=0% min-rtt=0ms avg-rtt=0ms max-rtt=0ms
   MK06-Extra (10.200.1.25) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.50 56 64 28ms
    1 10.200.1.50 56 64 7ms
    sent=2 received=2 packet-loss=0% min-rtt=7ms avg-rtt=17ms max-rtt=28ms
   SXT-MG (10.200.1.50) - OK
  SEQ HOST SIZE TTL TIME STATUS
    0 10.200.1.51 56 64 9ms
    1 10.200.1.51 56 64 5ms
    sent=2 received=2 packet-loss=0% min-rtt=5ms avg-rtt=7ms max-rtt=9ms
   SXT-CA (10.200.1.51) - OK
  Resultado: 7 OK, 1 FAIL
 SECCIN 2: GATEWAYS DE VLANS (Solo si es MK01/MK03)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.10.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN10-Servers (192.168.10.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.20.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN20-Desktop (192.168.20.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.201.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN201-CCTV (192.168.201.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.90.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN90-Private (192.168.90.1) - No alcanzable (normal si no es gateway)
  SEQ HOST SIZE TTL TIME STATUS
    0 192.168.96.1 timeout
    sent=1 received=0 packet-loss=100%
  - VLAN96-Guest (192.168.96.1) - No alcanzable (normal si no es gateway)
 SECCIN 3: CONECTIVIDAD INTERNET
  SEQ HOST SIZE TTL TIME STATUS
    0 8.8.8.8 timeout
    1 8.8.8.8 timeout
    sent=2 received=0 packet-loss=100%
  SEQ HOST SIZE TTL TIME STATUS
    0 1.1.1.1 timeout
    1 1.1.1.1 timeout
    sent=2 received=0 packet-loss=100%
   Google DNS (8.8.8.8) - FAIL
   Cloudflare DNS (1.1.1.1) - FAIL
 SECCIN 4: ESTADO DEL SISTEMA
  Uptime: 09:39:04
  CPU: 4%
  Memoria libre: 102 MB
 SECCIN 5: INTERFACES PRINCIPALES
                      FIN DEL TEST