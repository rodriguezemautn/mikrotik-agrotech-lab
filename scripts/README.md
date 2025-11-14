# Instrucciones de Despliegue de Radioenlaces AgroTech (Versión 131125)

Resumen de Cumplimiento 

Requerimiento

Estado

Observaciones

1. Frontera L2 ISP con Q-in-Q

Cumplido

MK01/MK02 OK.

2. Enlace PtP 8 km (SXT-MG ↔ SXT-CA)

Cumplido

Usando SXT G-2HnD, WDS, Nv2.

3. Enlace PtMP (MK03 → MK04/05/06)

Cumplido

WDS + Nv2, transporte VLANs.

4. AP local VLAN90/96 en cada sitio

Cumplido

OK en MK01, MK02, MK06.

5. Versiones de Scripts

Cumplido

Todos los scripts versionados con 131125.

6. Correo Electrónico

Cumplido

Configuración SMTP en MK01 para protocolosinlambrica@gmail.com.

Antes de importar el archivo:
/system reset-configuration no-defaults=yes skip-backup=yes

/import file=mk01_131125.rsc


Orden de importación recomendado:

MK01 → MK02 → SXT-MG → SXT-CA → MK03 → MK04 → MK05 → MK06