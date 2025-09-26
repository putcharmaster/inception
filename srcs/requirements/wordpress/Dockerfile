FROM alpine:3.19

RUN apk add --no-cache \
  php82 php82-fpm php82-cli php82-mysqli php82-curl php82-json php82-mbstring php82-zip php82-openssl \
  php82-xml php82-dom php82-phar php82-ctype php82-gd \
  curl tar bash netcat-openbsd

# Ensure www-data exists (idempotent)
RUN addgroup -S www-data 2>/dev/null || true && \
    adduser  -S -H -s /sbin/nologin -G www-data www-data 2>/dev/null || true

# Install WP-CLI for automated provisioning
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

WORKDIR /var/www/html
COPY conf/php-fpm.conf /etc/php82/php-fpm.d/zz-pool.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm82", "-F"]
