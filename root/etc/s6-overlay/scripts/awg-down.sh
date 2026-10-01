#!/usr/bin/env sh

set -e

function tunnels_down() {
  for tunnel_conf in $(find /var/lib/proxy/awg.d -type f -name "*.conf"); do
    local tunnel_name tunnel_conf_down

    tunnel_name="$(basename "${tunnel_conf}")"
    tunnel_name="${tunnel_name%.*}"
    tunnel_conf_down="${tunnel_conf}.down.sh"

    if [ -e "${tunnel_conf_down}" ]; then
      sh "${tunnel_conf_down}" "${tunnel_name}"
    fi
  done
}

tunnels_down
