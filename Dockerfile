# syntax=docker/dockerfile:1.7
FROM eclipse-temurin:11-jre-alpine

LABEL org.opencontainers.image.title="Pixelmon Forge Server" \
      org.opencontainers.image.description="Minecraft 1.16.5 + Forge 36.2.34 + Pixelmon 9.1.13 + QuickHomes" \
      org.opencontainers.image.source="https://github.com/CriticalWombat/Pixelmon-Docker" \
      maintainer="CriticalWombat"

# ---- Build-time versions ----
ARG MC_VERSION=1.16.5
ARG FORGE_VER=36.2.34
ARG FORGE_INSTALLER="forge-${MC_VERSION}-${FORGE_VER}-installer.jar"
ARG FORGE_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VER}/${FORGE_INSTALLER}"

# Pixelmon & QuickHomes (direct, non-gated links)
ARG PIXELMON_FILE="Pixelmon-1.16.5-9.1.13-universal.jar"
ARG PIXELMON_URL="https://cdn.modrinth.com/data/59ZceYlU/versions/CPLYWxEL/Pixelmon-1.16.5-9.1.13-universal.jar"

ARG QUICKHOMES_FILE="quickhomes-1.16.5-1.3.0-forge.jar"
ARG QUICKHOMES_URL="https://github.com/itsmeow/QuickHomes/releases/download/1.16.5-1.3.0/quickhomes-1.16.5-1.3.0-forge.jar"

# Optional checksums
ARG FORGE_SHA256=""
ARG PIXELMON_SHA256=""
ARG QUICKHOMES_SHA256=""

# ---- Runtime config ----
ENV EULA="false" \
    SERVER_PORT=25565 \
    RCON_ENABLE=false \
    RCON_PORT=25575 \
    Xms=1G \
    Xmx=4G

# ---- Packages & user (run as root; we'll drop later) ----
RUN set -eux; \
    apk add --no-cache bash curl tini netcat-openbsd ca-certificates su-exec; update-ca-certificates; \
    adduser -D -h /home/minecraft -u 10001 minecraft; \
    mkdir -p /server /mods /data; \
    chown -R minecraft:minecraft /server /mods;
    # don't chown /data here; it may be a bind mount at runtime

WORKDIR /server

# Robust curl defaults
ENV CURL_RETRY="--retry 5 --retry-connrefused --retry-delay 2 --max-time 600"

# ---- Forge install ----
RUN set -eux; \
    curl -fLsS ${CURL_RETRY} "${FORGE_URL}" -o "${FORGE_INSTALLER}"; \
    if [ -n "${FORGE_SHA256}" ]; then echo "${FORGE_SHA256}  ${FORGE_INSTALLER}" | sha256sum -c -; fi; \
    java -jar "${FORGE_INSTALLER}" --installServer; \
    FORGE_JAR="$(ls -1 forge-${MC_VERSION}-${FORGE_VER}.?* | head -n1)"; \
    ln -s "${FORGE_JAR}" forge.jar

# ---- Mods ----
RUN set -eux; \
    mkdir -p /mods; \
    curl -fLsS ${CURL_RETRY} "${PIXELMON_URL}"  -o "/mods/${PIXELMON_FILE}"; \
    if [ -n "${PIXELMON_SHA256}" ]; then echo "${PIXELMON_SHA256}  /mods/${PIXELMON_FILE}" | sha256sum -c -; fi; \
    curl -fLsS ${CURL_RETRY} "${QUICKHOMES_URL}" -o "/mods/${QUICKHOMES_FILE}"; \
    if [ -n "${QUICKHOMES_SHA256}" ]; then echo "${QUICKHOMES_SHA256}  /mods/${QUICKHOMES_FILE}" | sha256sum -c -; fi

# ---- Scripts ----
COPY start-server.sh /usr/local/bin/start-server
COPY entrypoint.sh    /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/start-server /usr/local/bin/entrypoint && \
    chown minecraft:minecraft /usr/local/bin/start-server

EXPOSE 25565/tcp
VOLUME ["/data", "/mods"]

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD /bin/sh -c "nc -z 127.0.0.1 ${SERVER_PORT}"

# tini as PID1 -> entrypoint (runs as root, then drops to minecraft)
ENTRYPOINT ["/sbin/tini","--","/usr/local/bin/entrypoint"]
# no CMD; entrypoint will exec start-server
