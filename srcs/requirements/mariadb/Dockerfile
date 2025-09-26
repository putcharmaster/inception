FROM alpine:3.19


RUN apk add --no-cache mariadb mariadb-client bash su-exec


# Create mysql user/group and datadir
RUN mkdir -p /run/mysqld /var/lib/mysql && \
chown -R mysql:mysql /run/mysqld /var/lib/mysql


COPY conf/mariadb.cnf /etc/my.cnf.d/mariadb.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mariadbd", "--user=mysql", "--skip-networking=0", "--bind-address=0.0.0.0"]
