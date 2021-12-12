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
# $Id: NetBSD.sh 98 2021-12-12 12:37:08Z rhubarb-geek-nz $
#

VERSION="$1"
SVNREV="$2"

test -n "$VERSION"

if test -n "$SVNREV"
then
	if test "$SVNREV" -gt 0
	then
		VERSION="$VERSION"pl"$SVNREV"
	fi
fi

mkdir meta

PKGNAME=cdesktopenv-$VERSION
PKGDEP="ast-ksh freetype2 font-adobe-75dpi font-adobe-100dpi fontconfig motif tcl"

(
    set -e
    echo HOMEPAGE=https://sourceforge.net/projects/cdesktopenv/
    echo MACHINE_ARCH=$(uname -p)
    echo OPSYS=$(uname -s)
    echo OS_VERSION=$(uname -r)
    echo PKGTOOLS_VERSION=$(pkg_info -V)
) > meta/BUILD_INFO

find data -type f | xargs chmod -w

chmod 2555 data/usr/dt/bin/dtmail
chmod 2555 data/usr/dt/bin/dtmailpr
chmod 4555 data/usr/dt/bin/dtappgather

(
	set -e
	echo "@name $PKGNAME"
	cd data
	find */dt -type d | while read N
	do
		echo "@pkgdir $N"
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
) > meta/CONTENTS

echo "CDE - Common Desktop Environment" > meta/COMMENT

cat > meta/DESC << EOF
The Common Desktop Environment was created by a collaboration of Sun, HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of commercial UNIXs, it is now available as open-source software for the first time.
EOF

pkg_create -v -B meta/BUILD_INFO -P "$PKGDEP" -c meta/COMMENT -g wheel -u root -d meta/DESC -I / -f meta/CONTENTS -p data -F xz "$PKGNAME.tgz"
