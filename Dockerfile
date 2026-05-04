FROM shinsenter/phpfpm-nginx:php7.4

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
