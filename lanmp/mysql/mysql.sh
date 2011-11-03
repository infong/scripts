#!/bin/bash

# Build mysql 

pkgname=mysql
pkgver=5.5.14
url="http://www.mysql.com/"
srcdir=$(pwd)/mysql
depends=('cmake' 'openssl' 'libssl-dev' 'zlib1g-dev' 'libncurses5-dev' 'bison')
source=("http://mysql.he.net/Downloads/MySQL-5.5/${pkgname}-${pkgver}.tar.gz")

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
mkdir build
cd build

# Comment 2 lines below, if somethins wrong when building
CFLAGS="-fPIC ${CFLAGS} -fno-strict-aliasing -DBIG_JOINS=1 -fomit-frame-pointer" \
CXXFLAGS="-fPIC ${CXXFLAGS} -fno-strict-aliasing -DBIG_JOINS=1 -felide-constructors -fno-rtti" \
cmake ../mysql-5.5.14 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DMANUFACTURER="MySQL" \
    -DSYSCONFDIR=/etc/mysql \
    -DMYSQL_DATADIR=/var/lib/mysql \
    -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysqld.sock \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DENABLED_LOCAL_INFILE=ON \
    -DINSTALL_INFODIR=share/mysql/docs \
    -DINSTALL_MANDIR=share/man \
    -DINSTALL_PLUGINDIR=/usr/lib/mysql/plugin \
    -DINSTALL_SCRIPTDIR=bin \
    -DINSTALL_INCLUDEDIR=include/mysql \
    -DINSTALL_DOCREADMEDIR=share/mysql \
    -DINSTALL_SUPPORTFILESDIR=share/mysql \
    -DINSTALL_MYSQLSHAREDIR=share/mysql \
    -DINSTALL_DOCDIR=share/mysql/docs \
    -DINSTALL_SHAREDIR=share/mysql \
    -DWITH_READLINE=ON \
    -DWITH_ZLIB=system \
    -DWITH_SSL=system \
    -DWITH_LIBWRAP=ON \
    -DWITH_MYSQLD_LDFLAGS="${LDFLAGS}" \
    -DWITH_EXTRA_CHARSETS=complex \
    -DWITH_EMBEDDED_SERVER=ON \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
    -DWITHOUT_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITHOUT_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITHOUT_FEDERATED_STORAGE_ENGINE=1

make

install -d /etc/mysql
install -d /etc/mysql/conf.d
install -m655 ${srcdir}/my.cnf /etc/mysql/my.cnf
install -m755 support-files/mysql.server /etc/init.d/mysql
make install

groupadd -g 89 mysql &>/dev/null
useradd -u 89 -g mysql -d /var/lib/mysql -s /bin/false mysql &>/dev/null
install -d /var/log/mysql
cd /usr; /usr/bin/mysql_install_db --user=mysql --basedir=/usr
chown -R wmysql:mysql var/lib/mysql &>/dev/null

