#!/bin/bash

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





# Exim
wget $CHOST/$VERSION/exim.conf -O /etc/exim/exim.conf
if [ "$srv_type" != 'micro' ] &&  [ "$srv_type" != 'small' ]; then
    sed -i "s/#SPAM/SPAM/g" /etc/exim/exim.conf
    sed -i "s/#CLAMD/CLAMD/g" /etc/exim/exim.conf
fi
wget $CHOST/$VERSION/dnsbl.conf -O /etc/exim/dnsbl.conf
wget $CHOST/$VERSION/spam-blocks.conf -O /etc/exim/spam-blocks.conf
touch /etc/exim/white-blocks.conf
rm -rf /etc/exim/domains
mkdir -p /etc/exim/domains
chmod 640 /etc/exim/exim.conf
gpasswd -a exim mail
if [ -e /etc/init.d/sendmail ]; then
    chkconfig sendmail off
    service sendmail stop
fi
if [ -e /etc/init.d/postfix ]; then
    chkconfig postfix off
    service postfix stop
fi
rm -f /etc/alternatives/mta
ln -s /usr/sbin/sendmail.exim /etc/alternatives/mta
chkconfig exim on
service exim start
if [ "$?" -ne 0 ]; then
    echo "Error: exim start failed"
    exit 1
fi


# Dovecot configuration
if [ "$release" -eq '5' ]; then
    wget $CHOST/$VERSION/dovecot.conf -O /etc/dovecot.conf
else
    wget $CHOST/$VERSION/$release/dovecot.tar.gz -O  /etc/dovecot.tar.gz
    cd /etc/
    rm -rf dovecot
    tar -xzf dovecot.tar.gz
    rm -f dovecot.tar.gz
    chown -R root:root /etc/dovecot
fi
gpasswd -a dovecot mail
chkconfig dovecot on
service dovecot start
if [ "$?" -ne 0 ]; then
    echo "Error: dovecot start failed"
    exit 1
fi

# ClamAV configuration
if [ "$srv_type" = 'medium' ] ||  [ "$srv_type" = 'large' ]; then
    wget $CHOST/$VERSION/clamd.conf -O /etc/clamd.conf
    wget $CHOST/$VERSION/freshclam.conf -O /etc/freshclam.conf
    gpasswd -a clam exim
    gpasswd -a clam mail
    /usr/bin/freshclam
    chkconfig clamd on
    service clamd start
    if [ "$?" -ne 0 ]; then
        echo "Error: clamd start failed"
        exit 1
    fi
fi



#spammAssassin configuration
if [ "$srv_type" = 'medium' ] ||  [ "$srv_type" = 'large' ]; then
    chkconfig spamassassin on
    service spamassassin start
    if [ "$?" -ne 0 ]; then
        echo "Error: spamassassin start failed"
        exit 1
    fi
fi

# Fail2ban configuration
if [ -z "$disable_fail2ban" ]; then
    cd /etc
    wget $CHOST/$VERSION/fail2ban.tar.gz -O fail2ban.tar.gz
    tar -xzf fail2ban.tar.gz
    rm -f fail2ban.tar.gz
    chkconfig fail2ban on
    service fail2ban start
else
    sed -i "s/fail2ban//" $VESTA/conf/vestac.conf
fi

# php configuration
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php.ini
sed -i "s/;date.timezone =/date.timezone = UTC/g" /etc/php.ini

# phpMyAdmin configuration
wget $CHOST/$VERSION/httpd-pma.conf -O /etc/httpd/conf.d/phpMyAdmin.conf
wget $CHOST/$VERSION/pma.conf -O /etc/phpMyAdmin/config.inc.php
sed -i "s/%blowfish_secret%/$(gen_pass)/g" /etc/phpMyAdmin/config.inc.php
chmod 777 /var/lib/php/session



# Roundcube configuration
wget $CHOST/$VERSION/httpd-webmail.conf -O /etc/httpd/conf.d/roundcubemail.conf
wget $CHOST/$VERSION/roundcube-main.conf -O /etc/roundcubemail/main.inc.php
wget $CHOST/$VERSION/roundcube-db.conf -O /etc/roundcubemail/db.inc.php
wget $CHOST/$VERSION/roundcube-driver.php -O \
    /usr/share/roundcubemail/plugins/password/drivers/vesta.php
wget $CHOST/$VERSION/roundcube-pw.conf -O \
    /usr/share/roundcubemail/plugins/password/config.inc.php
chmod a+r /etc/roundcubemail/*
r="$(gen_pass)"
mysql -e "CREATE DATABASE roundcube"
mysql -e "GRANT ALL ON roundcube.* TO roundcube@localhost IDENTIFIED BY '$r'"
sed -i "s/%password%/$r/g" /etc/roundcubemail/db.inc.php
if [ -e "/usr/share/roundcubemail/SQL/mysql.initial.sql" ]; then
    mysql roundcube < /usr/share/roundcubemail/SQL/mysql.initial.sql
else
    mysql roundcube < /usr/share/doc/roundcubemail-*/SQL/mysql.initial.sql
fi



# Add default web domain
$VESTA/bin/v-add-web-domain admin default.domain $vst_ip

# Add default dns domain
$VESTA/bin/v-add-dns-domain admin default.domain $vst_ip

# Add default mail domain
$VESTA/bin/v-add-mail-domain admin default.domain

# Configuring crond
command='sudo /usr/local/vesta/bin/v-update-sys-queue disk'
$VESTA/bin/v-add-cron-job 'admin' '15' '02' '*' '*' '*' "$command"
command='sudo /usr/local/vesta/bin/v-update-sys-queue traffic'
$VESTA/bin/v-add-cron-job 'admin' '10' '00' '*' '*' '*' "$command"
command='sudo /usr/local/vesta/bin/v-update-sys-queue webstats'
$VESTA/bin/v-add-cron-job 'admin' '30' '03' '*' '*' '*' "$command"
command='sudo /usr/local/vesta/bin/v-update-sys-queue backup'
$VESTA/bin/v-add-cron-job 'admin' '*/5' '*' '*' '*' '*' "$command"
command='sudo /usr/local/vesta/bin/v-backup-users'
$VESTA/bin/v-add-cron-job 'admin' '10' '05' '*' '*' '*' "$command"
command='sudo /usr/local/vesta/bin/v-update-user-stats'
$VESTA/bin/v-add-cron-job 'admin' '20' '00' '*' '*' '*' "$command"
command='sudo /usr/local/vesta/bin/v-update-sys-rrd'
$VESTA/bin/v-add-cron-job 'admin' '*/5' '*' '*' '*' '*' "$command"

# Build inititall rrd images
$VESTA/bin/v-update-sys-rrd

# Enable file system quota
if [ "$quota" = 'yes' ]; then
    $VESTA/bin/v-add-sys-quota
fi

# Start system service
chkconfig vesta on
service vesta start
if [ "$?" -ne 0 ]; then
    echo "Error: vesta start failed"
    exit 1
fi



