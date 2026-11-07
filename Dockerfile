# --- Build Stage ---
FROM alpine:3.20 AS builder

ARG UNREAL_VERSION=6.2.7.1

RUN apk add --no-cache \
    build-base \
    openssl \
    openssl-dev \
    c-ares-dev \
    pcre2-dev \
    argon2-dev \
    libsodium-dev \
    curl \
    file

# 1. Create the non-root user in the builder stage
RUN adduser -D -u 10000 ircd

# 2. Prepare the build directory and grant ownership to ircd
WORKDIR /build
RUN chown -R ircd:ircd /build

# 3. Switch to the non-root user before downloading, configuring, and compiling
USER ircd

RUN curl -fsSL "https://www.unrealircd.org/downloads/unrealircd-${UNREAL_VERSION}.tar.gz" -o unrealircd.tar.gz && \
    tar -xzf unrealircd.tar.gz --strip-components=1

RUN ./Config --enable-ssl \
             --enable-ziplinks \
             --with-showlistmodes \
             --with-listen=5 \
             --with-dpath=/home/ircd/unrealircd \
             --with-spaths && \
    make -j$(nproc) && \
    make install

# --- Runtime Stage ---
FROM alpine:3.20

RUN apk add --no-cache \
    openssl \
    openssl-dev \
    c-ares \
    c-ares-dev \
    pcre2 \
    pcre2-dev \
    argon2-libs \
    libsodium \
    libsodium-dev \
    ca-certificates \
    su-exec \
    shadow \
    curl \
    file \
    patch \
    build-base

# Create base ircd user and group (defaults to 10000)
RUN adduser -D -u 10000 ircd

WORKDIR /home/ircd/unrealircd
COPY --from=builder --chown=ircd:ircd /home/ircd/unrealircd /home/ircd/unrealircd
COPY --from=builder --chown=ircd:ircd /build /build

# Preserve clean upstream configs outside the volume mount target
RUN cp -r /home/ircd/unrealircd/conf /home/ircd/unrealircd/conf.default

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 6667 (plaintext clients), 6697 (TLS clients), 6900 (TLS server linking)
EXPOSE 6667 6697 6900

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD su-exec ircd /home/ircd/unrealircd/unrealircd status || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/home/ircd/unrealircd/bin/unrealircd", "-F"]