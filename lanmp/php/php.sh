#!/bin/bash
# php

pkgname=php
pkgver=5.4.6

url='http://www.php.net'
depends=('libxml2' 'libxml2-dev' 'libsqlite-dev' 'libsqlite-dev' 'libsqlite3-dev' 'sqlite' 'sqlite3' 'libdb-dev' 'libqdbm-dev' 'libc-client-dev' 'bzip2' 'lib32bz2-1.0' 'libncurses5-dev' 'zlib1g-dev' 'libxml2-dev' 'libssl-dev' 'libpng12-dev' 'libjpeg-dev' 'libfreetype6-dev' 'libfreetype6' 'libcurl3' 'zlibc' 'zlib1g' 'openssl' 'mcrypt' 'libxml2' 'libtool' 'libsasl2-dev' 'libpq-dev' 'libpq5' 'libpng-dev' 'libpng3' 'libpng12-0' 'libpcrecpp0' 'libpcre3-dev' 'libpcre3' 'libncurses5' 'libmhash-dev' 'libmhash2' 'libmcrypt-dev' 'libltdl-dev' 'libltdl3-dev' 'libjpeg62-dev' 'libjpeg62' 'libglib2.0-dev' 'libglib2.0-0' 'libevent-dev' 'libcurl4-openssl-dev' 'libc-client-dev' 'libbz2-dev' 'libbz2-1.0' 'gettext' 'curl' 'libgdbm-dev' 'libenchant-dev' 'libicu-dev' 'libgmp3-dev'  'unixodbc-dev' 'unixodbc' 'freetds-dev' 'libpspell-dev' 'libreadline-dev' 'libsnmp-dev' 'libtidy-dev' 'libxslt-dev' 'libexpat1-dev' 'libvpx-dev')
srcdir=$(pwd)/php
currdir=$(pwd)
pkgdir=${currdir}/pkg

md5sums="c9aa0f4996d1b91ee9e45afcfaeb5d2e"

echo -e "\E[1;32m==>\E[m Making package: ${pkgname}-${pkgver}"

echo -e "\E[1;32m==>\E[m Installing depends packages"
#for pkg in ${depends[@]}; do
#	sudo apt-get install -y ${pkg};
#done;


source=("http://www.php.net/distributions/${pkgname}-${pkgver}.tar.bz2")

if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.bz2 ]; then
  echo -e "\E[1;32m==>\E[m ${pkgname}-${pkgver}.tar.bz2 [found]\E[m"
else
  echo -e "\E[1;33m==> Warning\E[m: ${pkgname}-${pkgver}.tar.bz2 not found. download now......\E[m"
  wget -q -c ${source} -O ${srcdir}/${pkgname}-${pkgver}.tar.bz2
fi


check() {
	filemd5=$(md5sum ${srcdir}/${pkgname}-${pkgver}.tar.bz2 | cut -d" " -f1)
	echo -e "\E[1;32m==>\E[m Validating source files with md5sums..."
	if [ "$filemd5" != "$md5sums" ]; then
		echo -e "\E[1;34m ->\E[m ${pkgname}-${pkgver}.tar.bz2... Failed"
		echo -e "\E[1;31m==> ERROR\E[m: One or more files did not pass the validity check!"
		exit 1
	else
		echo -e "\E[1;34m ->\E[m ${pkgname}-${pkgver}.tar.bz2... Passed"
		sleep 2
	fi
}

check

export LDFLAGS="${LDFLAGS//-Wl,--as-needed}"
export LDFLAGS="${LDFLAGS//,--as-needed}"

phpconfig="--srcdir=../${pkgname}-${pkgver} \
	--config-cache \
	--prefix=/usr \
	--sysconfdir=/etc/php \
	--localstatedir=/var \
	--with-layout=GNU \
	--with-config-file-path=/etc/php \
	--with-config-file-scan-dir=/etc/php/conf.d \
	--disable-rpath \
	--mandir=/usr/share/man \
	--without-pear \
	"

