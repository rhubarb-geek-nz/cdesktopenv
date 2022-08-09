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
# $Id: SunOS.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
#

test -n "$1"
test -n "$2"

DIRNAME=$(dirname "$0")
MACHINE_ARCH=$(uname -m)
VERSION="$1"
SVNREV="$2"
VENDOR="cdesktopenv.sf.net"

if test -z "$MAINTAINER"
then
	if git config user.email > /dev/null
	then
		MAINTAINER="$(git config user.email)"
	else
		MAINTAINER="$(id -un)@$(hostname)"
	fi
fi

if test -z "$DESTDIR"
then
	DESTDIR="$(pwd)/data"
	export DESTDIR
fi

clean()
{
	rm -rf intdir dist dist2
}

trap clean 0

clean

ls -ld data/usr/dt/lib

rm -rf intdir dist

mkdir intdir dist

if test -d data-64
then
	case "$(uname -p)" in
		i386 )
			ARCH64=amd64
			;;
		* )
			ARCH64=sparcv9
			;;
	esac
	(
		set -e
		cd data-64/usr/dt/lib
		tar cf - lib*
	) | (
		set -e
		cd data/usr/dt/lib
		mkdir "$ARCH64"
		ln -s "$ARCH64" 64
		cd "$ARCH64"
		tar xvf -
	)
fi

os/elf.sh

(
	set -e
	cd data

	if test ! -h usr/dt/include
	then
		if test ! -d usr/dt/share/include
		then
			echo MOVING INCLUDES TO SHARE
			mv usr/dt/include usr/dt/share/include
		fi
	fi
)

(
	set -e
	cd data

	for d in var/dt etc/dt usr/dt etc/pam.d
	do
		if test -d "$d"
		then
			find "$d" | while read N
			do
				if grep " $N\$" ../os/SunOS.map >/dev/null
				then
					grep " $N\$" ../os/SunOS.map | while read A B; do echo $A $N; done
				else
					M=$(basename $N)
					if grep " $M\$" ../os/SunOS.map >/dev/null
					then
						grep " $M\$" ../os/SunOS.map | while read A B; do echo $A $N; done
					else
						echo ERROR $N or $M not found >&2
						echo SUNWdtaux $N
					fi
				fi
			done
		fi
	done
) | while read PKG FILE
do
	mkdir -p "intdir/$PKG"

	ISDIR=false

	if test ! -h "data/$FILE"
	then
		if test -d "data/$FILE"
		then
			ISDIR=true
		fi
	fi

	if $ISDIR
	then
		mkdir -p "intdir/$PKG/$FILE"
	else
		(
			cd "data"
			tar cf - "$FILE"
		) | (
			cd "intdir/$PKG"
			tar xf -
		)

		if test -u "data/$FILE"
		then
			echo "SETUID $FILE"
			chmod u+s "intdir/$PKG/$FILE"
		fi

		if test -g "data/$FILE"
		then
			echo "SETGID $FILE"
			chmod g+s "intdir/$PKG/$FILE"
		fi

		if test -f "data/$FILE"
		then
			chmod -w "intdir/$PKG/$FILE"
		fi
	fi
