FROM alpine:3.11

LABEL maintainer "CriticalWombat"

EXPOSE 30050/tcp
EXPOSE 30050/udp

ENV Xms=1G
ENV Xmx=4G

RUN apk add --update --no-cache openjdk11 wget nfs-utils nss && \
    mkdir -p /pixelmon/mods && mkdir /data && \
    wget -O /pixelmon/forge-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/1.16.5-36.2.39/forge-1.16.5-36.2.39-installer.jar && \
    wget -O /pixelmon/mods/spongeforge.jar https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongeforge/1.16.5-36.2.5-8.1.0-RC1202/spongeforge-1.16.5-36.2.5-8.1.0-RC1202-universal.jar && \
    wget -O /pixelmon/mods/Pixelmon-server.jar https://dl.reforged.gg/3BvPBUv && \
    cd /pixelmon && \
    echo eula=true > eula.txt && \
    java -jar /pixelmon/forge-installer.jar --installServer && \
    ln -s forge-1.16.5*.jar forge.jar
ADD start-server.sh /pixelmon

WORKDIR /data
VOLUME /data

CMD ["/bin/sh", "/pixelmon/start-server.sh"]
