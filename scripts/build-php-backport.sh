#!/bin/sh
set -eu

# Keep the release's ABI and the base image's configure options/extensions.
test "$(php-config --version)" = '7.4.33'
configure_options=$(php-config --configure-options)

curl -fsSL https://www.php.net/distributions/php-7.4.33.tar.xz \
    -o /usr/src/php.tar.xz
printf '%s  %s\n' \
    '924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927' \
    /usr/src/php.tar.xz | sha256sum -c -
docker-php-source extract

curl -fsSL "https://github.com/php/php-src/commit/${PHP_BACKPORT_COMMIT}.patch" \
    -o /tmp/php-security.patch
printf '%s  %s\n' "$PHP_BACKPORT_SHA256" /tmp/php-security.patch | sha256sum -c -
patch --batch --fuzz=0 -d /usr/src/php -p1 < /tmp/php-security.patch

# Save the patched source before configure/make create build artifacts.
tar -cJf /usr/src/php.tar.xz -C /usr/src --exclude=php/.docker-extracted php

cd /usr/src/php
export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"
# php-config emits shell-quoted options, including architecture-specific paths.
eval "./configure $configure_options"
make -j"$PHP_BUILD_JOBS"
make install
php -v
php-fpm -v
