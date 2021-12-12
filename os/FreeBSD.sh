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
# $Id: FreeBSD.sh 98 2021-12-12 12:37:08Z rhubarb-geek-nz $
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
maintainer rhubarb-geek-nz@users.sourceforge.net
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

echo ---- MANIFEST START ---
cat meta/MANIFEST
echo ---- MANIFEST END ---

find data -type f | xargs chmod -w

chmod 2555 data/usr/dt/bin/dtmail
chmod 2555 data/usr/dt/bin/dtmailpr
chmod 4555 data/usr/dt/bin/dtappgather

(
	cd data
	find */dt -type d | while read N
	do
		echo @dir $N
	done
	find */dt -type f | (
		CURGRP=
		GRP=

		while read N
		do
			case "$N" in
				usr/dt/bin/dtmail | usr/dt/bin/dtmailpr )
					GRP="mail"
					;;
				* )
					GRP=
					;;
			esac

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

			echo "$N"
		done
	)
	find */dt -type l
) > meta/PLIST

pkg create -M meta/MANIFEST -o . -r data -v -p meta/PLIST
