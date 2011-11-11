#!/bin/bash

# build Apache2

pkgname=httpd
pkgver=2.2.21

# build with mod_fcgid?
build_fcgid=false
fcgidver=2.3.6

md5sums="1696ae62cd879ab1d4dd9ff021a470f2"

depends=('libpcre3-dev' 'libssl-dev' 'libldap-dev' 'libdb-dev')
mpmtype=('prefork' 'worker')
srcdir=$(pwd)/apache
pkgdir=$(pwd)/pkg

echo -e "\E[1;32m==>\E[m Making package: ${pkgname}-${pkgver}"

echo -e "\E[1;32m==>\E[m Installing depends packages"
# install depends packages
for i in ${depends[@]}; do
    apt-get install -y ${i};
done;

# check file
if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.bz2 ]; then
  echo -e "\E[1;32m==>\E[m${pkgname}-${pkgver}.tar.bz2 [Found]\E[m"
  else
  echo -e "\E[1;33m==> Warning\E[m: ${pkgname}-${pkgver}.tar.bz2 not found. download now......\E[m"
  wget -q -c http://www.apache.org/dist/httpd/httpd-${pkgver}.tar.bz2 -O apache/${pkgname}-${pkgver}.tar.bz2
fi

check() {
	filemd5=$(md5sum ${srcdir}/${pkgname}-${pkgver}.tar.bz2| cut -d" " -f1)
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

echo -e "\E[1;32m==>\E[m Extracting Sources..."
echo -e "\E[1;34m ->\E[m Extracting ${pkgname}-${pkgver}.tar.gz with bsdtar"

cd ${srcdir}
tar jxf ${pkgname}-${pkgver}.tar.bz2
cd "${srcdir}/httpd-${pkgver}"

sed -e 's#User daemon#User http#' \
    -e 's#Group daemon#Group http#' \
    -i docs/conf/httpd.conf.in

cat >>config.layout<<EOF
<Layout APACHE>
	prefix:          /etc/httpd
	exec_prefix:     /usr
	bindir:          /usr/bin
	sbindir:         /usr/sbin
	libdir:          /usr/lib/httpd
	libexecdir:      /usr/lib/httpd/modules
	mandir:          /usr/share/man
	sysconfdir:      /etc/httpd/conf
	datadir:         /usr/share/httpd
	installbuilddir: /usr/lib/httpd/build
	errordir:        /usr/share/httpd/error
	iconsdir:        /usr/share/httpd/icons
	htdocsdir:       /srv/http
	manualdir:       /usr/share/httpd/manual
	cgidir:          /srv/http/cgi-bin
	includedir:      /usr/include/httpd
	localstatedir:   /var
	runtimedir:      /var/run/httpd
	logfiledir:      /var/log/httpd
	proxycachedir:   /var/cache/httpd
</Layout>
EOF


echo -e "\E[1;32m==>\E[m Starting build apr..."
#build apr
mkdir build-apr
cd build-apr
../srclib/apr/configure --prefix=/usr --includedir=/usr/include/apr-1 \
    --with-installbuilddir=/usr/share/apr-1/build \
    --enable-nonportable-atomics \
    --with-devrandom=/dev/urandom
make
make install
cd "${srcdir}/httpd-${pkgver}"


echo -e "\E[1;32m==>\E[m Starting build apr-util..."
# build apr-util
mkdir build-apu
cd build-apu
../srclib/apr-util/configure --prefix=/usr --with-apr=/usr \
    --without-pgsql --without-mysql --without-sqlite2 --without-sqlite3 \
    --with-berkeley-db=/usr --with-gdbm=/usr --with-ldap
make
make install
cd "${srcdir}/httpd-${pkgver}"

echo -e "\E[1;32m==>\E[m Starting build httpd..."
# build httpd in mpm-prefork & mpm-worker
for mpm in ${mpmtype[@]} ; do
        mkdir build-${mpm}
        pushd build-${mpm}
        ../configure --enable-layout=APACHE \
                --enable-modules=all \
                --enable-mods-shared=all \
                --enable-so \
                --enable-suexec \
                --with-suexec-caller=http \
                --with-suexec-docroot=/srv/http \
                --with-suexec-logfile=/var/log/httpd/suexec.log \
                --with-suexec-bin=/usr/sbin/suexec \
                --with-suexec-uidmin=99 --with-suexec-gidmin=99 \
                --enable-ldap --enable-authnz-ldap \
                --enable-cache --enable-disk-cache --enable-mem-cache --enable-file-cache \
                --enable-ssl --with-ssl \
                --enable-deflate --enable-cgid \
                --enable-proxy --enable-proxy-connect \
                --enable-proxy-http --enable-proxy-ftp \
                --enable-dbd \
                --with-apr=/usr/bin/apr-1-config \
                --with-apr-util=/usr/bin/apu-1-config \
                --with-pcre=/usr \
                --with-mpm=${mpm}
        make
        if [ "${mpm}" = "prefork" ]; then
            make dDESTDIR=$pkgdir install
        else
            install -m755 httpd "$pkgdir/usr/sbin/httpd.${mpm}"
        fi
        popd
done

install -D -m755 "${srcdir}/init.d.httpd" "$pkgdir/etc/init.d/httpd"

# symlinks for /etc/httpd
ln -fs /var/log/httpd "$pkgdir/etc/httpd/logs"
ln -fs /var/run/httpd "$pkgdir/etc/httpd/run"
ln -fs /usr/lib/httpd/modules "$pkgdir/etc/httpd/modules"
ln -fs /usr/lib/httpd/build "$pkgdir/etc/httpd/build"

# set sane defaults
sed -e 's#/usr/lib/httpd/modules/#modules/#' \
    -e 's|#\(Include conf/extra/httpd-multilang-errordoc.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-autoindex.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-languages.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-userdir.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-default.conf\)|\1|' \
    -i "$pkgdir/etc/httpd/conf/httpd.conf"

echo -e "\E[1;32m==>\E[m Adding http user, if it Failed, please add by yourself..."
# add http user and group
groupadd -g 99 http
useradd -g 99 -u 99 -s /bin/false http

echo -e "\E[1;32m==>\E[m All Files Installed in $pkgdir, you can copy them to /"

