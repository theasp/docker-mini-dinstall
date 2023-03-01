FROM theasp/userlayer:debian-bullseye
ENV ENABLE_SUDO=false ENABLE_SSH_AGENT=false HTTP_PORT=80
VOLUME /app/etc /app/repo /app/log
EXPOSE $HTTP_PORT
RUN set -ex; \
  apt-get update; \
  apt-get install -qy mini-dinstall gnupg2 procps nginx-light; \
  apt-get clean

COPY app/*.sh app/*.envsubst /app/
COPY app/entrypoint.d/* /app/entrypoint.d/
COPY app/supervisord.d/* /app/supervisord.d/
