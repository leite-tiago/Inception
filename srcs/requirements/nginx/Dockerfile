FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	   nginx openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default || true \
	&& mkdir -p /etc/nginx/conf.d /etc/nginx/ssl /run/nginx /var/www/html

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
	&& chown -R www-data:www-data /var/www/html

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
