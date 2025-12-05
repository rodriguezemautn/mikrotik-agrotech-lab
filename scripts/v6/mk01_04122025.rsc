# Configuración Corregida para MK01-agrotech-lp-gw (RouterOS 6.49)
# Correcciones:
# 1. Eliminación de la duplicidad de IPs de Gateway en las interfaces Q-in-Q.
# 2. Eliminación de la encapsulación de VLANs innecesarias (10, 20, 201) en el Q-in-Q.
# 3. Ajuste de DHCP Server para que solo sirva IPs a través de las interfaces locales.

/system identity set name=MK01-agrotech-lp-gw

# 1. Limpieza de IPs duplicadas y VLANs innecesarias en Q-in-Q
/ip address remove [find comment~"Gateway remoto VLAN"]
/ip dhcp-server remove [find interface~"qinq-vlan"]

# 2. Reconfiguración de Interfaces VLAN (Solo encapsular 90, 96, 999)
/interface vlan remove [find name~"qinq-vlan"]
/interface vlan
add comment="C-VLAN 90 - Private WiFi (encapsulada en S-VLAN 4000)" interface=s-vlan-4000 mtu=1580 name=qinq-vlan90 vlan-id=90
add comment="C-VLAN 96 - Guest WiFi (encapsulada en S-VLAN 4000)" interface=s-vlan-4000 mtu=1580 name=qinq-vlan96 vlan-id=96
add comment="C-VLAN 999 - Management (encapsulada en S-VLAN 4000)" interface=s-vlan-4000 mtu=1580 name=qinq-vlan999 vlan-id=999

# 3. Reconfiguración de Bridge VLAN Filtering (Solo transportar 90, 96, 999 en Q-in-Q)
/interface bridge vlan remove [find vlan-ids=10]
/interface bridge vlan remove [find vlan-ids=20]
/interface bridge vlan remove [find vlan-ids=201]
/interface bridge vlan remove [find vlan-ids=90]
/interface bridge vlan remove [find vlan-ids=96]
/interface bridge vlan remove [find vlan-ids=999]

/interface bridge vlan
# VLAN 10 (Local)
add bridge=BR-LOCAL tagged=BR-LOCAL untagged=ether4-local vlan-ids=10
# VLAN 20 (Local)
add bridge=BR-LOCAL tagged=BR-LOCAL vlan-ids=20
# VLAN 201 (Local)
add bridge=BR-LOCAL tagged=BR-LOCAL untagged=ether5-local vlan-ids=201
# VLAN 90 (Local + Q-in-Q)
add bridge=BR-LOCAL tagged=BR-LOCAL,s-vlan-4000,wlan1 vlan-ids=90
# VLAN 96 (Local + Q-in-Q)
add bridge=BR-LOCAL tagged=BR-LOCAL,s-vlan-4000,wlan1 vlan-ids=96
# VLAN 999 (Management - Local + Q-in-Q)
add bridge=BR-LOCAL tagged=BR-LOCAL,s-vlan-4000 untagged=ether3-mgmt vlan-ids=999
# S-VLAN 4000 (Trunk ISP)
add bridge=BR-LOCAL tagged=BR-LOCAL,ether2-isp vlan-ids=4000

# 4. Asignación de IP a las interfaces Q-in-Q para el enrutamiento de gestión
# La IP de gestión 10.200.1.1/24 ya está asignada a vlan999-mgmt (Línea 79 del .rsc original).
# Para que el tráfico de gestión regrese por el Q-in-Q, la ruta estática es suficiente.

# 5. Ajuste de Firewall Mangle (Solo para Q-in-Q)
# La regla de mark-routing (Línea 125) debe usar la interfaz qinq-vlan999 como in-interface para el tráfico de gestión que viene del campo.
# La regla actual usa ether2-isp, que es la interfaz física, lo cual es correcto para el tráfico Q-in-Q.

# 6. Ajuste de Rutas (La ruta por defecto debe usar la interfaz WAN)
/ip route set [find comment="Default route to Internet"] gateway=ether1-wan

# 7. Reconfiguración de DHCP Server (Solo para interfaces locales)
# Los DHCP Servers ya están configurados para las interfaces locales (Líneas 51-55 del .rsc original).
# Los DHCP Servers para las interfaces Q-in-Q fueron eliminados en el paso 1.

# 8. Reconfiguración de IP Address (Solo para interfaces Q-in-Q)
/ip address remove [find interface~"qinq-vlan"]
/ip address add address=10.200.1.1/24 comment="Management IP - VLAN 999" interface=vlan999-mgmt network=10.200.1.0
/ip address add address=192.168.10.1/24 comment="Gateway VLAN 10 - Servers" interface=vlan10-local network=192.168.10.0
/ip address add address=192.168.20.1/24 comment="Gateway VLAN 20 - Desktop" interface=vlan20-local network=192.168.20.0
/ip address add address=192.168.90.1/24 comment="Gateway VLAN 90 - Private WiFi" interface=vlan90-local network=192.168.90.0
/ip address add address=192.168.96.1/24 comment="Gateway VLAN 96 - Guest WiFi" interface=vlan96-local network=192.168.96.0
/ip address add address=192.168.201.1/24 comment="Gateway VLAN 201 - CCTV" interface=vlan201-local network=192.168.201.0
/ip address add address=10.10.10.2/30 comment="WAN IP - Simulacion laboratorio" interface=ether1-wan network=10.10.10.0
/ip address add address=10.200.1.1/24 comment="Management IP remoto via Q-in-Q" interface=qinq-vlan999 network=10.200.1.0