phpextensions="--enable-bcmath=shared \
	--enable-calendar=shared \
	--enable-dba=shared \
	--enable-exif=shared \
	--enable-ftp=shared \
	--enable-gd-native-ttf \
	--enable-intl=shared \
	--enable-mbstring \
	--enable-phar=shared \
	--enable-posix=shared \
	--enable-shmop=shared \
	--enable-soap=shared \
	--enable-sockets=shared \
	--enable-sysvmsg=shared \
	--enable-sysvsem=shared \
	--enable-sysvshm=shared \
	--enable-zip=shared \
	--with-bz2=shared \
	--with-curl=shared \
	--with-db4=/usr \
	--with-enchant=shared,/usr \
	--with-freetype-dir=/usr \
	--with-gd=shared \
	--with-gdbm \
	--with-gettext=shared \
	--with-gmp=shared \
	--with-iconv=shared \
	--with-icu-dir=/usr \
	--with-imap-ssl \
	--with-imap=shared \
	--with-jpeg-dir=/usr \
	--with-vpx-dir=/usr \
	--with-ldap=shared \
	--with-ldap-sasl \
	--with-mcrypt=shared \
	--with-mhash \
	--with-mssql=shared \
	--with-mysql-sock=/var/run/mysqld/mysqld.sock \
	--with-mysql=shared,mysqlnd \
	--with-mysqli=shared,mysqlnd \
	--with-openssl=shared \
	--with-pcre-regex=/usr \
	--with-pdo-mysql=shared,mysqlnd \
	--with-pdo-odbc=shared,unixODBC,/usr \
	--with-pdo-pgsql=shared \
	--with-pdo-sqlite=shared,/usr \
	--with-pgsql=shared \
	--with-png-dir=/usr \
	--with-pspell=shared \
	--with-snmp=shared \
	--with-sqlite3=shared,/usr \
	--with-tidy=shared \
	--with-unixODBC=shared,/usr \
	--with-xmlrpc=shared \
	--with-xsl=shared \
	--with-zlib \
	--with-kerberos \
	"

cd ${srcdir}

echo -e "\E[1;32m==>\E[m Extracting Sources..."
echo -e "\E[1;34m ->\E[m Extracting ${pkgname}-${pkgver}.tar.bz2 with bsdtar"
mkdir -p ${srcdir}/src
tar jxf ${pkgname}-${pkgver}.tar.bz2 -C ${srcdir}/src/
cd ${srcdir}/src/${pkgname}-${pkgver}

echo -e "\E[1;32m==>\E[m Patching..."

patch -p0 -i ${srcdir}/php.ini.patch
patch -p0 -i ${srcdir}/php-fpm.conf.in.patch

#sed -i 's/PHP_EXTRA_VERSION=""/PHP_EXTRA_VERSION="-infong"/g' configure

EXTENSION_DIR=/usr/lib/php/modules
export EXTENSION_DIR
PEAR_INSTALLDIR=/usr/share/pear
export PEAR_INSTALLDIR

srcdir=${srcdir}/src
pkgbase=${pkgname}

echo -e "\E[1;32m==>\E[m Starting build php..."
#php
cd ${srcdir}
mkdir ${srcdir}/build-php
cd ${srcdir}/build-php
ln -s ../${pkgbase}-${pkgver}/configure
./configure ${phpconfig} \
	--disable-cgi \
	--with-readline \
	--enable-pcntl \
	${phpextensions}
make

echo -e "\E[1;32m==>\E[m Starting build php-cgi..."
# cgi and fcgi
# reuse the previous run; this will save us a lot of time
cp -a ${srcdir}/build-php ${srcdir}/build-cgi
cd ${srcdir}/build-cgi
./configure ${phpconfig} \
	--disable-cli \
	--enable-cgi \
	${phpextensions}
make

echo -e "\E[1;32m==>\E[m Starting build php-apache..."
# apache
cp -a ${srcdir}/build-php ${srcdir}/build-apache
cd ${srcdir}/build-apache
./configure ${phpconfig} \
	--disable-cli \
	--with-apxs2 \
	${phpextensions}
make

