# osTicket web server: official PHP + Apache image with the extensions osTicket needs.
FROM php:8.3-apache

ARG OSTICKET_VERSION=1.18.4

# PHP extensions osTicket requires or recommends (mysqli = database, ldap = Active Directory
# login, gd/intl/zip/gettext = UI, attachments and translations, opcache/apcu = speed).
# ldap-utils adds ldapsearch, used to troubleshoot the AD connection from inside the container.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev libjpeg62-turbo-dev libfreetype6-dev libicu-dev libzip-dev libldap-dev \
        ldap-utils ca-certificates unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir="lib/$(dpkg-architecture --query DEB_HOST_MULTIARCH)" \
    && docker-php-ext-install -j"$(nproc)" mysqli gd intl zip ldap gettext opcache \
    && pecl install apcu && docker-php-ext-enable apcu \
    && rm -rf /var/lib/apt/lists/*

# Download the official osTicket release and copy its web files into Apache's folder.
# include/ost-config.php is a link into a Docker volume so the settings survive rebuilds.
RUN curl -fsSL -o /tmp/ost.zip \
        "https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip" \
    && unzip -q /tmp/ost.zip -d /tmp/ost \
    && cp -a /tmp/ost/upload/. /var/www/html/ \
    && rm -rf /tmp/ost /tmp/ost.zip \
    && mkdir -p /var/osticket-config \
    && ln -s /var/osticket-config/ost-config.php /var/www/html/include/ost-config.php \
    && chown -R www-data:www-data /var/www/html

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
