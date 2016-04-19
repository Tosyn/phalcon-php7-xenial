FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y software-properties-common \
    && LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php \
    && apt-get update

RUN apt-get install -y --allow-unauthenticated \
	php7.0-fpm \
    	php7.0-cli \
    	php7.0-curl \
    	php7.0-gd \
    	php7.0-intl \
	php7.0-pgsql \
    	nginx \
    	curl \
    	wget \
	sudo \
	vim \
        git

# For zephir installtion; the following packages are needed in Ubuntu:
RUN apt-get install -y --allow-unauthenticated gcc make re2c libpcre3-dev php7.0-dev

# Install composer
RUN curl -sS http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install zephir
RUN composer global require "phalcon/zephir:dev-master" 
#RUN export PATH="$PATH:~/.composer/vendor/bin"

# Install phalcon dev tool 
RUN composer require "phalcon/devtools" -d /usr/local/bin/ \
    && ln -s /usr/local/bin/vendor/phalcon/devtools/phalcon.php /usr/bin/phalcon

# Add dev user
RUN useradd -m -d /workspace -s /bin/bash developer \
    && chown -R developer:developer /workspace \
    && adduser developer sudo 

# Install phalconphp with php7
WORKDIR /workspace/base
RUN git clone https://github.com/phalcon/cphalcon.git -b 2.1.x --single-branch
WORKDIR /workspace/base/cphalcon
RUN ~/.composer/vendor/bin/zephir build --backend=ZendEngine3
RUN echo "extension=phalcon.so" >> /etc/php/7.0/fpm/conf.d/20-phalcon.ini
RUN echo "extension=phalcon.so" >> /etc/php/7.0/cli/conf.d/20-phalcon.ini

# Clean up
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/cli/php.ini \
    && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini \
    && sed -i "s/memory_limit = 128M/memory_limit = 256M /g" /etc/php/7.0/fpm/php.ini \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/* /usr/src/*

WORKDIR /workspace/base
CMD sudo service php7.0-fpm start && sudo nginx -g "daemon off;"
