# syntax=docker/dockerfile:1

ARG ALPINE_VERSION="3.24.2"
ARG S6_OVERLAY_VERSION="3.2.3.2"
ARG AWGTUN_VERSION="3.1.20260828"
ARG AWGCTL_VERSION="3.1.20260812"
ARG XRAY_VERSION="26.3.27"


FROM alpine:${ALPINE_VERSION} AS builder

ARG AWGTUN_VERSION
ARG AWGCTL_VERSION

RUN apk add --no-cache git go linux-headers make

WORKDIR /src/awgtun

RUN git clone -b "v${AWGTUN_VERSION}" https://github.com/amnezia-vpn/amneziawg-go.git . \
    && make && make install DESTDIR=/app \
    && mv /app/usr/bin/amneziawg-go /app/usr/bin/awgtun

WORKDIR /src/awg

RUN git clone -b "v${AWGCTL_VERSION}" https://github.com/amnezia-vpn/amneziawg-tools.git . \
    && cd src && make && make install DESTDIR=/app \
    && mv /app/usr/bin/awg /app/usr/bin/awg && rm -r /app/usr/share

WORKDIR /


FROM alpine:${ALPINE_VERSION}

ARG S6_OVERLAY_VERSION
ARG XRAY_VERSION

RUN apk add --no-cache ca-certificates iproute2 ipset iptables xz

WORKDIR /tmp

RUN set -e; \
    arch="$(arch)"; \
    case "${arch}" in \
      "aarch64") \
        ;; \
      "x86_64") \
        ;; \
      *) \
        echo >&2 "error: unsupported architecture"; \
        exit 1; \
        ;; \
    esac; \
    wget -q "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" -O s6-overlay.tar.xz \
    && tar -xJpf s6-overlay.tar.xz --directory / \
    && rm -rf *

RUN set -e; \
    arch="$(arch)"; \
    case "${arch}" in \
      "aarch64") \
        ;; \
      "x86_64") \
        ;; \
      *) \
        echo >&2 "error: unsupported architecture"; \
        exit 1; \
        ;; \
    esac; \
    wget -q "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${arch}.tar.xz" -O s6-overlay.tar.xz \
    && tar -xJpf s6-overlay.tar.xz --directory / \
    && rm -rf *

RUN set -e; \
    arch="$(arch)"; \
    case "${arch}" in \
      "aarch64") \
        arch="arm64-v8a"; \
        ;; \
      "x86_64") \
        arch="64"; \
        ;; \
      *) \
        echo >&2 "error: unsupported architecture"; \
        exit 1; \
        ;; \
    esac; \
    wget -q "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${arch}.zip" -O xray.zip \
    && unzip xray.zip \
    && chmod a+x xray \
    && mv xray /usr/bin \
    && mkdir -p /usr/share/xray \
    && mv geo*.dat /usr/share/xray \
    && rm -rf *

COPY --from=builder /app/usr/bin/* /usr/bin/
COPY ./root/ /
RUN chmod a+x /etc/s6-overlay/scripts/*.sh
RUN mkdir -p /etc/proxy /var/lib/proxy/awg.d /var/lib/proxy/xray.d

WORKDIR /
VOLUME /var/lib/proxy/awg.d
VOLUME /var/lib/proxy/xray.d

ENTRYPOINT ["/init"]
CMD []
