FROM shinsenter/phpfpm-nginx:php7.4

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
