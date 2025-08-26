# Pixelmon Forge Server (Docker)

Minecraft **1.16.5** server with **Forge 36.2.34**, **Pixelmon Reforged 9.1.13**, and **QuickHomes** (server-side `/sethome` + `/home`) — packaged for Docker with sane defaults, graceful shutdowns, and built-in volume permission fixes.

- Non-root runtime (user `minecraft`, uid `10001`)
- `tini` as PID 1 for clean signal handling
- Healthcheck to detect when the server is actually listening
- Version-pinned defaults, but overridable via build args
- Seeds and persists world/config/mods under `/data`
- EntryPoint fixes `/data` ownership on first run if needed, then drops privileges

---

## Versions (defaults)

| Component  | Version                         | Notes                                             |
|-----------:|:--------------------------------|:--------------------------------------------------|
| Minecraft  | **1.16.5**                      | Pixelmon 9.1.x line                               |
| Forge      | **36.2.34**                     | Pixelmon’s recommended loader for 1.16.5          |
| Pixelmon   | **9.1.13**                      | 1.16.5 compatible                                 |
| QuickHomes | **1.16.5-1.3.0 (Forge)**        | Server-side `/home` + `/sethome` only             |
| Java (JRE) | **11** (Temurin, Alpine base)   | Stable for MC 1.16.5 + Forge 36.2.x              |

You can change these via build args (see **Build**).

---

## Repository Layout

```
.
├── Dockerfile
├── compose.yaml      # Optional for docker compose instances
├── entrypoint.sh     # fixes /data perms, drops to non-root, starts the server script
└── start-server.sh   # writes eula, seeds mods, generates server.properties, starts Forge
```

---

## Build

> **Prereqs:** Docker 20+ recommended.

### Default (pinned) build

```bash
docker build -t pixelmon-forge:9.1.13 .
```

### Override versions/URLs at build time

```bash
docker build \
  --build-arg MC_VERSION=1.16.5 \
  --build-arg FORGE_VER=36.2.34 \
  --build-arg PIXELMON_FILE="Pixelmon-1.16.5-9.1.13-universal.jar" \
  --build-arg PIXELMON_URL="https://cdn.modrinth.com/data/59ZceYlU/versions/CPLYWxEL/Pixelmon-1.16.5-9.1.13-universal.jar" \
  --build-arg QUICKHOMES_FILE="quickhomes-1.16.5-1.3.0-forge.jar" \
  --build-arg QUICKHOMES_URL="https://github.com/itsmeow/QuickHomes/releases/download/1.16.5-1.3.0/quickhomes-1.16.5-1.3.0-forge.jar" \
  -t pixelmon-forge:custom .
```

### (Optional) Enforce checksums

```bash
docker build \
  --build-arg FORGE_SHA256="<sha256>" \
  --build-arg PIXELMON_SHA256="<sha256>" \
  --build-arg QUICKHOMES_SHA256="<sha256>" \
  -t pixelmon-forge:verified .
```

Compute hashes with `sha256sum <file>`.

---

## Run (Quickstart)

One-liner:

```bash
docker run -d --name pixelmon \
  -e EULA=true -e Xms=2G -e Xmx=4G -e SERVER_PORT=25565 \
  -p 25565:25565 \
  -v "$PWD/data":/data \
  pixelmon-forge:9.1.13
```

Follow logs:

```bash
docker logs -f pixelmon
```

You should see Forge and Pixelmon load, then: `Done (X.XXXs)! For help, type "help"`.

### Environment Variables

| Variable       | Default | Purpose                                        |
|----------------|---------|------------------------------------------------|
| `EULA`         | `false` | **Must be `true`** to run (writes `eula.txt`)  |
| `SERVER_PORT`  | `25565` | Minecraft server port inside the container     |
| `RCON_ENABLE`  | `false` | Enable RCON if `true`                          |
| `RCON_PORT`    | `25575` | RCON port (used if enabled)                    |
| `Xms`          | `1G`    | JVM min heap size                              |
| `Xmx`          | `4G`    | JVM max heap size                              |

### Volumes

- `/data` — **persistent** world, configs, logs, and your effective mods  
- `/mods` — image-baked mods (seeded into `/data/mods` on first run)

On first start, the container seeds baked mods into `/data/mods` **if missing**. After that, manage `/data/mods` yourself.

---

## Docker Compose (optional)

```yaml
services:
  pixelmon:
    image: pixelmon-forge:9.1.13
    container_name: pixelmon
    restart: unless-stopped
    environment:
      EULA: "true"
      Xms: 2G
      Xmx: 6G
      SERVER_PORT: 25565
      RCON_ENABLE: "false"
    ports:
      - "25565:25565"
    volumes:
      - ./data:/data
```

Start with:

```bash
docker compose up -d
```

---

## Client Requirements

