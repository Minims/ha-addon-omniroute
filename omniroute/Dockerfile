# Pin to an exact upstream image. Renovate watches this declaration.
# renovate: datasource=docker depName=diegosouzapw/omniroute
ARG OMNIROUTE_VERSION="3.8.51-web"
FROM diegosouzapw/omniroute:${OMNIROUTE_VERSION}

ARG BUILD_VERSION
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="aarch64"

# The upstream image runs as non-root. Root is needed only to make Home
# Assistant's persistent /data volume writable before OmniRoute starts.
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends jq openssl gosu \
  && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /
RUN chmod 0755 /usr/local/bin/ha-omniroute-entrypoint

EXPOSE 20128
ENTRYPOINT ["/usr/local/bin/ha-omniroute-entrypoint"]

# Preserve the upstream permission check and standalone launcher.
CMD ["/app/check-permissions.sh", "node", "dev/run-standalone.mjs"]
