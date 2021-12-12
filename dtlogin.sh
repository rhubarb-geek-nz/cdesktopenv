#!/bin/sh -e
#
#  Copyright 2020, Roger Brown
#
#  This file is part of rhubarb pi.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: dtlogin.sh 10 2021-01-11 21:09:06Z rhubarb-geek-nz $
#

#
# Package from an idea from "https://sourceforge.net/p/cdesktopenv/wiki/CDE%20on%20the%20Raspberry%20Pi/"
#

cleanup()
{
	rm -rf control data data.tar.* control.tar.* debian-binary
}

cleanup

trap cleanup 0

first()
{
	echo "$1"
}

mkdir -p control data/etc/X11 data/lib/systemd/system data/etc/systemd/system

echo "/usr/dt/bin/dtlogin" > "data/etc/X11/default-display-manager"

cat > data/lib/systemd/system/dtlogin.service << EOF
[Unit]
Description=CDE Login Manager
Requires=rpcbind.service
After=systemd-user-sessions.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon
EOF

ln -s "/lib/systemd/system/dtlogin.service" data/etc/systemd/system/display-manager.service

# this last not needed if use raspi-config
ln -s "/lib/systemd/system/graphical.target" data/etc/systemd/system/default.target

(
	set -e
	cd data
	find * | while read N
	do
		set -e
		if test ! -d "$N"
		then
			if dpkg -S "$N"
			then
				false
			fi
		fi
	done
)

echo "2.0" > debian-binary

SIZE=`du -sk data`
SIZE=`first $SIZE`
PKGNAME=dtlogin-service
VERSION=1.0
ARCH=all

cat > control/control <<EOF
Package: $PKGNAME
Architecture: $ARCH
Version: $VERSION
Priority: optional
Section: x11
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Installed-Size: $SIZE
Depends: rpcbind, x11-dt, xserver-xorg-input-libinput, xserver-xorg-video-fbdev
Homepage: https://sourceforge.net/p/cdesktopenv/wiki/CDE%20on%20the%20Raspberry%20Pi/
Description: CDE Dt Login service
 The Common Desktop Environment Login service

EOF

cat control/control

for d in control data
do
	(
		set -e
		cd $d
		tar --owner=0 --group=0 --create --xz --file ../$d.tar.xz ./*
	)
done

rm -rf "$PKGNAME"_"$VERSION"_"$ARCH".deb

ar r "$PKGNAME"_"$VERSION"_"$ARCH".deb debian-binary control.tar.* data.tar.*
