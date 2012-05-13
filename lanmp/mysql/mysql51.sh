#!/bin/bash

pkgname=mysql
pkgver=5.1.63
url="http://www.mysql.com/"
srcdir=$(pwd)/mysql51
depends=('openssl' 'libssl-dev' 'zlib1g-dev' 'libncurses5-dev')
source=("http://mysql.he.net/Downloads/MySQL-5.1/${pkgname}-${pkgver}.tar.gz")

md5sums="672167c3f03f969febae66c43859d76d"

echo -e "\E[1;32m==>\E[m Making package: ${pkgname}-${pkgver}"

echo -e "\E[1;32m==>\E[m Installing depends packages"
for dep in ${depends[@]}; do
    sudo apt-get install -y ${dep};
done;

if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.gz ]; then
    echo -e "\E[1;32m==>\E[m ${pkgname}-${pkgver}.tar.gz [found]\E[m"
else
    echo -e "\E[1;33m==> Warning\E[m: ${pkgname}-${pkgver}.tar.gz not found. download now......\E[m"
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

check

echo -e "\E[1;32m==>\E[m Extracting Sources..."
echo -e "\E[1;34m ->\E[m Extracting ${pkgname}-${pkgver}.tar.gz with bsdtar"
cd "${srcdir}"
tar zxf ${pkgname}-${pkgver}.tar.gz
cd ${pkgname}-${pkgver}
patch -Np0 -i "${srcdir}/skip-abi-check.patch"

echo -e "\E[1;32m==>\E[m Starting build()..."

CFLAGS="-fPIC ${CFLAGS} -fno-strict-aliasing -DBIG_JOINS=1 -fomit-frame-pointer" \
CXXFLAGS="-fPIC ${CXXFLAGS} -fno-strict-aliasing -DBIG_JOINS=1 -felide-constructors -fno-rtti" \
./configure --prefix=/usr \
    --libexecdir=/usr/sbin \
    --localstatedir=/var \
    --sysconfdir=/etc/mysql \
    --without-docs \
    --with-readline \
    --without-libedit \
    --with-ssl \
    --with-libwrap \
    --with-zlib-dir=/usr \
    --with-charset=utf8 \
    --with-collation=utf8_general_ci \
    --with-extra-charsets=complex \
    --with-embedded-server \
    --with-unix-socket-path=/var/run/mysqld/mysqld.sock \
    --enable-local-infile \
    --with-plugins=innobase,innodb_plugin \
    #--datadir=/var/lib/mysql

make

pkgdir=${srcdir}/pkg
install -d $pkgdir/etc/mysql
install -d $pkgdir/etc/mysql/conf.d
install -m655 ${srcdir}/my.cnf $pkgdir/etc/mysql/my.cnf
install -m755 support-files/mysql.server $pkgdir/etc/init.d/mysql
make DESTDIR=${pkgdir} install
  
  # create library symlinks in /usr/lib
ln -sf mysql/libmysqlclient.so.16 ${pkgdir}/usr/lib/libmysqlclient.so.16
ln -sf libmysqlclient.so.16 ${pkgdir}/usr/lib/libmysqlclient.so
ln -sf libmysqlclient.so.16 ${pkgdir}/usr/lib/libmysqlclient.so.1
ln -sf mysql/libmysqlclient_r.so.16  ${pkgdir}/usr/lib/libmysqlclient_r.so.16
ln -sf libmysqlclient_r.so.16 ${pkgdir}/usr/lib/libmysqlclient_r.so
ln -sf libmysqlclient_r.so.16 ${pkgdir}/usr/lib/libmysqlclient_r.so.1
install -d $pkgdir/var/log/mysql

echo -e "\E[1;32m==>\E[m Adding mysql user, if it Failed, please add by yourself..."
groupadd -g 89 mysql &>/dev/null
useradd -u 89 -g mysql -d /var/lib/mysql -s /bin/false mysql &>/dev/null

echo -e "\E[1;32m==>\E[m All Files Installed in $pkgdir, you can copy them to /"
echo -e "  -> After that do:"
echo -e "    cd /usr; /usr/bin/mysql_install_db --user=mysql --basedir=/usr"
echo -e "    chown -R mysql:mysql var/lib/mysql &>/dev/null"

rm -r ${pkgdir}/usr/{sql-bench,mysql-test}
