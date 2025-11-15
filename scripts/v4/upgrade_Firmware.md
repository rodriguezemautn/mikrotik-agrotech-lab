¡Absolutamente\! La actualización a **RouterOS 6.49.x LTS** es un paso excelente para aumentar la estabilidad y obtener las últimas correcciones de errores, sin alterar la configuración de licencia (que está ligada al *Software ID* y *Serial Number* del equipo).

El proceso de actualización en MikroTik es seguro y estándar. Dada tu salida de `ping` y `export`, asumo que tienes **conectividad a Internet** y el equipo está operativo, lo cual simplifica la tarea.

Aquí tienes la guía completa para actualizar tus **RB951Ui-2HnD** y **SXTG-2HnD** a la versión 6.49.x, utilizando el método más rápido y recomendado: **Actualización directa desde la terminal por Internet**.

-----

## 🛠️ Procedimiento de Actualización a RouterOS 6.49.x LTS

Este método utiliza el comando `system package update` para descargar y aplicar la última versión **Long-Term Support (LTS)** disponible. La versión 6.49.12 es la última LTS de la rama 6.x.

### Paso 1: Verificar la Conectividad y la Versión Actual

Verifica que el equipo tiene conectividad activa a los servidores de MikroTik. Ya has confirmado que puedes hacer `ping 8.8.8.8`.

```bash
# Comando de verificación (Debe mostrar la versión actual y si hay una disponible)
/system package update check-for-updates
```

**Resultado esperado si hay una versión disponible:**

```
       status: New version is available
      version: 6.49.12
     installed-version: 6.48.3
```

### Paso 2: Descargar e Instalar la Actualización

Una vez confirmada la nueva versión (6.49.12), procede con la descarga e instalación.

```bash
# Descarga la versión más reciente del canal "long-term" e inicia la instalación.
/system package update install
```

El router descargará el paquete y te pedirá confirmación para reiniciar.

**Ejemplo de diálogo:**

```
Do you want to continue? [y/n] 
```

Escribe `y` y presiona Enter. El equipo se reiniciará automáticamente. **El proceso de actualización toma de 1 a 3 minutos.**

### Paso 3: Actualizar el RouterBOOT (Firmware)

La licencia de RouterOS está vinculada al **Software ID** (en tu caso, `LLBU-WG2H`), no a la versión de RouterOS. Sin embargo, por seguridad y compatibilidad, siempre es crucial actualizar el *firmware* del dispositivo (*RouterBOOT*) a su última versión.

Una vez que el router reinicie con RouterOS 6.49.x:

1.  **Verifica la versión actual del firmware:**

    ```bash
    /system routerboard print
    ```

    (Busca las líneas `current-firmware` y `upgrade-firmware`)

2.  **Actualiza el RouterBOOT:**

    ```bash
    /system routerboard upgrade
    ```

    Escribe `y` y presiona Enter.

3.  **Reinicia el equipo (obligatorio para aplicar el RouterBOOT):**

    ```bash
    /system reboot
    ```

### Paso 4: Verificación Final

Tras el segundo reinicio, verifica que la versión de RouterOS y el RouterBOOT se hayan actualizado.

```bash
/system resource print
```

(Debe mostrar `version: 6.49.12`)

```bash
/system routerboard print
```

(Debe mostrar que `current-firmware` es igual a `upgrade-firmware`)

-----

## 📝 Nota sobre la Licencia

**No hay riesgo de perder la licencia.**

  * **Licencia:** Las licencias de MikroTik (como la Nivel 4, estándar en los RB951 y SXT) están vinculadas al **Software ID** y no caducan ni se degradan al actualizar dentro de la misma rama mayor (de 6.48.3 a 6.49.12).
  * **Configuración:** La configuración existente se mantiene después de la actualización y los reboots.

**Recomendación:** Después de realizar la actualización y el *reboot* final, aplica los **scripts `.rsc` optimizados** que te proporcioné previamente, para asegurar que la configuración de Q-in-Q, Bridge VLAN Filtering y MTU 1590 esté configurada con la sintaxis de la versión 6.49.x y cumpla con todos los requisitos del proyecto Agrotech.