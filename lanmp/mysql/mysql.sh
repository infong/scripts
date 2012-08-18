#!/bin/bash

# Build mysql 

pkgname=mysql
pkgver="5.5.25a"
url="http://www.mysql.com/"
srcdir=$(pwd)/mysql
depends=('cmake' 'openssl' 'libssl-dev' 'zlib1g-dev' 'libncurses5-dev' 'bison')
source=("http://mysql.he.net/Downloads/MySQL-5.5/${pkgname}-${pkgver}.tar.gz")

md5sums="0841fbc79872c5f467d8c8842f45257a"

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
mkdir build
cd build

echo -e "\E[1;32m==>\E[m Starting build()..."

# Comment 2 lines below, if somethins wrong when building
CFLAGS="-fPIC ${CFLAGS} -fno-strict-aliasing -DBIG_JOINS=1 -fomit-frame-pointer" \
CXXFLAGS="-fPIC ${CXXFLAGS} -fno-strict-aliasing -DBIG_JOINS=1 -felide-constructors -fno-rtti" \
cmake ../${pkgname}-${pkgver} \
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

pkgdir=${srcdir}/pkg
install -d $pkgdir/etc/mysql
install -d $pkgdir/etc/mysql/conf.d
install -m655 ${srcdir}/my.cnf $pkgdir/etc/mysql/my.cnf
install -m755 support-files/mysql.server $pkgdir/etc/init.d/mysql
make DESTDIR=${pkgdir} install

echo -e "\E[1;32m==>\E[m Adding mysql user, if it Failed, please add by yourself..."
groupadd -g 89 mysql &>/dev/null
useradd -u 89 -g mysql -d /var/lib/mysql -s /bin/false mysql &>/dev/null
install -d $pkgdir/var/log/mysql

echo -e "\E[1;32m==>\E[m All Files Installed in $pkgdir, you can copy them to /"
echo -e "  -> After that do:"
echo -e "    cd /usr; /usr/bin/mysql_install_db --user=mysql --basedir=/usr"
echo -e "    chown -R mysql:mysql var/lib/mysql &>/dev/null"
