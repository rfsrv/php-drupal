FROM shinsenter/phpfpm-nginx:php7.4 AS base

# Emergency upstream PHP 7.4 mitigation for CVE-2026-109618 / CVE-2026-109619.
# Compile separately so the build dependencies do not enter the runtime image.
FROM base AS php-build

ARG PHP_BACKPORT_COMMIT=712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
ARG PHP_BACKPORT_SHA256=5fe57ca6ee96d59b36c6e0ca842843c50884f177bef1e85234cf669b577f5e48
ARG PHP_BUILD_JOBS=4

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        ca-certificates curl patch xz-utils \
        libargon2-dev libcurl4-openssl-dev libonig-dev libreadline-dev \
        libsodium-dev libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

COPY scripts/build-php-backport.sh /tmp/build-php-backport.sh
RUN sh /tmp/build-php-backport.sh

FROM base

LABEL org.rfsrv.php.security-backport="712e60f9edfd03f0960fc4fc3c2c375f42b90aa2"

COPY --from=php-build /usr/local/bin/php /usr/local/bin/php
COPY --from=php-build /usr/local/bin/php-config /usr/local/bin/php-config
COPY --from=php-build /usr/local/bin/phpize /usr/local/bin/phpize
COPY --from=php-build /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm
COPY --from=php-build /usr/local/include/php/ /usr/local/include/php/
COPY --from=php-build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
# phpaddmod/docker-php-ext-install must also use the patched source.
COPY --from=php-build /usr/src/php.tar.xz /usr/src/php.tar.xz

ARG SUPERCRONIC_VERSION=0.2.33

# Install OS packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        wget \
        nano \
        procps \
        msmtp \
        imagemagick \
        imagemagick-common \
        ncurses-base \
        ncurses-bin \
        ncurses-term \
        default-mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add PHP extensions
RUN phpaddmod imagick shmop sockets

# Add Pear modules
RUN pear install console_table

# Xdebug for debugging
RUN pecl install xdebug-3.1.6

COPY scripts/verify-php-backport.sh /usr/local/bin/verify-php-backport
RUN sh /usr/local/bin/verify-php-backport

# Install supercronic (container-native cron daemon for the cron sidecar)
RUN set -eux; \
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
    wget -qO /usr/local/bin/supercronic \
        "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH}"; \
    chmod +x /usr/local/bin/supercronic

# Crontab and helper consumed when the image is used as a cron sidecar.
RUN mkdir -p /etc/supercronic
COPY cron/crontab /etc/supercronic/crontab
COPY scripts/drupal-cron-run.sh /usr/local/bin/drupal-cron-run
RUN chmod +x /usr/local/bin/drupal-cron-run
