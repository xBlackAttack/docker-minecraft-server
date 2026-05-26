FROM --platform=amd64 didstopia/base:alpine-3.23

LABEL maintainer="Didstopia <support@didstopia.com>"

# System variables for use with installation
ENV _JAVA_OPTIONS "-XX:+UseG1GC -Djava.security.egd=file:/dev/urandom"
ENV PATH "${PATH}:/opt/jdk/bin"
ENV LANG "C.UTF-8"

# Minecraft server specific environment variables
ENV MINECRAFT_SERVER_DOWNLOAD_URL "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
ENV MINECRAFT_SERVER_MEMORY_MIN "1G"
ENV MINECRAFT_SERVER_MEMORY_MAX "1G"
ENV MINECRAFT_SERVER_AGREE_EULA "true"
ENV MINECRAFT_SERVER_ARGUMENTS "nogui"
ENV MINECRAFT_SERVER_RCON_ENABLE "false"
ENV MINECRAFT_SERVER_RCON_PORT "25575"
ENV MINECRAFT_SERVER_RCON_PASSWORD ""

# Install dependencies
RUN apk --no-cache add \
    wget \
    ca-certificates \
    bash \
    curl \
    jq

# Install Java (latest Minecraft needs Java 25, available in the 3.23 repos)
RUN apk --no-cache add openjdk25-jre

# Install the latest Minecraft server, resolved through Mojang's version manifest
RUN set -eux; \
    MANIFEST="$(curl -sSL "$MINECRAFT_SERVER_DOWNLOAD_URL")"; \
    RELEASE="$(echo "$MANIFEST" | jq -r '.latest.release')"; \
    VERSION_URL="$(echo "$MANIFEST" | jq -r --arg v "$RELEASE" '.versions[] | select(.id==$v) | .url')"; \
    SERVER_URL="$(curl -sSL "$VERSION_URL" | jq -r '.downloads.server.url')"; \
    wget --quiet -O /server.jar "$SERVER_URL"
RUN chmod a+rwx /server.jar

# Copy the startup scripts (which also handles automatic updates)
ADD start.sh /start.sh
RUN chmod +x /start.sh

# Run as the "docker" user by default
ENV PGID 1000
ENV PUID 1000

# Expose the default server port
EXPOSE 25565

# Expose the default RCON port
EXPOSE 25575

# Export the default volume (already exported in base image, but QNAP doesn't detect this)
VOLUME ["/app"]

# Set the startup command
CMD ["/bin/bash", "/start.sh"]
