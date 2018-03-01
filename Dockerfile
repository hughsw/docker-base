# To build and publish:
# $ docker build -t hughsw/gsbase .
# $ docker login -u hughsw -p <password>
# $ docker push hughsw/gsbase
#
# And on a target
# $ docker pull hughsw/gsbase

# Debian 9.x
FROM debian:stretch

# A tiny executable that pauses -- Useful for keeping a container
# alive if commands daemonize themselves, by putting it at the end of
# the startup script.
COPY pause /

# RUN echo && dpkg --list && echo 1


RUN true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      apt-transport-https \
      apt-utils \
      ca-certificates \
    && apt-get install -y --no-install-recommends \
      curl \
      emacs25-nox \
      g++ \
      gcc \
      git \
      gnupg2 \
      make \
      net-tools \
      python \
      python3 \
      python3-dev \
      python3-pip \
      python3-setuptools \
      python3-wheel \
      rsync \
      screen \
      shared-mime-info \
      software-properties-common \
      sudo \
      telnet \
      unzip \
      wget \
      zip \
    && python --version \
    && python3 --version \
    && rm -r /var/lib/apt/lists/* \
    && true


# nginx 1.10 (.3)
RUN true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      nginx \
    && nginx -v \
    && rm -r /var/lib/apt/lists/* \
    && true

# MariaDB 10.1
RUN true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      mariadb-server \
      mariadb-client \
    && mysql --version \
    && rm -r /var/lib/apt/lists/* \
    && true

# NodeJS 9.x
RUN true \
    && apt-get update \
    && curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash - \
    && apt-get install -y --no-install-recommends \
      nodejs \
    && node --version \
    && npm --version \
    && rm -r /var/lib/apt/lists/* \
    && true

# PHP 7.0
RUN true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      php7.0 \
      php7.0-common \
      php7.0-curl \
      php7.0-fpm \
      php7.0-gd \
      php7.0-gettext \
      php7.0-mbstring \
      php7.0-mbstring \
      php7.0-mcrypt \
      php7.0-mysql \
      php7.0-xml \
      php7.0-zip \
    && php --version \
    && rm -r /var/lib/apt/lists/* \
    && true

#      php7.0-token-stream \
#      php7.0-pclzip \

# See: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
# and read to the bottom where it talks about "commit hash".
# Commit of 2018-01-17 at https://github.com/composer/getcomposer.org/commits/master
# Composer 1.6.2
ENV COMPOSER_COMMIT_HASH=32c2c34883cf31c57e4729d1afaf09facad7615b
#  --quiet
RUN true \
    && wget https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_COMMIT_HASH/web/installer -O - -q | php -- \
    && mv composer.phar /usr/local/bin/composer \
    && composer --version \
    && groupadd -r php && useradd -r -m -g php php \
    && true

ENV PATH /home/php/.composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER php:php
RUN composer global require laravel/installer
USER root:root


# Install Docker CLI tools into image
# Using them in a container requires mapping host engine socket into container: Risky!
# See: https://docs.docker.com/engine/security/security/#docker-daemon-attack-surface
#
# See: https://github.com/docker/docker-install
# Did:
#   curl -fsSL get.docker.com -o get-docker.sh
#   sh test-docker.sh --dry-run
# Copied the '+' indicated outputs
RUN true \
    && curl -fsSL "https://download.docker.com/linux/debian/gpg" | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian  $(lsb_release -cs) stable" \
    && apt-get remove -y docker-ce docker docker-engine docker.io || true \
    && mkdir -p /var/lib/docker \
    && rm -rf /var/lib/docker \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce docker-compose \
    && docker --version \
    && docker-compose --version \
    && rm -r /var/lib/apt/lists/* \
    && true


# Put nutritional info into GSBASE.txt
RUN echo 'ver () { echo -n "$@" " : " >> GSBASE.txt && "$@" >> GSBASE.txt 2>&1 ; } \
  && touch GSBASE.txt \
  && ver date \
  && ver uname -a \
  && ver python --version \
  && ver python3 --version \
  && ver nginx -v \
  && ver mysql --version \
  && ver node --version \
  && ver npm --version \
  && ver php --version \
  && ver composer --version \
  && ver docker --version \
  && ver docker-compose --version \
  ' | /bin/bash && cat GSBASE.txt
