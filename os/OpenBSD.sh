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
# $Id: OpenBSD.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
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

PKGLIST="ksh93 motif tcl"
PKGDEPS=

for d in $PKGLIST
do
	pkg_info -P -q $d
	pkg_info -I -q $d
	PKGPATH=$(pkg_info -P -q $d)
	PKGSPEC=$(pkg_info -I -q $d)
	PKGDEPS="$PKGDEPS -P $PKGPATH:$d-*:$PKGSPEC"
done

if test -z "$MAINTAINER"
then
	if git config user.email > /dev/null
	then
		MAINTAINER="$(git config user.email)"
	else
		MAINTAINER="$(id -un)@$(hostname)"
	fi
fi

test -n "$VERSION"

. os/fakeroot.sh

mkdir meta

os/elf.sh

find data -type f | xargs chmod -w

(
	set -e
	cd data
	echo "@group"
	find */dt -type d | while read N
	do
		echo "@dir $N"
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

cp meta/CONTENTS log/

cat > meta/DESC << EOF
The Common Desktop Environment was created by a collaboration of Sun, HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of commercial UNIXs, it is now available as open-source software for the first time.
EOF

COMMENT="CDE - Common Desktop Environment"
MACHINE_ARCH=$(uname -p)
HOMEPAGE=https://sourceforge.net/projects/cdesktopenv/
FULLPKGPATH=x11/cde
FTP=yes
PKGNAME="cdesktopenv-$VERSION.tgz"

pkg_create 								\
        -A "$MACHINE_ARCH"				\
        -d meta/DESC 					\
		$PKGDEPS						\
        -D "COMMENT=$COMMENT" 			\
        -D "HOMEPAGE=$HOMEPAGE" 		\
        -D "MAINTAINER=$MAINTAINER" 	\
        -D "FULLPKGPATH=$FULLPKGPATH" 	\
        -D "FTP=$FTP" 					\
        -f meta/CONTENTS				\
        -B data 						\
        -p / 							\
        "$PKGNAME"

tar tvfz "$PKGNAME" | grep "+CONTENTS
+DESC
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm"

(
	trap 'rm -rf ./+CONTENTS' 0
	tar xvfz "$PKGNAME" +CONTENTS   
	grep -A2 "@group mail" +CONTENTS
)
