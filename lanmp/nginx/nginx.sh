#!/bin/bash

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
pkgver=1.2.0
pkgdesc="lightweight HTTP server and IMAP/POP3 proxy server"
depends=('libpcre3-dev' 'zlib1g-dev' 'libssl-dev')
url="http://nginx.org"
source="http://nginx.org/download/${pkgname}-${pkgver}.tar.gz"

md5sums="a02ef93d65a7031a1ea3256ad5eba626"

echo -e "\E[1;32m==>\E[m Making package: ${pkgname}-${pkgver}"

echo -e "\E[1;32m==>\E[m Installing depends packages"
for i in ${depends[@]}; do
    sudo apt-get install -y ${i};
done;


if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.gz ]; then
  echo -e "\E[1;32m==>\E[m ${pkgname}-${pkgver}.tar.gz [found]"
  else
  echo -e "\E[1;33m==> Warning\E[m: ${pkgname}-${pkgver}.tar.gz not found. download now......"
  wget -q -c ${source} -O ${srcdir}/${pkgname}-${pkgver}.tar.gz
fi

check() {
	filemd5=$(md5sum ${srcdir}/${pkgname}-${pkgver}.tar.gz | cut -d" " -f1)
	echo -e "\E[1;32m==>\E[m Validating source files with md5sums..."
	if [ "$filemd5" != "$md5sums" ]; then
		echo -e "\E[1;34m ->\E[m ${pkgname}-${pkgver}.tar.gz... Failed"
		echo -e "\E[1;31m==> ERROR\E[m: One or more files did not pass the validity check!"
		exit 1
	else
		echo -e "\E[1;34m ->\E[m ${pkgname}-${pkgver}.tar.gz... Passed"
		sleep 2
	fi
}

build() {
    cd ${srcdir}
    echo -e "\E[1;32m==>\E[m Extracting Sources..."
    echo -e "\E[1;34m ->\E[m Extracting ${pkgname}-${pkgver}.tar.gz with bsdtar"
    tar zxf ${pkgname}-${pkgver}.tar.gz
    echo -e "\E[1;32m==>\E[m Starting build()..."
    sleep 1
    cd ${srcdir}/${pkgname}-${pkgver}
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
        --with-http_sub_module \
        --with-ipv6 \
        --http-scgi-temp-path=${_tmp_path} \
        --http-uwsgi-temp-path=${_tmp_path} \
        --with-pcre-jit \
        --with-http_realip_module
        #--add-module=/usr/lib/passenger/ext/nginx \
        #--with-http_mp4_module \
        #--with-http_realip_module \
        #--with-http_addition_module \
        #--with-http_xslt_module \
        #--with-http_image_filter_module \
        #--with-http_geoip_module \
        #--with-http_flv_module \
        #--with-http_gzip_static_module \
        #--with-http_random_index_module \
        #--with-http_secure_link_module \
        #--with-http_degradation_module \
        #--with-http_perl_module \

    make
}

package() {
    echo -e "\E[1;32m==>\E[m Starting package()..."
    
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

    echo -e "\E[1;32m==>\E[m All Files Installed in $pkgdir, you can copy them to /"
}

check
build
package

# End of nginx.sh
