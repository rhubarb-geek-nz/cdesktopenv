#!/bin/sh -e
#
#  Copyright 2021, Roger Brown
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
# $Id: slackware.sh 56 2021-05-27 22:35:00Z rhubarb-geek-nz $
#

OSID=slack
OSVER=$(. /etc/os-release ; echo $VERSION_ID)
PKGARCH=$(uname -m)
VERSION="$1"
SVNREV="$2"
USRGRP="$3"
DESTPKG=

case "$PKGARCH" in
	aarch64 | x86_64 )
		;;
	arm* )
		PKGARCH=arm
		;;
	* )
		PKGARCH=$(gcc -Q --help=target | grep "\-march=" | while read A B C; do echo $B; break; done)
		;;
esac

cleanup()
{
	rm -rf data
	if test -n "$DESTPKG"
	then
		rm -f "$DESTPKG"
	fi
}

trap cleanup 0

mkdir data/install

cat > data/install/slack-desc << EOF
           |-----handy-ruler------------------------------------------------------|
cdesktopenv: CDE - Common Desktop Environment
cdesktopenv:
cdesktopenv: The Common Desktop Environment was created by a collaboration of Sun,
cdesktopenv: HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of
cdesktopenv: commercial UNIXs, it is now available as open-source software for the
cdesktopenv: first time.
cdesktopenv:
cdesktopenv:
cdesktopenv:
cdesktopenv:
cdesktopenv:
EOF

chown -R 0:0 data

DESTPKG=cdesktopenv-"$VERSION"-"$PKGARCH"-"$SVNREV"_"$OSID$OSVER".txz

(
	set -e
	cd data
	/sbin/makepkg --linkadd y --chown n ../"$DESTPKG"
)

if test -n "$USRGRP"
then
	chown "$USRGRP" "$DESTPKG"
fi

DESTPKG=
