# php-drupal

PHP 7.4 / FPM / nginx base image for the legacy Drupal application.

## Emergency PHP security backport

The image rebuilds PHP 7.4.33 with the official upstream emergency mitigation for
**CVE-2026-109618** and **CVE-2026-109619**:

- [Upstream PHP 7.4 backport](https://github.com/php/php-src/tree/PHP-7.4-CVE-2026-109618-109619)
- Pinned commit: `712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`
- Both the release source and the patch are SHA-256 checked during the build.

The rebuild preserves the base image's configure options and extension ABI.
Patched headers and source are also provided for subsequent extension builds.
PHP still reports **7.4.33**; the image label
`org.rfsrv.php.security-backport` identifies the applied commit.

This is the upstream minimal mitigation for an end-of-life PHP release, not a
return to supported PHP maintenance. It deliberately exits the worker immediately
on out-of-memory errors (PHP shutdown callbacks will not run), and disables session
upload-progress processing in the engine. Ordinary sessions and uploads remain
available.

## Build and verify

```sh
docker build --pull -t php-drupal:emergency-backport .
docker run --rm --entrypoint sh php-drupal:emergency-backport \
    /usr/local/bin/verify-php-backport
```

The build runs extension, FPM configuration, and out-of-memory behavior checks.
The existing GitHub Actions workflow publishes both amd64 and arm64 images to
`ghcr.io/rfsrv/php-drupal:latest`. Downstream application images must be rebuilt
with the updated base and redeployed to replace their existing PHP binaries.
