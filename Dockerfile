# DOCKER-VERSION 1.13.0
#
# brunobertechini/centos-lamp-6.8.1
#
# Based on CentOS 6.8
#
# MySQL root password: empty
# Change using [root#]/usr/bin/mysqladmin -u root password 'mysql'
#
# Url Phpmyadmin: http://localhost:8080/phpmyadmin
#

FROM centos:6.8
MAINTAINER NgIT "bruno.bertechini@outlook.com"

#
# UPDATE PACKAGES
#
RUN yum update -y

#
# Add Epel Mirror
#
RUN yum install -y epel-release

#
# TOOLS
#
RUN yum install -y curl wget unzip yum-utils python-setuptools

#
# APACHE
#
RUN yum install -y httpd

#
# PHP
#
RUN yum install -y php php-mysql 

# Install composer
WORKDIR /tmp
RUN curl -sS https://getcomposer.org/installer | php
RUN mv /tmp/composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# Create phpinfo file
RUN echo '<?php phpinfo(); ?>' >> /var/www/html/phpinfo.php


# Configure php.ini
RUN sed -i -e "s/short_open_tag = Off/short_open_tag = On/" /etc/php.ini

#
# MYSQL
#
RUN yum install -y mysql-server phpmyadmin

# Allow Access to phpMyAdmin from everyone
RUN sed -i -e "s/Allow from 127.0.0.1/Allow from ALL/" /etc/httpd/conf.d/phpMyAdmin.conf

## CLEAN UP
RUN package-cleanup --dupes
RUN package-cleanup --cleandupes
RUN yum clean all

#
# SUPERVISOR
#
RUN yum -y install python-setuptools
RUN easy_install supervisor
RUN /usr/bin/echo_supervisord_conf > /etc/supervisord.conf

# make supervisor run in foreground
RUN sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf

# add mysqld program to supervisord config
RUN echo  >> /etc/supervisord.conf
RUN echo [program:mysqld] >> /etc/supervisord.conf
RUN echo 'command=/usr/bin/mysqld_safe --datadir=/var/lib/mysql --socket=/var/lib/mysql/mysql.sock --pid-file=/var/run/mysqld/mysqld.pid --basedir=/usr --user=mysql' >> /etc/supervisord.conf

# add httpd program to supervisord config
RUN echo  >> /etc/supervisord.conf
RUN echo [program:httpd] >> /etc/supervisord.conf
RUN echo 'command=/usr/sbin/httpd -D FOREGROUND' >> /etc/supervisord.conf
RUN echo  >> /etc/supervisord.conf

#
# Allow Access to phpMyAdmin from everyone
#
RUN sed -i -e "s/Allow from 127.0.0.1/Allow from ALL/" /etc/httpd/conf.d/phpMyAdmin.conf

#
# Start services for the first time
#
RUN service mysqld start
RUN service httpd start

WORKDIR /root

EXPOSE 80 3306

#
# Start Supervisor in foreground
#
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]