#!/bin/sh
set -eu

php -r '
if (PHP_VERSION !== "7.4.33") {
    fwrite(STDERR, "Unexpected PHP version: " . PHP_VERSION . "\n");
    exit(1);
}
foreach (["curl", "gd", "imagick", "mbstring", "mysqli", "Zend OPcache", "pdo_mysql", "redis", "session", "shmop", "sockets", "sodium", "xml", "zip"] as $extension) {
    if (!extension_loaded($extension)) {
        fwrite(STDERR, "Missing extension: $extension\n");
        exit(1);
    }
}
'
php-fpm -t

# The emergency backport must exit immediately on OOM, without running PHP
# shutdown callbacks against potentially corrupted interpreter state.
status=0
output=$(php -n -d memory_limit=16M -r '
register_shutdown_function(function () { echo "UNSAFE_SHUTDOWN_CALLBACK\n"; });
$value = str_repeat("x", 32 * 1024 * 1024);
' 2>&1) || status=$?
test "$status" -eq 1
case "$output" in
    *'Allowed memory size of'*'exhausted'*) ;;
    *) printf 'Expected OOM diagnostic, got: %s\n' "$output" >&2; exit 1 ;;
esac
case "$output" in
    *UNSAFE_SHUTDOWN_CALLBACK*) printf 'Unsafe OOM shutdown behavior\n' >&2; exit 1 ;;
esac
printf 'PHP emergency backport smoke checks passed.\n'
