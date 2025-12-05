# ============================================================================
# MK02 - SCRIPT DE CORRECCIÓN RÁPIDA (Sin reset)
# ============================================================================
#
# PROBLEMA: Falta BR-TRANSPORT con los puertos principales
# SOLUCIÓN: Crear bridge y agregar puertos
#
# EJECUTAR LÍNEA POR LÍNEA O COPIAR TODO
#
# ============================================================================

# PASO 1: Crear el bridge de transporte que falta
/interface bridge add name=BR-TRANSPORT vlan-filtering=no protocol-mode=none comment="Bridge transporte L2"

# PASO 2: Agregar los puertos principales
# IMPORTANTE: Estos son los que faltaban!
/interface bridge port add bridge=BR-TRANSPORT interface=s-vlan-4000-transport comment="Q-in-Q entrada"
/interface bridge port add bridge=BR-TRANSPORT interface=ether1-to-sxt comment="Trunk a SXT-MG"

# PASO 3: Crear VLAN 999 sobre BR-TRANSPORT para gestión
/interface vlan add name=vlan999-transport interface=BR-TRANSPORT vlan-id=999 comment="VLAN 999 transporte"

# PASO 4: Agregar vlan999-transport al bridge de unión de gestión
/interface bridge port add bridge=BR-MGMT-UNION interface=vlan999-transport comment="VLAN 999 desde transporte"

# PASO 5: Verificar inmediatamente
:put "=== VERIFICACIÓN ==="
:put ""
:put ">>> Bridge ports en BR-TRANSPORT:"
/interface bridge port print where bridge=BR-TRANSPORT
:put ""
:put ">>> Test ping a MK01:"
/ping 10.200.1.1 count=3
:put ""
:put ">>> Test ping a SXT-MG:"
/ping 10.200.1.50 count=3


# ============================================================================
# SI TODAVÍA NO FUNCIONA, VERIFICAR:
# ============================================================================
#
# 1. ¿Hay cable en ether2-isp? 
#    /interface ethernet monitor ether2-isp once
#
# 2. ¿La S-VLAN 4000 está corriendo?
#    /interface vlan print where name=s-vlan-4000-transport
#
# 3. ¿Hay tráfico llegando?
#    /interface print stats where name~"ether2|s-vlan"
#
# 4. ¿El switch ISP está configurado con VLAN 4000?
#    (Si usas cable directo, no necesitas Q-in-Q)
#
# ============================================================================


# ============================================================================
# ALTERNATIVA: SI USAS CABLE DIRECTO (Sin Q-in-Q)
# ============================================================================
# Si conectaste MK01-ether2 directamente a MK02-ether2 sin switch:

# Remover s-vlan-4000-transport del bridge
# /interface bridge port remove [find interface=s-vlan-4000-transport bridge=BR-TRANSPORT]

# Agregar ether2-isp directamente (sin Q-in-Q)
# /interface bridge port add bridge=BR-TRANSPORT interface=ether2-isp comment="Trunk directo desde MK01"

# Y en MK01, agregar ether2 al bridge como trunk (ver MK01-TRUNK-DIRECTO.rsc)
