# Maintainer: rhubarb-geek-nz@users.sourceforge.net
pkgname=cdesktopenv
pkgver=2.5.1
pkgrel=1
epoch=
pkgdesc="CDE - Common Desktop Environment"
arch=("$CARCH")
url="https://sourceforge.net/projects/cdesktopenv/"
license=('LGPL2')
groups=()
depends=('xorg-server' 'dnsutils' 'libxinerama' 'libxss' 'ncurses' 'openmotif' 'rpcbind' 'xbitmaps' 'ksh' 'tcl' 'compress' 'libxaw' 'xorg-xrdb' 'xorg-xset' 'xorg-xsetroot' 'xorg-mkfontscale' 'xorg-bdftopcf' 'xorg-fonts-100dpi' 'xorg-fonts-75dpi' 'xorg-fonts-misc' 'xorg-fonts-cyrillic' 'xorg-fonts-type1' 'libutempter')
makedepends=('xorg-server-devel' 'git' 'bison' 'flex' 'rpcsvc-proto' 'libtool' 'autoconf' 'automake' 'opensp')
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
noextract=()
md5sums=()
validpgpkeys=()

prepare() {
	git clone --branch "$pkgver" --single-branch --recursive https://git.code.sf.net/p/cdesktopenv/code "$pkgname-$pkgver"
	cd "$pkgname-$pkgver"
}

build() {
	cd "$pkgname-$pkgver/cde"
	./autogen.sh
	./configure --disable-static --prefix=/usr/dt --enable-spanish --enable-italian --enable-french --enable-german
	LANG=C make
}

check() {
	cd "$pkgname-$pkgver/cde"
	ls -ld include/Dt/Dt.h programs/dtksh/dtksh programs/dtdocbook/instant/instant
	grep "DtVERSION_STRING" include/Dt/Dt.h
	grep "#define DtVERSION_STRING \"CDE Version $pkgver\"" include/Dt/Dt.h
}

package() {
	cd "$pkgname-$pkgver/cde"

	mkdir -p "$pkgdir/usr/lib/systemd/system"

	cat > "$pkgdir/usr/lib/systemd/system/dtlogin.service" <<EOF
[Unit]
Description=CDE login service
Documentation=man:dtlogin(1)
Requires=rpcbind.service
After=systemd-user-sessions.service plymouth-quit.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon

[Install]
Alias=display-manager.service
EOF

	LANG=C DESTDIR="$pkgdir" make install

	find "$pkgdir" -type f -name "lib*.la" | xargs rm
}
