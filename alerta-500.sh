#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Vigila todos los logs de dominio de DirectAdmin+LiteSpeed y genera un correo
# cuando detecta:
#   · código HTTP 500            (access logs)
#   · “PHP Fatal error”          (error logs)
#   · “Access denied”            (error logs / MySQL)
# El mensaje incluye dominio y fichero/URL implicados.
# ---------------------------------------------------------------------------

EMAIL="tu@correo.com"                 # ← destinatario de alertas
LOGBASE="/var/log/httpd/domains"      # ← carpeta de *.log y *.error.log

shopt -s nullglob                     # evita literales vacíos en bucles
declare -A WATCHERS                   # mapa logfile → PID del tail -F

# ---------- Funciones ------------------------------------------------------

extract_target() {                    # $1 = línea completa del log
  local line="$1" target="N/A"

  # 1) Fatal error: ... in /ruta/fichero.php on line N
  if [[ $line =~ \ in\ ([^[:space:]]+\.php) ]]; then
      target="${BASH_REMATCH[1]}"

  # 2) Access log: "GET /ruta/archivo.php HTTP/1.1" 500
  elif [[ $line =~ \"[A-Z]+\ ([^[:space:]]+)\ HTTP/ ]]; then
      target="${BASH_REMATCH[1]}"
  fi
  printf '%s' "$target"
}

send_mail() {                         # $1 = logfile, $2 = línea completa
  local dom="$(basename "$1" .log)"
  local culprit; culprit="$(extract_target "$2")"

  printf '%s\n\nDominio : %s\nArchivo : %s\nServidor: %s\n' \
         "$2" "$dom" "$culprit" "$(hostname -f)" \
    | mail -s "[ALERTA] $dom ⇢ $culprit" "$EMAIL"
}

start_tail() {                        # crea watcher para un log concreto
  local lf="$1"
  tail -n0 -F "$lf" | while read -r l; do
    if [[   "$l" =~ [[:space:]]500[[:space:]]  ]] \
       || [[ "$l" == *"PHP Fatal error"*      ]] \
       || [[ "$l" == *"Access denied"*        ]]; then
         send_mail "$lf" "$l"
    fi
  done &
  WATCHERS["$lf"]=$!
}

scan_logs() {                         # detecta logs nuevos cada pasada
  for lf in "$LOGBASE"/*.log "$LOGBASE"/*.error.log; do
    [[ -e $lf && -z ${WATCHERS["$lf"]+x} ]] && start_tail "$lf"
  done
}

cleanup() {                           # mata todos los tail al salir
  for p in "${WATCHERS[@]}"; do kill "$p" 2>/dev/null; done
}
trap cleanup EXIT SIGINT SIGTERM

# ---------- Bucle de servicio ---------------------------------------------
while true; do
  scan_logs          # arranca watchers faltantes
  sleep 300          # re-escaneo cada 5 min para captar dominios nuevos
done
