FROM ubuntu:16.04

MAINTAINER Ronald Bradford <me@ronaldbradford.com>

RUN apt-get update \
    && apt-get install -y make sudo libaio1 vim-tiny perl-modules libnuma1 \
    && rm -rf /var/lib/apt/lists/* 

EXPOSE 3306
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