echo -e "\E[1;32m==>\E[m Starting build php-fpm..."
# fpm
cp -a ${srcdir}/build-php ${srcdir}/build-fpm
cd ${srcdir}/build-fpm
./configure ${phpconfig} \
	--disable-cli \
	--enable-fpm \
	--with-fpm-user=http \
	--with-fpm-group=http \
	${phpextensions}
make

#echo -e "\E[1;32m==>\E[m Starting build php-embed..."
## embed
#cp -a ${srcdir}/build-php ${srcdir}/build-embed
#cd ${srcdir}/build-embed
#./configure ${phpconfig} \
#	--disable-cli \
#	--enable-embed=shared \
#	${phpextensions}
#make

echo -e "\E[1;32m==>\E[m Starting build pear..."
# pear
cp -a ${srcdir}/build-php ${srcdir}/build-pear
cd ${srcdir}/build-pear
./configure ${phpconfig} \
	--disable-cgi \
	--with-readline \
	--enable-pcntl \
	--with-pear \
	${phpextensions}
make


package() {
	echo -e "\E[1;32m==>\E[m Starting package()..."
	cd ${srcdir}/build-php
	make -j1 INSTALL_ROOT=${pkgdir} install
	install -d -m755 ${pkgdir}/usr/share/pear
	# install php.ini
	install -D -m644 ${srcdir}/${pkgbase}-${pkgver}/php.ini-production ${pkgdir}/etc/php/php.ini
	install -d -m755 ${pkgdir}/etc/php/conf.d/

	# remove static modules
	rm -f ${pkgdir}/usr/lib/php/modules/*.a

	pkgdesc='CGI and FCGI SAPI for PHP'

	install -D -m755 ${srcdir}/build-cgi/sapi/cgi/php-cgi ${pkgdir}/usr/bin/php-cgi

	pkgdesc='Apache SAPI for PHP'

	install -D -m755 ${srcdir}/build-apache/libs/libphp5.so ${pkgdir}/usr/lib/httpd/modules/libphp5.so
	install -D -m644 ${srcdir}/../apache.conf ${pkgdir}/etc/httpd/conf/extra/php5_module.conf

	pkgdesc='FastCGI Process Manager for PHP'

	install -D -m755 ${srcdir}/build-fpm/sapi/fpm/php-fpm ${pkgdir}/usr/sbin/php-fpm
	install -D -m644 ${srcdir}/build-fpm/sapi/fpm/php-fpm.8 ${pkgdir}/usr/share/man/man8/php-fpm.8
	install -D -m644 ${srcdir}/build-fpm/sapi/fpm/php-fpm.conf ${pkgdir}/etc/php/php-fpm.conf
	install -D -m755 ${srcdir}/build-fpm/sapi/fpm/init.d.php-fpm ${pkgdir}/etc/init.d/php-fpm
#	install -D -m644 ${srcdir}/logrotate.d.php-fpm ${pkgdir}/etc/logrotate.d/php-fpm
	install -d -m755 ${pkgdir}/etc/php/fpm.d

#	pkgdesc='Embed SAPI for PHP'

#	install -D -m755 ${srcdir}/build-embed/libs/libphp5.so ${pkgdir}/usr/lib/libphp5.so
#	install -D -m644 ${srcdir}/${pkgbase}-${pkgver}/sapi/embed/php_embed.h ${pkgdir}/usr/include/php/sapi/embed/php_embed.h

	pkgdesc='PHP Extension and Application Repository'

	cd ${srcdir}/build-pear
	make -j1 install-pear INSTALL_ROOT=${pkgdir}
	rm -rf ${pkgdir}/usr/share/pear/.{channels,depdb,depdblock,filemap,lock,registry}
	echo -e "\E[1;32m==>\E[m All Files Installed in $pkgdir, you can copy them to /"
}

rm_dir(){
	
	echo -e "\E[1;32m==>\E[m Removing usless files..."
	local i
	while read i; do
		[ ! -e "$i" ] || rm -rf "$i"
	done < <(find ${pkgdir} -name '.*')
}

package
rm_dir
