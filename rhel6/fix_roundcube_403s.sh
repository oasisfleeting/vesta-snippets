```
#!/bin/bash

export PATH=$PATH:/sbin
RHOST='r.vestacp.com'
CHOST='c.vestacp.com'
REPO='cmmnt'
VERSION='0.9.8/rhel'
YUM_REPO='/etc/yum.repos.d/vesta.repo'

# Roundcube configuration
wget $CHOST/$VERSION/httpd-webmail.conf -O /etc/httpd/conf.d/roundcubemail.conf
wget $CHOST/$VERSION/roundcube-main.conf -O /etc/roundcubemail/main.inc.php
wget $CHOST/$VERSION/roundcube-db.conf -O /etc/roundcubemail/db.inc.php
wget $CHOST/$VERSION/roundcube-driver.php -O \
    /usr/share/roundcubemail/plugins/password/drivers/vesta.php
wget $CHOST/$VERSION/roundcube-pw.conf -O \
    /usr/share/roundcubemail/plugins/password/config.inc.php
chmod a+r /etc/roundcubemail/*
r="mySuperSecretRoundCubeMySqlPassword!@#$%"

mysql -e "GRANT ALL ON roundcube.* TO roundcube@localhost IDENTIFIED BY '$r'"
sed -i "s/%password%/$r/g" /etc/roundcubemail/db.inc.php
```
