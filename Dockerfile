FROM alpine:3.7

MAINTAINER n3wbiemember "<giri@codigo.id>"

#define parameter
ARG REPO
ARG BRANCH
ARG DIR
ARG SERVER_NAME
ARG ROOTDIR
ARG ENV
ARG PHPVERSION

RUN set -x \
    && apk add --update --no-cache wget ca-certificates icu-libs git \
    openrc nginx dcron tzdata && \
    
    #add repository php$PHPVERSION, sebaiknya pake php7.2 https://symfony.fi/entry/php-7-1-vs-7-2-benchmarks-with-docker-and-symfony-flex
    wget -O /etc/apk/keys/phpearth.rsa.pub https://repos.php.earth/alpine/phpearth.rsa.pub && \
    echo "@php https://repos.php.earth/alpine/v3.7" >> /etc/apk/repositories && apk update && \
    
    #default install php library
    apk add --update --no-cache \
    php$PHPVERSION-fpm@php \
    php$PHPVERSION-xml@php \
    php$PHPVERSION-curl@php \
    php$PHPVERSION-mcrypt@php \
    php$PHPVERSION-ctype@php \
    php$PHPVERSION-json@php \
    php$PHPVERSION-openssl@php \
    php$PHPVERSION-pdo@php \
    php$PHPVERSION-intl@php \
    php$PHPVERSION-pdo_mysql@php \
    php$PHPVERSION-mysqlnd@php \
    php$PHPVERSION-mysqli@php \
    php$PHPVERSION-mbstring@php \
    php$PHPVERSION-opcache@php \
    php$PHPVERSION-bcmath@php \
    php$PHPVERSION-zip@php \
    php$PHPVERSION-dom@php \
    php$PHPVERSION-iconv@php \
    php$PHPVERSION-exif@php \
    php$PHPVERSION-gd@php \
    php$PHPVERSION-phar@php \
    php$PHPVERSION-tokenizer@php \
    php$PHPVERSION-xmlreader@php \
    php$PHPVERSION-xmlwriter@php \
    php$PHPVERSION-xdebug@php \
    php$PHPVERSION-redis@php \
    php$PHPVERSION-fileinfo@php \
    php$PHPVERSION-common@php \
    php$PHPVERSION-bz2@php \
    php$PHPVERSION-session@php \
    curl && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN rm /etc/php/$PHPVERSION/php.ini && mv /etc/php/$PHPVERSION/php.ini-production /etc/php/$PHPVERSION/php.ini

RUN s=";date.timezone =" && \
    r="date.timezone = 'Asia/Jakarta'" && \
    sed -i -e "s~$s~$r~g" /etc/php/$PHPVERSION/php.ini

RUN s=";session.save_path" && \
    r="session.save_path" && \
    sed -i -e "s~$s~$r~g" /etc/php/$PHPVERSION/php.ini

#custome php and other template config
RUN sed -i -e "s/;\?listen\s*=\s*.*/listen = 127.0.0.1:9000/g" /etc/php/$PHPVERSION/php-fpm.d/www.conf && \
    sed -i -e "s/;\?user\s*=\s*.*/user = nginx/g" /etc/php/$PHPVERSION/php-fpm.d/www.conf && \
    sed -i -e "s/;\?group\s*=\s*.*/group = nginx/g" /etc/php/$PHPVERSION/php-fpm.d/www.conf && \
    sed -i -e "s/;\?pid\s*=\s*.*/pid = \/run\/php-fpm$PHPVERSION\/php-fpm$PHPVERSION.pid/g" /etc/php/$PHPVERSION/php-fpm.conf && \
    sed -i -e "s/;\?upload_max_filesize\s*=\s*.*/upload_max_filesize = 30M/g" /etc/php/$PHPVERSION/php.ini && \
    sed -i -e "s/;\?post_max_size\s*=\s*.*/post_max_size = 250M/g" /etc/php/$PHPVERSION/php.ini && \
    sed -i -e "s/;\?memory_limit\s*=\s*.*/memory_limit = 300M/g" /etc/php/$PHPVERSION/php.ini && \
    sed -i -e "s/;\?max_execution_time\s*=\s*.*/max_execution_time = 60/g" /etc/php/$PHPVERSION/php.ini && \
    sed -i -e "s/;\?pm\s*=\s*.*/pm = static/g" /etc/php/$PHPVERSION/php-fpm.d/www.conf && \
    sed -i -e "s/;\?expose_php\s*=\s*.*/expose_php = Off/g" /etc/php/$PHPVERSION/php.ini && \
    sed -i -e "s/;\?pm.max_children\s*=\s*.*/pm.max_children = 16/g" /etc/php/$PHPVERSION/php-fpm.d/www.conf && \
    ln -nsf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

#edit user defautl
WORKDIR /etc/nginx
#RUN sed -i -e "s/user nginx;/user www-data;/g" nginx.conf && rm conf.d/default.conf 

RUN rm nginx.conf
ADD nginx.conf nginx.conf
RUN rm conf.d/default.conf 

#copy file to docker
COPY default.conf conf.d/default.conf
COPY vhost.conf conf.d/vhost.conf

#running service @booting process
RUN rc-update add dcron default && \
    rc-update add nginx default && \
    rc-update add php-fpm$PHPVERSION default && \

    echo 'null::respawn:/sbin/syslogd -n -S -D -O /proc/1/fd/1' >> /etc/inittab && \
    rm -fr /var/cache/apk/* \
    # Disable getty's
    && sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab \
    && sed -i \
        # Change subsystem type to "docker"
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        # Allow all variables through
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        # Start crashed services
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        # Define extra dependencies for services
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf \
    # Remove unnecessary services
    && rm -f /etc/init.d/hwdrivers \
            /etc/init.d/hwclock \
            /etc/init.d/hwdrivers \
            /etc/init.d/modules \
            /etc/init.d/modules-load \
            /etc/init.d/modloop \
    # Can't do cgroups
    && sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh \
    && sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh

#change permission
RUN mkdir -p /opt/www && chown -R nginx:nginx /opt

WORKDIR /opt/www
COPY index.html index.html

#clone app + define server + root dir nginx
RUN git clone $REPO $DIR && cd $DIR && git checkout $BRANCH && \
    sed -i -e "s/xname/$SERVER_NAME/g" /etc/nginx/conf.d/vhost.conf && \
    sed -i -e "s/_ENV_/$ENV/g" /etc/nginx/conf.d/vhost.conf && \
    f="web/public" && \
    sed -i -e "s~$f~$ROOTDIR~g" /etc/nginx/conf.d/vhost.conf && \
    cek=`find . -name composer.json` && \
    if [ -z $cek ];then echo "can't find composer json";else `composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader`;fi && \
    chown -R nginx:nginx /opt
#delete git for production

CMD ["/sbin/init"]
#EXPOSE 80
