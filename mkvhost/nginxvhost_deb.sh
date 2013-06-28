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

nginxavailable="/etc/nginx/sites-available"
nginxenabled="/etc/nginx/sites-enabled"
serverroot="/srv/http"
logdir="/var/log/nginx"

domain=$1

domain_nowww=${domain#www.}

if [ $# -gt 1 ]; then
    alias_domain=$@
    alias_domain=${alias_domain#*" "}
    alias="
server {
    listen       80;
    server_name  $alias_domain;
    return       301 http://$domain\$request_uri;
}
"

fi

echo "==> Creating vhost config file";
cat >$nginxavailable/$domain_nowww.conf<<eof
#
# $domain
#
$alias
server {
    listen   80; ## listen for ipv4; this line is default and implied

    server_name  $domain;
    root         /srv/http/$domain_nowww/htdocs;
    index        index.html index.htm index.php;
    access_log   $logdir/$domain_nowww-access.log;
    error_log    $logdir/$domain_nowww-error.log;

    location ~ \.(js|css|jpg|jpeg|png|ico|gif|bmp)(\?.*)$ {
        add_header Cache-Control public;
        expires    1w;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000 or sock
    #
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass            unix:/var/run/php5-fpm.sock;
        fastcgi_index           index.php;
        fastcgi_param           SCRIPT_FILENAME    \$request_filename;
        include                 fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
eof

echo "==> Enableing config"
ln -s $nginxavailable/$domain_nowww.conf $nginxenabled/$domain_nowww.conf

echo "==> mkdir webroot directory"
mkdir -p $serverroot/$domain_nowww/htdocs

echo "==> restart Nginx"
/etc/init.d/nginx restart
