# Debian 9.x
FROM debian:stretch

RUN echo && dpkg --list && echo 1

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
      netcat \
      procps \
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
      fcgiwrap \
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

#    && npm install npm@latest -g \


# PHP 7.2
# Based on: https://www.chris-shaw.com/blog/installing-php-7.2-on-debian-8-jessie-and-debian-9-stretch
RUN true \
    && curl -sSL  https://packages.sury.org/php/apt.gpg > /etc/apt/trusted.gpg.d/php.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      php7.2 \
      php7.2-cli \
      php7.2-common \
      php7.2-curl \
      php7.2-fpm \
      php7.2-gd \
      php7.2-json \
      php7.2-mbstring \
      php7.2-mysql \
      php7.2-opcache \
      php7.2-readline \
      php7.2-xml \
      php7.2-zip \
    && echo >> /etc/php/7.2/fpm/php-fpm.conf \
    && echo 'ping.path = /ping' >> /etc/php/7.2/fpm/php-fpm.conf \
    && echo 'pm.status_path = /status' >> /etc/php/7.2/fpm/php-fpm.conf \
    && php --version \
    && php-fpm7.2 --version \
    && php-fpm7.2 --test \
    && rm -r /var/lib/apt/lists/* \
    && true

#      php7.2-gettext \
#      php7.2-mcrypt \

# Note: See further testing of php-fpm in the GSBASE section below.


# PHP Composer
# See: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
# and read to the bottom where it talks about "commit hash".
# Commit of 2018-05-04, Composer 1.6.5, at https://github.com/composer/getcomposer.org/commits/master
RUN true \
    && export COMPOSER_COMMIT_HASH=fe44bd5b10b89fbe7e7fc70e99e5d1a344a683dd \
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
# Copied the indicated outputs and let them log to console
RUN true \
    && curl -fsSL "https://download.docker.com/linux/debian/gpg" | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian  $(lsb_release -cs) stable" \
    && apt-get remove -y docker-ce docker docker-engine docker.io || true \
    && mkdir -p /var/lib/docker \
    && rm -rf /var/lib/docker \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      docker-ce \
      docker-compose \
    && docker --version \
    && docker-compose --version \
    && rm -r /var/lib/apt/lists/* \
    && true


# asyncrun.sh -- A shell script that runs $@ as a child and forwards signals to it.
#
# await-port.sh -- A shell script that waits for a port to be active, or times out;
# useful for waiting for a service to become active
#
# pause -- A tiny executable that pauses -- Useful for keeping a container
# alive if commands daemonize themselves, by putting it at the end of
# the startup script.
COPY asyncrun.sh await-port.sh pause /usr/local/bin/

# TOOO: Remove this legacy placement of the binary
COPY pause /

ENTRYPOINT ["asyncrun.sh"]


# Put nutritional info into GSBASE.txt
RUN echo 'ver () { echo -n "$@" " : " >> GSBASE.txt && "$@" >> GSBASE.txt 2>&1 ; } \
  && touch GSBASE.txt \
  && ver date \
  && ver uname -a \
  && ver ps --version \
  && ver python --version \
  && ver python3 --version \
  && ver nginx -v \
  && ver mysql --version \
  && ver node --version \
  && ver npm --version \
  && ver php --version \
  && ver php-fpm7.2 --version \
  && ver php-fpm7.2 --test \
  && ver composer --version \
  && ver docker --version \
  && ver docker-compose --version \
  && ver service --status-all \
  && ver service php7.2-fpm start \
  && ver service --status-all ; \
  ' | /bin/bash -eu && cat GSBASE.txt

# Sigh...  The following tests worked in an earlier incarnation of the
# container (after `service php7.2-fpm start`), but now the cgi-fcgi
# program isn't found, even though many docs claim it comes with
# libfcgi0ldbl (supercedes libfcgi), which is installed as part of
# fcgiwrap...
#   SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect /var/run/php/php7.2-fpm.sock ; \
#   SCRIPT_NAME=/status SCRIPT_FILENAME=/status QUERY_STRING= REQUEST_METHOD=GET cgi-fcgi -bind -connect /var/run/php/php7.2-fpm.sock ; \
