#!/bin/sh
# Runs every time the osTicket container starts, before Apache.
set -e

CONFIG=/var/osticket-config/ost-config.php
WEBROOT=/var/www/html

# 1. Trust the lab's root certificate (needed for the secure LDAP connection to the DC).
if ls /usr/local/share/ca-certificates/bayview/*.crt >/dev/null 2>&1; then
    update-ca-certificates >/dev/null 2>&1
    echo "entrypoint: lab root certificate trusted"
fi

# 2. Copy any plugins (e.g. auth-ldap.phar) from the read-only plugins folder.
if ls /var/osticket-plugins/*.phar >/dev/null 2>&1; then
    cp /var/osticket-plugins/*.phar "$WEBROOT/include/plugins/"
    chown www-data:www-data "$WEBROOT"/include/plugins/*.phar
    echo "entrypoint: plugins copied"
fi

# 3. First start: create a writable config file for the web installer.
#    After install: lock the config file and remove the setup folder (osTicket's own advice).
if [ ! -f "$CONFIG" ]; then
    cp "$WEBROOT/include/ost-sampleconfig.php" "$CONFIG"
    chown www-data:www-data "$CONFIG"
    chmod 0666 "$CONFIG"
    echo "entrypoint: new install, open http://<host>:8080/setup/ to run the installer"
elif grep -q "define('OSTINSTALLED',TRUE)" "$CONFIG"; then
    chown root:root "$CONFIG"
    chmod 0644 "$CONFIG"
    rm -rf "$WEBROOT/setup"
    echo "entrypoint: osTicket installed, config locked, setup folder removed"
fi

exec "$@"
