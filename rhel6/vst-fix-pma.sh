#!/bin/bash

# Vesta RHEL/CentOS installer v.04

#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
export PATH=$PATH:/sbin
RHOST='r.vestacp.com'
CHOST='c.vestacp.com'
REPO='cmmnt'
VERSION='0.9.8/rhel'
YUM_REPO='/etc/yum.repos.d/vesta.repo'
software="nginx httpd mod_ssl mod_ruid2 mod_extract_forwarded mod_fcgid
    php php-bcmath php-cli php-common php-gd php-imap php-mbstring php-mcrypt
    php-mysql php-pdo php-soap php-tidy php-xml php-xmlrpc quota e2fsprogs
    phpMyAdmin awstats webalizer vsftpd mysql mysql-server exim dovecot clamd
    spamassassin curl roundcubemail bind bind-utils bind-libs mc screen ftp
    libpng libjpeg libmcrypt mhash zip unzip openssl flex rssh libxml2
    ImageMagick sqlite pcre sudo bc jwhois mailx lsof tar telnet rrdtool
    fail2ban GeoIP freetype ntp openssh-clients vesta vesta-nginx vesta-php"


# Password generator
gen_pass() {
    MATRIX='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    LENGTH=32
    while [ ${n:=1} -le $LENGTH ]; do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$PASS"
}


# phpMyAdmin configuration
wget $CHOST/$VERSION/httpd-pma.conf -O /etc/httpd/conf.d/phpMyAdmin.conf
wget $CHOST/$VERSION/pma.conf -O /etc/phpMyAdmin/config.inc.php
sed -i "s/%blowfish_secret%/$(gen_pass)/g" /etc/phpMyAdmin/config.inc.php
chmod 777 /var/lib/php/session

# Roundcube configuration
#wget $CHOST/$VERSION/httpd-webmail.conf -O /etc/httpd/conf.d/roundcubemail.conf
#wget $CHOST/$VERSION/roundcube-main.conf -O /etc/roundcubemail/main.inc.php
#wget $CHOST/$VERSION/roundcube-db.conf -O /etc/roundcubemail/db.inc.php
#wget $CHOST/$VERSION/roundcube-driver.php -O \
#    /usr/share/roundcubemail/plugins/password/drivers/vesta.php
#wget $CHOST/$VERSION/roundcube-pw.conf -O \
#    /usr/share/roundcubemail/plugins/password/config.inc.php
#chmod a+r /etc/roundcubemail/*
#r="$(gen_pass)"
#mysql -e "CREATE DATABASE roundcube"
#mysql -e "GRANT ALL ON roundcube.* TO roundcube@localhost IDENTIFIED BY '$r'"
#sed -i "s/%password%/$r/g" /etc/roundcubemail/db.inc.php
#if [ -e "/usr/share/roundcubemail/SQL/mysql.initial.sql" ]; then
#    mysql roundcube < /usr/share/roundcubemail/SQL/mysql.initial.sql
#else
#    mysql roundcube < /usr/share/doc/roundcubemail-*/SQL/mysql.initial.sql
#fi


