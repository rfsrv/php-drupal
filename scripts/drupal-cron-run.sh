#!/bin/sh
# Run Drupal cron from the application root.

set -eu

DRUPAL_ROOT="${DRUPAL_ROOT:-/var/www/html}"

cd "$DRUPAL_ROOT"

if [ -x "$DRUPAL_ROOT/vendor/bin/drush" ]; then
    exec "$DRUPAL_ROOT/vendor/bin/drush" cron
fi

if [ -x /usr/local/bin/drush ]; then
    exec /usr/local/bin/drush cron
fi

if command -v drush >/dev/null 2>&1; then
    exec drush cron
fi

echo "drupal-cron-run: drush not found" >&2
exit 127
