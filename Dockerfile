# Create CentOS7 Minimal Container
FROM centos:7

#Currently works with a blank root MariaDB password (BAD IDEA)
ENV DBNAME="torrentflux"
ENV DBUSER="torrentflux"
ENV DBPASS="#y56toq34tyq3"
ENV TIMEZONE="America/New_York"

# Install YUM pre-requisite REPOs and Packages
RUN yum install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y && \
    yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y && \
    yum -y install epel-release && \
    yum -y install bash wget supervisor vim-enhanced net-tools perl make gcc-c++ \
    vlc rsync nc cronie openssh sudo syslog-ng mariadb-server httpd php-mysql mlocate \
    git php php-cli unzip bzip2 libcurl-devel libevent-devel intltool openssl-devel && \
    yum update -y
    
# Create MySQL Start Script
RUN { \
    echo "#!/bin/bash"; \
    echo "/usr/bin/mysqld_safe &"; \
    echo "export SQL_TO_LOAD='/mysql_load_on_first_boot.sql';"; \
    echo "[[ -e \$SQL_TO_LOAD ]] && { sleep 5 && /usr/bin/mysql -u root --password='' < \$SQL_TO_LOAD && mv \$SQL_TO_LOAD /usr/share/torrentflux/sql/custom.sql; }"; \
    echo "while true; do sleep 60; done"; \
    } | tee /start-mysqld.sh && chmod a+x /start-mysqld.sh && /usr/libexec/mariadb-prepare-db-dir

