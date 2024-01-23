# Maintainer: rhubarb-geek-nz@users.sourceforge.net
pkgname=cdesktopenv
pkgver=2.4.0
pkgrel=1
epoch=
pkgdesc="CDE - Common Desktop Environment"
arch=("$CARCH")
url="https://sourceforge.net/projects/cdesktopenv/"
license=('LGPL2')
groups=()
depends=('xorg-server' 'dnsutils' 'libxinerama' 'libxss' 'ncurses' 'openmotif' 'rpcbind' 'xbitmaps' 'ksh' 'tcl' 'compress' 'libxaw' 'xorg-xrdb' 'xorg-xset' 'xorg-xsetroot' 'xorg-mkfontscale' 'xorg-bdftopcf' 'xorg-fonts-100dpi' 'xorg-fonts-75dpi' 'xorg-fonts-misc' 'xorg-fonts-cyrillic' 'xorg-fonts-type1' 'libutempter')
makedepends=('xorg-server-devel' 'bison' 'flex' 'bc' 'rpcsvc-proto' 'usr-lib-cpp')
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
source=("https://sourceforge.net/projects/cdesktopenv/files/src/cde-2.4.0.tar.gz")
sha256sums=("023df9d71f625583f36c2e3f7e57ddf85a8798eda203b40ba583c12c0c446e1e")

build() {
	cd "cde-$pkgver"
	LANG=C make World
}

package() {
	cd "cde-$pkgver"
	mkdir -p "$pkgdir/usr/lib/systemd/system"

    install -d "$pkgdir/usr/dt"
    install -d "$pkgdir/etc/dt"
    install -d "$pkgdir/var/dt"

    LANG=C admin/IntegTools/dbTools/installCDE -s "$(pwd)" -destdir "$pkgdir" -DontRunScripts

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

	chmod -w "$pkgdir/usr/lib/systemd/system/dtlogin.service"
}
