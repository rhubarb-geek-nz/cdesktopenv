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
# $Id: FreeBSD.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
#

VERSION="$1"
SVNREV="$2"

DEPLIST="xorg iconv bdftopcf libXScrnSaver open-motif tcl86 xorg-fonts ksh93"

test -n "$VERSION"

if test -n "$SVNREV"
then
	if test "$SVNREV" -gt 0
	then
		VERSION="$VERSION"_"$SVNREV"
	fi
fi

PKGNAME=cdesktopenv

if test -z "$MAINTAINER"
then
	if git config user.email > /dev/null
	then
		MAINTAINER="$(git config user.email)"
	else
		MAINTAINER="$(id -un)@$(hostname)"
	fi
fi

. os/fakeroot.sh

mkdir meta

(
	cat << EOF
name $PKGNAME
version $VERSION
comment CDE - Common Desktop Environment
www https://sourceforge.net/projects/cdesktopenv/
origin x11/cde
desc: <<EOD
The Common Desktop Environment was created by a collaboration of Sun, HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of commercial UNIXs, it is now available as open-source software for the first time.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "LGPL2"
]
categories: [
    "x11"
]
EOF
	echo "deps: {"
	for d in $DEPLIST
	do
		ORIGIN=$(pkg info -q --origin $d)
		VERS=$(pkg info $d | grep Version | while read A B C D; do echo $C; break; done | sed "y/,/ /" | while read E F; do echo $E; done)
		if test "$d" = "ksh93"
		then
			echo "   $d: {origin: $ORIGIN, version: $VERS}"
		else
			echo "   $d: {origin: $ORIGIN, version: $VERS},"
		fi
	done
	echo "}"
)  > meta/MANIFEST

os/elf.sh

find data -type f | xargs chmod -w

(
	cd data
	for d in */dt usr/local/etc/pam.d etc/pam.d
	do
		if test -d "$d"
		then
			find "$d" -type d | while read N
			do
				echo @dir $N
			done
		fi
	done
	for d in usr/local/etc/pam.d etc/pam.d
	do
		if test -d "$d"
		then
			find "$d" -type f
		fi
	done
	find */dt -type f | (
		CURGRP=
		CURMOD=
		DESTDIR=$(pwd)

		while read N
		do
			GRP=$(fakeroot_chgrp "$N")
			MOD=

			if test -f "$N" && test -x "$N"
			then
				if test -g "$N"
				then
					MOD=2555
				fi
				if test -u "$N"
				then
					MOD=4555
				fi
			fi

			if test "$CURGRP" != "$GRP"
			then
				CURGRP="$GRP"
				if test -n "$CURGRP"
				then
					echo "@group $CURGRP"
				else
					echo "@group"
				fi
			fi

			if test "$CURMOD" != "$MOD"
			then
				CURMOD="$MOD"
				if test -n "$CURMOD"
				then
					echo "@mode $CURMOD"
				else
					echo "@mode"
				fi
			fi

			echo "$N"
		done
	)
	find */dt -type l
) > meta/PLIST

cp meta/PLIST log/PLIST

pkg create -M meta/MANIFEST -o . -r data -v -p meta/PLIST

ls -ld "$PKGNAME-$VERSION.pkg"

tar tvfz "$PKGNAME-$VERSION.pkg" | grep "+COMPACT_MANIFEST
+MANIFEST
etc/pam.d/dt
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm"
