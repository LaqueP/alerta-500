# Alerta de Errores para LiteSpeed + DirectAdmin

Pequeño *daemon* en **Bash** que monitoriza los logs de dominio en servidores AlmaLinux con LiteSpeed Web Server y DirectAdmin, y envía notificaciones por correo electrónico cuando detecta:

* **HTTP 500** en *access logs*
* **PHP Fatal error** en *error logs*
* **Access denied** en *error logs* (p. ej. MySQL)

Incluye en el aviso el **dominio** y el **fichero/URL** implicados, para un diagnóstico inmediato.

---

## Índice

1. [Características](#características)
2. [Requisitos](#requisitos)
3. [Instalación](#instalación)
4. [Configuración](#configuración)
5. [Registro como servicio](#registro-como-servicio)
6. [Pruebas rápidas](#pruebas-rápidas)
7. [Personalización](#personalización)
8. [Contribuir](#contribuir)
9. [Licencia](#licencia)

---

## Características

| Función              | Detalle                                                                               |
| -------------------- | ------------------------------------------------------------------------------------- |
| Detección de eventos | `HTTP 500`, `PHP Fatal error`, `Access denied`                                        |
| Ámbito               | Todos los `*.log` y `*.error.log` en `LOGBASE` (por defecto `/var/log/httpd/domains`) |
| Inclusión en correo  | Dominio, fichero/URL, línea exacta del log, hostname                                  |
| Auto‑descubrimiento  | Nueva exploración cada 5 min para captar v‑hosts recién creados                       |
| Ligero               | Sólo depende de Bash, `tail` y `mailx`                                                |

---

## Requisitos

* AlmaLinux 8/9 (o equivalente) con **systemd**
* Paquetes base: `bash`, `coreutils`, `grep`, `mailx`
* MTA operativo (Postfix, Exim, sSMTP, msmtp…) o relay SMTP
* Acceso *root* para instalar el script y el servicio

---

## Instalación

```bash
# 1) Clona el repositorio
sudo git clone https://github.com/tuusuario/alerta-lsws.git /opt/alerta-lsws
cd /opt/alerta-lsws

# 2) Copia el script al PATH del sistema
sudo cp alerta-500.sh /usr/local/bin/

# 3) Dale permisos de ejecución
sudo chmod 755 /usr/local/bin/alerta-500.sh
```

---

## Configuración

Abre `alerta-500.sh` y ajusta las dos variables del principio:

```bash
EMAIL="admin@tu-dominio.com"   # Destinatario de alertas
LOGBASE="/var/log/httpd/domains"  # Carpeta de logs de DirectAdmin
```

> **Nota**: si tus logs están en `/home/USUARIO/domains/DOM/logs`, cambia `LOGBASE` en consecuencia.

---

## Registro como servicio

Copia la unidad de servicio incluida y actívala:

```bash
sudo cp alerta-500.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now alerta-500
```

Comandos útiles:

```bash
systemctl status alerta-500        # Ver estado
journalctl -fu alerta-500          # Log en tiempo real
```

<details>
<summary>Contenido de <code>alerta-500.service</code></summary>

```ini
[Unit]
Description=Alertas HTTP 500 / PHP Fatal / Access denied (LiteSpeed-DirectAdmin)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/alerta-500.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

</details>

---

## Pruebas rápidas

1. **Fatal error de PHP**

   ```php
   <?php die('test fatal'); ?>
   ```

   Navega a la página y verifica la llegada del correo.

2. **HTTP 500**

   En una página de pruebas:

   ```php
   <?php header("HTTP/1.1 500 Internal Server Error"); ?>
   ```

   o visita una URL inexistente en tu tienda.

---

## Personalización

| Necesidad                | Cómo hacerlo                                                             |
| ------------------------ | ------------------------------------------------------------------------ |
| Escaneo más frecuente    | Cambia `sleep 300` (segundos) al final del script                        |
| Filtrar rutas o patrones | Añade condiciones `&& [[ $l != *"/wp-cron.php"* ]]` antes de `send_mail` |
| Detectar más eventos     | Añade tus cadenas al `if` en `start_tail()`                              |
| Cambiar asunto del mail  | Modifica `send_mail()`                                                   |

---

## Contribuir

1. Haz un *fork* del proyecto
2. Crea una rama con tu mejora: `git checkout -b mi-mejora`
3. Haz *commit* de tus cambios: `git commit -am 'Añade nueva función'`
4. Sube la rama: `git push origin mi-mejora`
5. Abre un *Pull Request*

---

## Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Consulta el archivo `LICENSE` para más detalles.
