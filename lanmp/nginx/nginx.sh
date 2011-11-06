#!/bin/bash

#install nginx 

_doc_root=/srv/http/nginx
_server_root=/etc/nginx
_conf_path=${_server_root}/conf
_tmp_path=/var/spool/nginx
_log_path=/var/log/nginx
_user=http
_group=http

srcdir=$(pwd)/nginx

pkgdir=$(pwd)/pkg

pkgname=nginx
#pkgver=1.0.8
pkgver=1.1.6
pkgdesc="lightweight HTTP server and IMAP/POP3 proxy server"
depends=('libpcre3-dev' 'zlib1g-dev' 'libssl-dev')
url="http://nginx.org"
source="http://nginx.org/download/${pkgname}-${pkgver}.tar.gz"

for i in ${depends[@]}; do
    sudo apt-get install -y ${i};
done;

if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.gz ]; then
  echo -e "\E[1;32m${pkgname}-${pkgver}.tar.gz [found]\E[m"
  else
  echo -e "\E[1;31mWarning: ${pkgname}-${pkgver}.tar.gz not found. download now......\E[m"
  wget -c ${source} -O ${srcdir}/${pkgname}-${pkgver}.tar.gz
fi


build() {
    cd ${srcdir}
    tar zxvf ${pkgname}-${pkgver}.tar.gz
    cd ${srcdir}/${pkgname}-${pkgver}
    #sed -e 's%#define NGINX_VER          "nginx/" NGINX_VERSION%#define NGINX_VER          "lighttpd/inf-" NGINX_VERSION%' -i src/core/nginx.h
    ./configure \
        --prefix=${_server_root} \
        --sbin-path=/usr/sbin/nginx \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=${_tmp_path}/client_body_temp \
        --http-proxy-temp-path=${_tmp_path}/proxy_temp \
        --http-fastcgi-temp-path=${_tmp_path}/fastcgi_temp \
        --http-log-path=${_log_path}/access.log \
        --error-log-path=${_log_path}/error.log \
        --user=${_user} --group=${_group} \
        --with-imap --with-imap_ssl_module --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_dav_module \
        --with-http_gzip_static_module \
        --with-ipv6

    make
}

package() {
    cd $srcdir/nginx-${pkgver}
    make DESTDIR=$pkgdir install

    install -d $pkgdir/etc/logrotate.d/
    cat <<EOF > $pkgdir/etc/logrotate.d/nginx
    $_log_path/*log {
        create 640 http log
        compress
        postrotate
            /bin/kill -USR1 \`cat /var/run/nginx.pid 2>/dev/null\` 2> /dev/null || true
        endscript
    }
EOF

    sed -i -e "s/\<user\s\+\w\+;/user $_user;/g" $pkgdir/$_conf_path/nginx.conf

    install -d $pkgdir/$_tmp_path

    # move default document root outside server root
    install -d $pkgdir/$_doc_root
    mv $pkgdir/$_server_root/html/* $pkgdir/$_doc_root/
    rm -rf $pkgdir/$_server_root/html
    rm -f $pkgdir/$_doc_root/index.html

    # let's create links for relative paths in config file
    ln -s $_log_path $pkgdir/$_server_root/logs
    ln -s $_doc_root $pkgdir/$_server_root/html

    install -D -m755 $srcdir/nginx $pkgdir/etc/init.d/nginx
    install -D -m644 LICENSE $pkgdir/usr/share/licenses/nginx/LICENSE
    mkdir -p $pkgdir/etc/default
    echo "NGINX_CONFIG=/etc/nginx/conf/nginx.conf" >$pkgdir/etc/default/nginx
}

build
package
