FROM debian:bookworm
VOLUME /app/etc /app/repo
RUN set -ex; \
    apt-get update; \
    apt-get install -qy sudo mini-dinstall gnupg2 procps gettext-base; \
    apt-get clean

COPY app/ /app/
CMD /app/start.bash
