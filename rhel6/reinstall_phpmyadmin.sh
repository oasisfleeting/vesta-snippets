#!/bin/bash
yum install phpMyAdmin
wget http://c.vestacp.com/0.9.8/rhel/httpd-pma.conf -O /etc/httpd/conf.d/phpMyAdmin.conf
wget http://c.vestacp.com/0.9.8/rhel/pma.conf -O /etc/phpMyAdmin/config.inc.php
