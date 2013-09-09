#!/bin/sh

if [ $# -lt 1 ] || [ "$1"x = "--help"x ] || [ "$1"x = "-h"x ]; then
  echo "Usage:"
  echo "  sudo `basename $0` domain [alias]"
  echo "Examples:"
  echo "  sudo `basename $0` www.example.com [example.com]"
  exit 1
fi

if [ $(id -u) != "0" ]; then
  echo "Error: Oops, this script should run as root."
  exit 1
fi

apacheavailable="/etc/apache2/sites-available"
apacheenabled="/etc/apache2/sites-enabled"
serverroot="/srv/http"
logdir="/var/log/apache2"

domain=$1

domain_nowww=${domain#www.}

if [ $# -gt 1 ]; then
    alias_domain=$@
    alias_domain=${alias_domain#*" "}

fi

echo "==> Creating vhost config file";
cat >$apacheavailable/$domain_nowww.conf<<eof
#
# $domain
#
<VirtualHost *:80>
        ServerName  $domain
        ServerAlias $alias_domain
        ServerAdmin support@netcec.com

        DocumentRoot $serverroot/$domain_nowww/htdocs
        <Directory $serverroot/$domain_nowww/htdocs/>
                Options -Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                allow from all
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/error-$domain_nowww.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog \${APACHE_LOG_DIR}/access-$domain_nowww.log combined
</VirtualHost>

eof

echo "==> Enableing config"
ln -s $apacheavailable/$domain_nowww.conf $apacheenabled/$domain_nowww.conf

echo "==> mkdir webroot directory"
mkdir -p $serverroot/$domain_nowww/htdocs

echo "==> restart APACHE"
/etc/init.d/apache2 restart
