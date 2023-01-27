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
# $Id: package.sh 225 2023-01-27 06:36:11Z rhubarb-geek-nz $
#

if test 0 -eq $(id -u)
then
	echo This should not need to be run as root, stay safe out there. >&2
	false
fi

if test -e /usr/dt/bin/dtsession
then
	echo Do not build with an installed version, they may conflict and result in an ambiguous build. >&2
	false
fi

MACHINE_ARCH="$(uname -m)"
OPSYS="$(uname -s)"

getVersion()
{
	VERSION=
	INCL=

	for d in /usr/X11R?/include /usr/local/include
	do
		if test -f "$d/X11/Intrinsic.h"
		then
			INCL="$INCL -I$d"
			break
		fi
	done	

	(
		cpp $INCL <<EOF
#include "cdesktopenv-code/cde/include/Dt/Dt.h"
DtVERSION_STRING
EOF
	) | grep CDE | tail -1 | sed "y/\"/ /" | (
		while read N
		do
			for d in $N
			do
				if test -n "$d"
				then
					VERSION=$d
				fi
			done
		done
		echo $VERSION
	)
}

cleanup()
{
	for d in cdesktopenv-code filesets rpms rpm.spec meta data data-64
	do
		if test -w "$d"
		then
			rm -rf "$d"

			if test -d "$d"
			then
				chmod -R +w "$d"
				rm -rf "$d"
			fi
		fi
	done
}

if test -n "$1"
then
	CHECKOUT_VERSION="$1"
fi

cleanup

trap cleanup 0

rm -rf log

DESTDIR=$(pwd)/data
DESTDIR64=$(pwd)/data-64

. "os/$OPSYS.cf"

if test -z "$MAKE"
then
	if which gmake
	then
		MAKE=gmake
	else
		MAKE=make
	fi
fi

if test ! -d cdesktopenv-code
then

	if test -n "$CHECKOUT_VERSION"
	then
		GIT_EXTRA_ARGS="--branch $CHECKOUT_VERSION"
	else
		GIT_EXTRA_ARGS=
	fi

	if git clone --recursive $GIT_EXTRA_ARGS --single-branch https://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code
	then
		echo git clone ok
	else
		rm -rf cdesktopenv-code

		test -n "$CHECKOUT_VERSION"

		git clone --recursive https://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code

		(
			set -e

			cd cdesktopenv-code

			git checkout --recurse-submodules "$CHECKOUT_VERSION"
		)

		CHECKOUT_VERSION=
	fi

	(
		set -e

		cd cdesktopenv-code

		GITREV="$(git rev-parse HEAD)"

		for PATCHREV in "../patches/$GITREV.$OPSYS.$MACHINE_ARCH" "../patches/$GITREV.$OPSYS" "../patches/$GITREV"
		do
			if test -f "$PATCHREV"
			then
				echo apply "$PATCHREV"
				git apply "$PATCHREV"
				break
			fi
		done
	)

	if test "$OPSYS" = "SunOS"
	then
		(
			set -e

			cd cdesktopenv-code/cde

			./autogen.sh

			./configure --prefix=/usr/dt $CONFIGURATION_PARAMS MAKE="$MAKE" CFLAGS="-m64 $CFLAGS" CXXFLAGS="-m64 $CXXFLAGS" --enable-spanish --enable-italian --enable-french --enable-german

			(
				set -e

				cd util

				MAKE="$MAKE" "$MAKE"
			)

			(
				set -e

				cd lib

				MAKE="$MAKE" "$MAKE"

				MAKE="$MAKE" DESTDIR="$DESTDIR64" "$MAKE" install
			)

			(
				set -e

				cd programs/dtinfo/DtMmdb

				MAKE="$MAKE" "$MAKE"

				MAKE="$MAKE" DESTDIR="$DESTDIR64" "$MAKE" install
			)

			MAKE="$MAKE" "$MAKE" clean			
		)
	fi

	(
		set -e

		cd cdesktopenv-code/cde

		./autogen.sh

		./configure --prefix=/usr/dt $CONFIGURATION_PARAMS MAKE="$MAKE" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" --enable-spanish --enable-italian --enable-french --enable-german

		MAKE="$MAKE" "$MAKE"
	)
fi

ls -ld cdesktopenv-code/cde/include/Dt/Dt.h cdesktopenv-code/cde/programs/dtksh/dtksh cdesktopenv-code/cde/programs/dtdocbook/instant/instant

GITREV=$(cd cdesktopenv-code ; git rev-parse HEAD)
GITHASH=$(cd cdesktopenv-code ; git rev-parse --short HEAD)

if test -n "$2"
then
	VERSION="$2"
else
	VERSION=$(getVersion)

	if test -z "$CHECKOUT_VERSION"
	then
		VERSION="$VERSION.$GITHASH"
	fi
fi

SVNREV=0

for d in "patches/$GITREV.$OPSYS.$MACHINE_ARCH" "patches/$GITREV.$OPSYS" "patches/$GITREV"
do
	if test -f "$d"
	then
		if ( cd .git 2>/dev/null )
		then
			SVNREV=$( echo $SVNREV + $( git log --oneline "$d" | wc -l) | bc)
		else
			svn log -q "$d" > /dev/null

			SVNREV=$( echo $SVNREV + $( svn log -q "$d" | grep -v "\-----------" | wc -l) | bc)
		fi
	fi
done

echo VERSION=$VERSION SVNREV=$SVNREV

test -n "$VERSION"

mkdir data

PWD=$(pwd)

fakeroot <<EOF
set -e
cd "$PWD"
(
	set -e
	cd cdesktopenv-code/cde
	MAKE="$MAKE" "$MAKE" install "DESTDIR=$DESTDIR"
)
mkdir -p log
(
	set -e
	cd data
	find * | xargs ls -ld 
) > log/install.lst
if test -d data-64
then
	(
		set -e
		cd data-64
		find * | xargs ls -ld 
	) > log/install64.lst
fi
if test ! -d data/usr/dt/share/examples
then
	if test ! -h data/usr/dt/examples
	then
		ln -s share/examples data/usr/dt/examples
	fi
	(
		set -e
		cd cdesktopenv-code/cde
		tar cf - examples
	) | (
		set -e
		cd data/usr/dt/share
		tar xf -
		for d in hp ibm sun
		do
			D=\$(echo \$d | tr "[:lower:]" "[:upper:]" )
			find examples -type f -name Makefile.\$d | while read N
			do
				mv "\$N" \$(dirname "\$N")/"Makefile.\$D"
			done
		done
	)
fi
"os/$OPSYS.sh" "$VERSION" "$SVNREV"
EOF
