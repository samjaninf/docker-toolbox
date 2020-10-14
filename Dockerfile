FROM bitnami/minideb:buster
LABEL maintainer "Sitepilot <support@sitepilot.io>"

# ----- Args ----- #

ARG PHP_VERSION="74"

ARG USER_ID=1000
ARG USER_GID=1000
ARG USER_NAME=sitepilot

ENV BUILD_USER_ID=$USER_ID
ENV BUILD_USER_GID=$USER_GID
ENV BUILD_USER_NAME=$USER_NAME
ENV BUILD_PHP_VERSION=$PHP_VERSION

# ----- Common ----- #

RUN install_packages sudo less ca-certificates curl wget nano restic openssh-server git zsh unzip ruby-full rubygems rsync

# ----- PHP ----- #

RUN wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debain_repo.sh | bash

RUN install_packages \
    lsphp$PHP_VERSION \
    lsphp$PHP_VERSION-mysql \
    lsphp$PHP_VERSION-imap \
    lsphp$PHP_VERSION-curl \
    lsphp$PHP_VERSION-common \
    lsphp$PHP_VERSION-json \
    lsphp$PHP_VERSION-redis \
    lsphp$PHP_VERSION-opcache \
    lsphp$PHP_VERSION-igbinary \
    lsphp$PHP_VERSION-ioncube \
    lsphp$PHP_VERSION-imagick

RUN ln -s /usr/local/lsws/lsphp$PHP_VERSION/bin/php /usr/local/bin/php

# ----- WPCLI ----- #

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# ----- Composer ----- #

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && php -r "unlink('composer-setup.php');"

# ----- NodeJS ----- #

RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo bash - \
    && install_packages nodejs

# ----- Wordmove ----- #

RUN gem install --force --no-user-install wordmove

# ----- User ----- #

RUN addgroup --gid "$USER_GID" "$USER_NAME" \
    && adduser \
    --disabled-password \
    --gecos "" \
    --home "/opt/sitepilot/home" \
    --ingroup "$USER_NAME" \
    --no-create-home \
    --uid "$USER_ID" \
    "$USER_NAME" \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ----- Filesystem ----- #

COPY tags /

RUN chown $USER_NAME:$USER_NAME /opt/sitepilot/home

RUN chown root:root /opt/sitepilot/apps

RUN mkdir /run/sshd

# ----- Config ----- #

USER $USER_ID

WORKDIR /opt/sitepilot/home

EXPOSE 22

ENTRYPOINT ["sudo", "--preserve-env", "/opt/sitepilot/scripts/entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]

# ----- Checks ----- #

RUN php -v \
    && wp --version \
    && composer --version \
    && nodejs -v \
    && npm -v