# Install Torrentflux-b4rt    
RUN cd /usr/share && git clone https://github.com/XelaNull/torrentflux-b4rt-php7 && mv torrentflux-b4rt-php7 torrentflux && \
    cp -rp /usr/share/torrentflux/html/* /var/www/html/ && mkdir /var/www/html/downloads && chown apache /var/www/html/* -R && \
    rm -rf /etc/httpd/conf.d/welcome.conf && echo "date.timezone='${TIMEZONE}'" > /etc/php.d/timezone.ini && rm -rf /var/www/html/setup.php
# Create the Torrentflux-b4rt DB configuration file
RUN { \
      echo '<?php'; \
      echo '$cfg["db_type"] = "mysql";'; \
      echo '$cfg["db_host"] = "localhost";'; \
      echo "\$cfg[\"db_name\"] = \"${DBNAME}\";"; \
      echo "\$cfg[\"db_user\"] = \"${DBUSER}\";"; \
      echo "\$cfg[\"db_pass\"] = \"${DBPASS}\";"; \
      echo '$cfg["db_pcon"] = true;'; \
    } | tee /var/www/html/inc/config/config.db.php
# Create a .sql file that can be read in the first time MariaDB is started, that creates the Torrentflux-b4rt Database
# This section also contains any customized defaults that I would like set. The full list can be found at:
#     /usr/share/torrentflux/sql/mysql/mysql_torrentflux-b4rt-1.0.sql
RUN { \
      echo 'CREATE DATABASE torrentflux;'; \
      echo "GRANT ALL PRIVILEGES ON *.* to ${DBNAME}@'%' IDENTIFIED BY '${DBPASS}';"; \
      echo "GRANT ALL PRIVILEGES ON *.* to ${DBNAME}@localhost IDENTIFIED BY '${DBPASS}';"; \
      echo "FLUSH PRIVILEGES;"; echo "USE torrentflux;"; \
    } | tee /mysql_load_on_first_boot.sql && cp /usr/share/torrentflux/sql/mysql/mysql_torrentflux-b4rt-1.0.sql /tmp.sql && \
    sed -i 's|/usr/bin/unrar|/usr/local/bin/unrar|g' /tmp.sql && \
    sed -i 's|/usr/bin/cksfv|/usr/local/bin/cksfv|g' /tmp.sql && \
    sed -i 's|/usr/local/bin/transmissioncli|/usr/local/bin/transmission-cli|g' /tmp.sql && \
    sed -i 's|/var/www/|/var/www/html/|g' /tmp.sql && \
    sed -i "s|'enable_home_dirs','1'|'enable_home_dirs','0'|g" /tmp.sql && \
    sed -i "s|'sharekill','0'|'sharekill','1'|g" /tmp.sql && \
    sed -i "s|'fluxd_Qmgr_maxUserTransfers','2'|'fluxd_Qmgr_maxUserTransfers','5'|g" /tmp.sql && \
    sed -i "s|'enable_search','1'|'enable_search','0'|g" /tmp.sql && \
    sed -i "s|'ui_displayusers','1'|'ui_displayusers','0'|g" /tmp.sql && \
    sed -i 's|PRIMARY KEY  (user_id,date)|PRIMARY KEY  (user_id)|g' /tmp.sql && \
    sed -i "s|date DATE NOT NULL default '0000-00-00'|date TIMESTAMP NOT NULL default CURRENT_TIMESTAMP|g" /tmp.sql && \
    cat /tmp.sql >> /mysql_load_on_first_boot.sql

# Install rar, unrar, and uudeview
RUN cd /root && wget https://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz && tar -zxf rarlinux-x64-5.5.0.tar.gz && cd rar && cp rar unrar /usr/local/bin/
RUN wget http://www.fpx.de/fp/Software/UUDeview/download/uudeview-0.5.20.tar.gz && tar zxvf uudeview-0.5.20.tar.gz && \
    cd uudeview-0.5.20 && ./configure && make && make install

# Create and Build Transmission 2.73 for Torrentflux-b4rt
RUN cd /root && wget https://github.com/XelaNull/transmission-releases/raw/master/transmission-2.73.tar.bz2 && tar jxvf transmission-2.73.tar.bz2 && \
    cd transmission-2.73 && git clone https://github.com/XelaNull/torrentflux.git && \
    rm -rf cli/cli.c && cp torrentflux/clients/transmission/transmission-2.73/cli.c cli/ && \
    rm -rf libtransmission/transmission.h && cp torrentflux/clients/transmission/transmission-2.73/transmission.h libtransmission/ && \
    ./configure --enable-cli --enable-daemon && make && strip cli/transmission-cli && cp cli/transmission-cli /usr/local/bin/

RUN cd /root && git clone https://github.com/vadmium/cksfv.git && cd cksfv && ./configure && make && make install

# Configure supervisord
RUN { \
    echo '[supervisord]'; \
    echo 'nodaemon        = true'; \
    echo 'user            = root'; \
    echo 'logfile         = /var/log/supervisord'; echo; \
    echo '[program:syslog-ng]'; \
    echo 'process_name    = syslog-ng'; \
    echo 'autostart       = true'; \
    echo 'autorestart     = unexpected'; \
    echo 'directory       = /etc'; \
    echo 'command         = /usr/sbin/syslog-ng -F'; \
    echo 'startsecs       = 1'; \
    echo 'priority        = 1'; echo; \
    echo '[program:crond]'; \
    echo 'process_name    = crond'; \
    echo 'autostart       = true'; \
    echo 'autorestart     = unexpected'; \
    echo 'directory       = /'; \
    echo 'command         = /usr/sbin/crond -n'; \
    echo 'startsecs       = 3'; \
    echo 'priority        = 1'; echo; \
    echo '[program:httpd]'; \
    echo 'process_name    = httpd'; \
    echo 'autostart       = true'; \
    echo 'autorestart     = unexpected'; \
    echo 'directory       = /'; \
    echo 'command         = /usr/sbin/apachectl -D FOREGROUND'; \
    echo 'startsecs       = 3'; \
    echo 'priority        = 1'; echo; \
    echo '[program:mysqld]'; \
    echo 'process_name    = mysqld'; \
    echo 'autostart       = true'; \
    echo 'autorestart     = unexpected'; \
    echo 'directory       = /'; \
    echo 'command         = /start-mysqld.sh'; \
    echo 'startsecs       = 3'; \
    echo 'priority        = 1'; echo; \
    } | tee /etc/supervisord.conf
    
# Ensure all packages are up-to-date, then fully clean out all cache
RUN yum -y update && yum clean all && rm -rf /tmp/* && rm -rf /var/tmp/*

# Set to start the supervisor daemon on bootup
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
