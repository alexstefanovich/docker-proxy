#!/usr/bin/env sh

set -e

function tunnels_up() {
  for tunnel_conf in $(find /var/lib/proxy/awg.d -type f -name "*.conf"); do
    local tunnel_name tunnel_conf_up

    tunnel_name="$(basename "${tunnel_conf}")"
    tunnel_name="${tunnel_name%.*}"
    tunnel_conf_up="${tunnel_conf}.up.sh"

    awgtun "${tunnel_name}" &> /dev/null
    awg setconf "${tunnel_name}" "${tunnel_conf}"

    if [ -e "${tunnel_conf_up}" ]; then
      sh "${tunnel_conf_up}" "${tunnel_name}"
    fi
  done
}

tunnels_up
