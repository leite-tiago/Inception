FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive \
	WP_PATH=/var/www/html \
	PHP_FPM_USER=www-data \
	PHP_FPM_GROUP=www-data

RUN apt-get update \
	 && apt-get install -y --no-install-recommends \
		 ca-certificates curl less nano netcat-traditional \
		 php-fpm php-mysql php-cli php-mbstring php-xml php-zip php-curl php-gd php-intl php-soap \
	   mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

# Install wp-cli
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp \
	&& wp --info --allow-root || true

RUN mkdir -p ${WP_PATH} /run/php

# Copy config and tools
COPY conf/www.conf /tmp/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Place php-fpm pool config according to installed PHP version
RUN set -eux; \
	v=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;'); \
	mkdir -p "/etc/php/${v}/fpm/pool.d"; \
		mv /tmp/www.conf "/etc/php/${v}/fpm/pool.d/www.conf"; \
		# Redirect php-fpm master error log to stderr to avoid FS permission issues
		conf="/etc/php/${v}/fpm/php-fpm.conf"; \
		if [ -f "$conf" ]; then \
			sed -i 's#^;\?\s*error_log\s*=.*#error_log = /proc/self/fd/2#' "$conf"; \
		fi

RUN chmod +x /usr/local/bin/entrypoint.sh \
	&& chown -R ${PHP_FPM_USER}:${PHP_FPM_GROUP} ${WP_PATH} /run/php

WORKDIR ${WP_PATH}

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
