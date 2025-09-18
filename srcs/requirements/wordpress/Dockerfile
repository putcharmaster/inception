FROM alpine:3.19


RUN apk add --no-cache php82 php82-fpm php82-cli php82-mysqli php82-curl php82-json php82-mbstring php82-zip php82-openssl curl tar bash


# php-fpm runs as www-data on Alpine (user: nginx). We'll use www-data-like user
RUN adduser -D -H -s /sbin/nologin www


WORKDIR /var/www/html
COPY conf/php-fpm.conf /etc/php82/php-fpm.d/zz-pool.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm82", "-F"]