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
# $Id: NetBSD.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
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

. os/fakeroot.sh

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

os/elf.sh

find data -type f | xargs chmod -w

(
	set -e
	echo "@name $PKGNAME"
	cd data
	find */dt -type d | while read N
	do
		echo "@pkgdir $N"
	done
	for d in etc/pam.d
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
) > meta/CONTENTS

echo "CDE - Common Desktop Environment" > meta/COMMENT

cat > meta/DESC << EOF
The Common Desktop Environment was created by a collaboration of Sun, HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of commercial UNIXs, it is now available as open-source software for the first time.
EOF

cp meta/* log/

pkg_create -v -B meta/BUILD_INFO -P "$PKGDEP" -c meta/COMMENT -g wheel -u root -d meta/DESC -I / -f meta/CONTENTS -p data -F xz "$PKGNAME.tgz"

tar tvfJ "$PKGNAME.tgz" | grep "+CONTENTS
+COMMENT
+DESC
+BUILD_INFO
etc/pam.d/dt
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm"