done

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtbas dist <<EOF
CATEGORY="system"
NAME="CDE application basic runtime environment"
PKG="SUNWdtbas"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtab dist <<EOF
CATEGORY="system"
NAME="CDE Dtbuilder"
PKG="SUNWdtab"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtct dist <<EOF
CATEGORY="system"
NAME="CDE UTF-8 Code Conversion Tool"
PKG="SUNWdtct"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtdmn dist <<EOF
CATEGORY="system"
NAME="CDE daemons"
PKG="SUNWdtdmn"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtdte dist <<EOF
CATEGORY="system"
NAME="Solaris Desktop Login Environment"
PKG="SUNWdtdte"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdthe dist <<EOF
CATEGORY="system"
NAME="CDE Help Runtime"
PKG="SUNWdthe"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdthev dist <<EOF
CATEGORY="system"
NAME="CDE Help Volumes"
PKG="SUNWdthev"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtinc dist <<EOF
CATEGORY="system"
NAME="CDE Includes"
PKG="SUNWdtinc"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtwm dist <<EOF
CATEGORY="system"
NAME="CDE Desktop Window Manager"
PKG="SUNWdtwm"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtdem dist <<EOF
CATEGORY="system"
NAME="CDE Demos"
PKG="SUNWdtdem"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtdst dist <<EOF
CATEGORY="system"
NAME="CDE Desktop Applications"
PKG="SUNWdtdst"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWtltk dist <<EOF
CATEGORY="system"
NAME="CDE Desktop ToolTalk runtime"
PKG="SUNWtltk"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWcsr Core Solaris, (Root)
P SUNWcsu Core Solaris, (Usr)
P SUNWcsd Core Solaris Devices
P SUNWdtbas CDE base
P SUNWdtdmn CDE daemons
P SUNWdtdte Desktop Login environment
P SUNWdticn CDE icons
P SUNWmfrun Motif RunTime Kit
P SUNWtltk ToolTalk runtime
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtezt dist <<EOF
CATEGORY="system"
NAME="CDE Solaris Desktop Extensions Applications"
PKG="SUNWdtezt"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

if test -d intdir/SUNWdthed
then
	cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWmfrun Motif RunTime Kit
P SUNWcsr Core Solaris, (Root)
P SUNWcsu Core Solaris, (Usr)
P SUNWcsd Core Solaris Devices
EOF

	os/SunOSdir2pkg.sh intdir intdir/SUNWdthed dist <<EOF
CATEGORY="system"
NAME="CDE Help Developer Environment"
PKG="SUNWdthed"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF
fi

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWcsr Core Solaris, (Root)
P SUNWcsu Core Solaris, (Usr)
P SUNWcsd Core Solaris Devices
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdticn dist <<EOF
CATEGORY="system"
NAME="CDE icons"
PKG="SUNWdticn"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

cat > intdir/depend <<EOF
P SUNWdtcor Solaris Desktop /usr/dt filesystem anchor
P SUNWcsr Core Solaris, (Root)
P SUNWcsu Core Solaris, (Usr)
P SUNWcsd Core Solaris Devices
EOF

os/SunOSdir2pkg.sh intdir intdir/SUNWdtma dist <<EOF
CATEGORY="system"
NAME="CDE man pages"
PKG="SUNWdtma"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF

if test -d intdir/SUNWdtaux
then
	os/SunOSdir2pkg.sh intdir intdir/SUNWdtaux dist <<EOF
CATEGORY="system"
NAME="CDE auxiliary content"
PKG="SUNWdtaux"
VERSION="$VERSION"
VENDOR="$VENDOR"
EMAIL="$MAINTAINER"
BASEDIR="/"
EOF
fi

rm intdir/depend

mkdir dist2

for d in dist/*.pkg
do
	pkginfo -d "$d"	| while read A B C
	do
		pkgtrans "$d" dist2 "$B"
	done
done

PKGFILE="$(pwd)/cdesktopenv-$VERSION-$(uname -p).pkg"

cat </dev/null >"$PKGFILE"

echo Writing "$PKGFILE"

pkgtrans -s dist2 "$PKGFILE" all

echo --- pkg --

pkginfo -d "$PKGFILE"

pkginfo -d "$PKGFILE" | wc -l

echo --- intdir --

ls intdir

ls intdir | wc -l

grep " etc/pam.d/dt
 usr/dt/bin/dtappgather=
 usr/dt/bin/dtmail=
 usr/dt/bin/dtsession=
 usr/dt/lib/64
libDtTerm.so
 usr/dt/bin/dtterm=" log/prototype.*

rm -rf tmp

mkdir tmp

pkgtrans "$PKGFILE" tmp all

grep " etc/pam.d/dt
 usr/dt/bin/dtappgather 
 usr/dt/bin/dtmail 
 usr/dt/bin/dtsession 
 usr/dt/lib/64
libDtTerm.so
 usr/dt/bin/dtterm " tmp/*/pkgmap

rm -rf tmp
