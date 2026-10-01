#!/usr/bin/env sh

set -e

SILENTLY="${SILENTLY:-"false"}"

level="info"
if [ "${SILENTLY}" = "true" ]; then
  level="none"
fi

cat > /etc/proxy/xray.json <<EOF
{
  "log": {
    "logLevel": "${level}",
    "dnsLog": true
  }
}
EOF

set -- xray run -config /etc/proxy/xray.json -confdir /var/lib/proxy/xray.d

exec "${@}"
