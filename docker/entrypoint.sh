#!/usr/bin/env bash
set -eu

DATABASE_NAME=${DATABASE_NAME-wordpress}
DATABASE_USER=${DATABASE_USER-root}
DATABASE_PASSWORD=${DATABASE_PASSWORD}
DATABASE_HOST=${DATABASE_HOST-database}
DATABASE_PORT=${DATABASE_PORT-3306}
WORDPRESS_VERSION=${WORDPRESS_VERSION-latest}

# Sometimes, timeout occurred when set 45 seconds for MySQL 8
wait-for-it --timeout=60 "${DATABASE_HOST}:${DATABASE_PORT}" -- install-wp-tests "${DATABASE_NAME}" "${DATABASE_USER}" "${DATABASE_PASSWORD}" "${DATABASE_HOST}:${DATABASE_PORT}" "${WORDPRESS_VERSION}"
