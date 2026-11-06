#!/bin/sh
set -e

PUID=${PUID:-10000}
PGID=${PGID:-10000}

if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
    echo "ERROR: UnrealIRCd refuses to run as root. PUID and PGID must not be 0." >&2
    exit 1
fi

CURRENT_UID=$(id -u ircd)
CURRENT_GID=$(id -g ircd)

if [ "$PGID" -ne "$CURRENT_GID" ]; then
    groupmod -o -g "$PGID" ircd
fi

if [ "$PUID" -ne "$CURRENT_UID" ]; then
    usermod -o -u "$PUID" ircd
fi

# Ensure conf directory exists
mkdir -p /home/ircd/unrealircd/conf

# Force-sync modules.default.conf from the container image
if [ -f "/home/ircd/unrealircd/conf.default/modules.default.conf" ]; then
    cp -f /home/ircd/unrealircd/conf.default/modules.default.conf /home/ircd/unrealircd/conf/modules.default.conf
fi

# Also sync help files if UnrealIRCd looks for them in conf
if [ -d "/home/ircd/unrealircd/conf.default/help" ]; then
    cp -rf /home/ircd/unrealircd/conf.default/help /home/ircd/unrealircd/conf/
fi

# Fix ownership
chown -R ircd:ircd /home/ircd/unrealircd

if [ -d "/home/ircd/unrealircd/conf" ]; then
    chown -R ircd:ircd /home/ircd/unrealircd/conf
fi

if [ -d "/home/ircd/unrealircd/data" ]; then
    chown -R ircd:ircd /home/ircd/unrealircd/data
fi

if [ -d "/build" ]; then
    chown -R ircd:ircd /build
fi

exec su-exec ircd "$@"