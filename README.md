## Reinstall phpMyAdmin

``
yum install phpMyAdmin
wget http://c.vestacp.com/0.9.8/rhel/httpd-pma.conf -O /etc/httpd/conf.d/phpMyAdmin.conf
wget http://c.vestacp.com/0.9.8/rhel/pma.conf -O /etc/phpMyAdmin/config.inc.php
``

## Pipe Mysql DB

``mysqldump --user=XXX --password=XXX --host=SOURCE_HOST SOURCE_DB | mysql --user=XXX --password=XXX --host=DESTINATION_HOST DESTINATION_DB``

