#!/bin/bash

pkgname=mysql
pkgver=5.1.59
url="http://www.mysql.com/"
srcdir=$(pwd)/mysql51
depends=('openssl' 'libssl-dev' 'zlib1g-dev' 'libncurses5-dev')
source=("http://mysql.he.net/Downloads/MySQL-5.1/${pkgname}-${pkgver}.tar.gz")

if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.gz ]; then
    echo -e "\E[1;32m${pkgname}-${pkgver}.tar.gz [found]\E[m"
else
    echo -e "\E[1;31mWarning: ${pkgname}-${pkgver}.tar.gz not found. download now......\E[m"
    wget ${source} -O ${srcdir}/${pkgname}-${pkgver}.tar.gz
fi

for dep in ${depends[@]}; do
        apt-get install -y ${dep};
done;

cd "${srcdir}"
tar zxvf ${pkgname}-${pkgver}.tar.gz
cd ${pkgname}-${pkgver}
patch -Np0 -i "${srcdir}/skip-abi-check.patch"

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
    --with-plugins=innobase,innodb_plugin

make

pkgdir=${srcdir}/pkg

make DESTDIR=${pkgdir} install
  
  # create library symlinks in /usr/lib
ln -sf mysql/libmysqlclient.so.16 ${pkgdir}/usr/lib/libmysqlclient.so.16
ln -sf libmysqlclient.so.16 ${pkgdir}/usr/lib/libmysqlclient.so
ln -sf libmysqlclient.so.16 ${pkgdir}/usr/lib/libmysqlclient.so.1
ln -sf mysql/libmysqlclient_r.so.16  ${pkgdir}/usr/lib/libmysqlclient_r.so.16
ln -sf libmysqlclient_r.so.16 ${pkgdir}/usr/lib/libmysqlclient_r.so
ln -sf libmysqlclient_r.so.16 ${pkgdir}/usr/lib/libmysqlclient_r.so.1

install -Dm644 ${srcdir}/my.cnf ${pkgdir}/etc/mysql/my.cnf
install -Dm755 support-files/mysql.server ${pkgdir}/etc/init.d/mysqld
#install -Dm755 ${srcdir}/mysqld ${pkgdir}/etc/rc.d/mysqld

rm -r ${pkgdir}/usr/{sql-bench,mysql-test}