- Install CurseForge Launcher from **curseforge.overwolf.com** (Windows/mac). Open it and click Minecraft.
- Install the **Pixelmon Modpack (1.16.5)**
- Go to Browse Modpacks → search “Pixelmon Modpack *by PixelmonMod* → install.
- In the profile’s Versions/Settings, set Pixelmon = 9.1.13 and ensure Forge = 36.2.x (to match your server).
- Click Play from the Pixelmon profile.
- Assuming you are on the same network as your docker containers bridged container, In Minecraft → Multiplayer → Add Server → enter your server’s IP (and port if not 25565). Connect.

Players **must** use a matching modded client:

- Minecraft **1.16.5**
- Forge **36.2.x** (36.2.34 recommended)
- Pixelmon **9.1.13**

The **CurseForge Launcher** Pixelmon Modpack (1.16.5) modpack is the easiest path.  
**QuickHomes** is server-side only (clients don’t need it).

---

## What’s Included (Server Image)

- **Forge** installed via official installer; stable symlink `forge.jar`
- **Pixelmon 9.1.13** baked into `/mods` (seeded to `/data/mods` on first run)
- **QuickHomes 1.16.5-1.3.0** for `/sethome` + `/home`
- **Healthcheck**:
  ```dockerfile
  HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
    CMD /bin/sh -c "nc -z 127.0.0.1 ${SERVER_PORT}"
  ```
- **Graceful startup/shutdown**:
  - `tini` as PID 1 (reaps zombies, forwards signals)
  - `start-server.sh` ends with `exec java ...` so signals reach the JVM
- **Permissions bootstrap**:
  - `entrypoint.sh` ensures `/data` exists and is writable by uid `10001`; fixes ownership **if needed**; then drops to `minecraft` user

---

## Data Layout & Backup

Everything important is under `/data`:

```
/data/
├── world/             # world and region data
├── config/            # mod & server configs
├── logs/              # server logs
├── mods/              # effective mods (seeded on first run)
└── server.properties  # main server config
```

To back up: stop the container, archive the `/data` directory.

---

## Updating Components

All key versions are controlled by build args in the Dockerfile:

```dockerfile
ARG MC_VERSION=1.16.5
ARG FORGE_VER=36.2.34
ARG PIXELMON_FILE="Pixelmon-1.16.5-9.1.13-universal.jar"
ARG PIXELMON_URL="https://cdn.modrinth.com/data/59ZceYlU/versions/CPLYWxEL/Pixelmon-1.16.5-9.1.13-universal.jar"
ARG QUICKHOMES_FILE="quickhomes-1.16.5-1.3.0-forge.jar"
ARG QUICKHOMES_URL="https://github.com/itsmeow/QuickHomes/releases/download/1.16.5-1.3.0/quickhomes-1.16.5-1.3.0-forge.jar"
```

When upgrading Pixelmon, ensure it still targets **MC 1.16.5 + Forge 36.2.x**.  
If a source blocks automated downloads, you can **COPY** the jar from build context or **mount it** into `/data/mods` at runtime.

---

## RCON (optional)

Enable RCON:

```bash
docker run -d --name pixelmon \
  -e EULA=true -e SERVER_PORT=25565 \
  -e RCON_ENABLE=true -e RCON_PORT=25575 \
  -p 25565:25565 -p 25575:25575 \
  -v "$PWD/data":/data \
  pixelmon-forge:9.1.13
```

After first run, set `rcon.password` in `/data/server.properties` and connect with an RCON client to `<host>:25575`.

---

## Troubleshooting

**403 during build (mod downloads)**  
Some hosts gate downloads. This image uses CI-friendly URLs (Modrinth/GitHub). If you change to a gated source, either **COPY** the file in your build or **mount** it at runtime.

**Permission denied under `/data`**  
The entrypoint auto-fixes ownership on first run. If disabled, ensure your host folder is owned by uid/gid `10001`:
```bash
sudo chown -R 10001:10001 ./data
```

**Port already in use**  
Change the host port: `-p 25566:25565`.

**Client can’t join**  
Ensure client has **Forge 36.2.x** and **Pixelmon 9.1.13** for **MC 1.16.5**. Vanilla clients won’t work.

---

## Security Notes

- Server runs as a **non-root** user after startup
- Only port **25565/tcp** is exposed by default
- If exposing to the internet, consider a player/IP allowlist and/or DDoS protection

---

## License & Distribution

- This repository provides Docker build scripts and configuration.  
- Mods are downloaded at build time from their respective sources. Respect each project’s license.  
- If distribution rules change, prefer mounting the mod jars at runtime or copying them from your local build context.

---

## Contributing

PRs welcome for:

- Version bumps (Forge/Pixelmon/QuickHomes)
- Additional optional server-side QoL mods
- Improved healthchecks or diagnostics

---

## Changelog

- **v1.0.0**
  - Initial release: MC 1.16.5 + Forge 36.2.34 + Pixelmon 9.1.13 + QuickHomes 1.16.5-1.3.0  