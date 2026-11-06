# UnrealIRCd Docker

A lightweight, multi-architecture (`linux/amd64`, `linux/arm64`) Docker image running the latest release of [UnrealIRCd](https://www.unrealircd.org/) on Alpine Linux.

```bash
docker pull ghcr.io/bradleyshaw/unrealircd-docker:latest
```

---

## Quick Start

### 1. Create Directories & Permissions

UnrealIRCd runs as an unprivileged user (`UID 10000`). Create your host folders and ensure the `data` directory is writable for persistent state (bans, channel history, reputation):

```bash
mkdir -p conf/tls data
sudo chown -R 10000:10000 data
```

### 2. Add Configuration

Place your `unrealircd.conf` inside `./conf/`. Make sure your `listen` blocks match the exposed ports:

```text
/* Client Connections */
listen { ip *; port 6667; };
listen { ip *; port 6697; options { tls; }; };

/* Server-to-Server Linking */
listen { ip *; port 6900; options { tls; serversonly; }; };
```

### 3. Run with Docker Compose

Save the following as `docker-compose.yml`:

```yaml
services:
  unrealircd:
    image: ghcr.io/bradleyshaw/unrealircd-docker:latest
    container_name: unrealircd
    restart: unless-stopped
    ports:
      - "6667:6667"   # Plaintext client
      - "6697:6697"   # TLS client
      - "6900:6900"   # TLS server-to-server linking
    volumes:
      - ./conf:/home/ircd/unrealircd/conf:ro
      - ./data:/home/ircd/unrealircd/data
```

Start the server:

```bash
docker compose up -d
docker compose logs -f
```

---

## Exposed Ports

| Port | Protocol | Purpose |
| :--- | :--- | :--- |
| `6667` | TCP (Plaintext) | Standard IRC client port |
| `6697` | TCP (TLS) | Secure IRC client port |
| `6900` | TCP (TLS) | Server-to-Server (`S2S`) linking & services (Anope/Atheme) |

---

## Handy Commands

```bash
# Test configuration syntax
docker exec -it unrealircd /home/ircd/unrealircd/bin/unrealircd -t

# Reload configuration without disconnecting users
docker exec -it unrealircd /home/ircd/unrealircd/bin/unrealircd rehash

# Check server status
docker exec -it unrealircd /home/ircd/unrealircd/bin/unrealircd status
```

---

## License

This container distribution is licensed under the [MIT License](LICENSE).  
UnrealIRCd is licensed under the [GPLv2](https://www.unrealircd.org/).