#!/bin/bash

export NGINX_CONFIG=/etc/nginx/sites-enabled/default
export HTTP_PORT="${HTTP_PORT:-80}"

envsubst < /app/nginx.conf.envsubst > ${NGINX_CONFIG}
envsubst < /app/supervisord.d/nginx.envsubst > /app/supervisord.d/nginx.conf
