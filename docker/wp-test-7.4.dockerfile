FROM ubuntu:jammy

# Install packages
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update \
    && apt-get -yqq install \
        software-properties-common \
        curl \
        unzip \
        subversion \
        mysql-client \
        git \
        wget

# Install older php
RUN apt-get update \
    && add-apt-repository ppa:ondrej/php \
    && apt-get -yqq install \
        php7.4 \
        php7.4-curl \
        php7.4-dev \
        php7.4-gd \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-pdo \
        php7.4-xdebug \
        php7.4-xml \
        php7.4-zip \
        php7.4-intl \
    && update-alternatives --set php /usr/bin/php7.4

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

ENV WORDPRESS_VERSION 6.0.2

# ↓ @see https://github.com/docker-library/php/issues/391#issuecomment-346590029

# ↓ @see https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
# ↓ Composer (2.2 or more) will now prompt you the first time you use a plugin
# ↓ to be sure that no package can run code during a Composer run if you do not trust it.
# ↓ @see: https://blog.packagist.com/composer-2-2/
RUN composer global config --no-interaction --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true \
 && composer global require --prefer-dist \
# ↓ 2020-08-24 WordPress supports PHPUnit 7.x
# ↓ @see https://core.trac.wordpress.org/ticket/50482#comment:8
# ↓ 2021-07-26 We still have to wait for update of WordPress to use PHPUnit 8 or more.
# ↓ WordPress hasn't support PHPUnit 8 or more with backward compatibility like for `void` return type declaration.
# ↓ Now they are trying to introduce PHPUnit Polyfills to resolve this issue:
# ↓ @see https://core.trac.wordpress.org/changeset/51567
# ↓ @see https://core.trac.wordpress.org/changeset/51568
    phpunit/phpunit:"<8.0.0" \
# ↓ 2020-11-23 WordPress started to require when running PHPUnit from WordPress 5.8.2
    yoast/phpunit-polyfills \
# ↓ To execute static analysis by PHP_CodeSniffer
    wp-coding-standards/wpcs \
    dealerdirect/phpcodesniffer-composer-installer \
    phpcompatibility/phpcompatibility-wp \
    automattic/vipwpcs \
# ↓ To use mock some functions of WordPress like "wp_remote_get"
# ↓ Only 1.3.* is allowed since 1.4 or more requires PHPUnit 8.0 or more
    mockery/mockery:1.3.* \
 && composer global clear-cache
ENV PATH $PATH:/root/.composer/vendor/bin
# ↓ Hot-fix for HTTP status 429 'Too Many Requests' when checkout testing suite in install-wp-tests
# ↓ @see https://wordpress.org/support/topic/too-many-requests-when-trying-to-checkout-plugin/
RUN wget -O /usr/bin/install-wp-tests https://raw.githubusercontent.com/wp-cli/scaffold-command/v2.0.12/templates/install-wp-tests.sh \
# ↓ Remove confirmation for initialize test database since it stops automated testing
 && sed -i "/read\s-p\s'Are\syou\ssure\syou\swant\sto\sproceed?\s\[y\/N\]:\s'\sDELETE_EXISTING_DB/d" /usr/bin/install-wp-tests \
 && chmod +x /usr/bin/install-wp-tests
# ↓ I decided "for the time being," "yes" may not be definitely better.
ENV DELETE_EXISTING_DB yes
ENV WP_CORE_DIR /usr/src/wordpress/
RUN touch wp-tests-config.php \
 && install-wp-tests '' '' '' localhost "${WORDPRESS_VERSION}" true \
 && rm -f wp-tests-config.php
# ↓ @see http://docs.docker.jp/compose/startup-order.html
RUN wget -O /usr/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
 && chmod +x /usr/bin/wait-for-it
COPY ./entrypoint.sh /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint
ENV WORDPRESS_VERSION=${WORDPRESS_VERSION}
WORKDIR /plugin
ENTRYPOINT ["entrypoint"]
