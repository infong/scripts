#!/bin/bash

# build Apache2

pkgname=httpd
pkgver=2.2.21

# build with mod_fcgid?
build_fcgid=false
fcgidver=2.3.6

depends=('libpcre3-dev' 'libssl-dev' 'libldap-dev' 'libdb-dev')
mpmtype=('prefork' 'worker')
srcdir=$(pwd)/apache

# install depends packages
for i in ${depends[@]}; do
        apt-get install -y ${i};
done;

# check file
if [ -s ${srcdir}/${pkgname}-${pkgver}.tar.bz2 ]; then
  echo -e "\E[1;32m${pkgname}-${pkgver}.tar.bz2 [found]\E[m"
  else
  echo -e "\E[1;31mWarning: ${pkgname}-${pkgver}.tar.bz2 not found. download now......\E[m"
  wget -c http://www.apache.org/dist/httpd/httpd-${pkgver}.tar.bz2 -O apache/${pkgname}-${pkgver}.tar.bz2
fi


cd ${srcdir}
tar jxvf ${pkgname}-${pkgver}.tar.bz2
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

# build apr-util
mkdir build-apu
cd build-apu
../srclib/apr-util/configure --prefix=/usr --with-apr=/usr \
    --without-pgsql --without-mysql --without-sqlite2 --without-sqlite3 \
    --with-berkeley-db=/usr --with-gdbm=/usr --with-ldap
make
make install
cd "${srcdir}/httpd-${pkgver}"

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
                make install
        else
                install -m755 httpd "/usr/sbin/httpd.${mpm}"
        fi
        popd
done

install -D -m755 "${srcdir}/init.d.httpd" "/etc/init.d/httpd"

# symlinks for /etc/httpd
ln -fs /var/log/httpd "/etc/httpd/logs"
ln -fs /var/run/httpd "/etc/httpd/run"
ln -fs /usr/lib/httpd/modules "/etc/httpd/modules"
ln -fs /usr/lib/httpd/build "/etc/httpd/build"

# set sane defaults
sed -e 's#/usr/lib/httpd/modules/#modules/#' \
    -e 's|#\(Include conf/extra/httpd-multilang-errordoc.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-autoindex.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-languages.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-userdir.conf\)|\1|' \
    -e 's|#\(Include conf/extra/httpd-default.conf\)|\1|' \
    -i "/etc/httpd/conf/httpd.conf"

# add http user and group
groupadd -g 99 http
useradd -g 99 -u 99 -s /bin/false http

echo -e "\E[1;32mdone!\E[m"

if $build_fcgid; then
    cd ${srcdir}
    tar zxvf mod_fcgid-{$fcgidver}.tar.gz
    cd mod_fcgid-{$fcgidver}
    ./configure.apxs
    make
    install modules/fcgid/.libs/mod_fcgid.so /usr/lib/httpd/modules/mod_fcgid.so
    #make install
fi

