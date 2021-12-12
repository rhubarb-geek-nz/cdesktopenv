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
# $Id: package.sh 10 2021-01-11 21:09:06Z rhubarb-geek-nz $
#

getVersion()
{
	VERSION=

	(
		cpp <<EOF
#include "/usr/dt/share/include/Dt/Dt.h"
DtVERSION_STRING
EOF
	) | tail -1 | sed "y/\"/ /" | (
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

if test -n "$1"
then
	VERSION="$1"
else
	VERSION=`getVersion`
fi

test -n "$VERSION"

if test -z "$DPKGARCH"
then
	DPKGARCH=`dpkg --print-architecture`
fi

cleanup()
{
	rm -rf data.tar.* control.tar.* control debian-binary
}

trap cleanup 0

CDE_INSTALLATION_TOP=/usr/dt
LIBLIST=
PATHLIST=
PKGLIST=
PKGNAME=x11-dt

if test -z "$OBJDUMP"
then
	OBJDUMP=objdump
fi

rotate()
{
	shift
	echo $@
}

first()
{
	echo $1
}

is_member()
{
	is_member_1=$1
	shift
	for is_member_i in $@
	do
		if test "$is_member_i" = "$is_member_1"
		then
			return 0
		fi
	done
	return 1
}

not_member()
{
	not_member_1=$1
	shift
	for not_member_i in $@
	do
		if test "$not_member_1" = "$not_member_i"
		then
			return 1
		fi
	done
	return 0
}

libconf()
{
	cat  /etc/ld.so.conf.d/*.conf | grep -v "# " | while read libconf_i
	do
		if test -d "$libconf_i"
		then
			echo "$libconf_i"
		fi
	done
}

findlib()
{
	case "$1" in
	/* )
		if test -f "$1"
		then
			echo "$1"
		fi
		;;
	* )
		for findlib_i in $PATHLIST
		do
			if test -f "$findlib_i/$1"
			then
				echo "$findlib_i/$1"
			fi
		done
		;;
	esac
}

get_needed()
{
	$OBJDUMP -p "$1" 2>/dev/null | while read A B C
	do
		case "$A" in
		NEEDED )
			echo "$B"
			;;
		* )
			;;
		esac
	done
}

PATHLIST="$PATHLIST `libconf`"

for d in $CDE_INSTALLATION_TOP/lib/* $CDE_INSTALLATION_TOP/bin/*
do
	if test -f "$d"
	then
		for e in `get_needed "$d"`
		do
			for f in `findlib "$e"`
			do
				if not_member "$f" $LIBLIST
				then
					LIBLIST="$LIBLIST $f"
				fi
			done
		done
	fi
done

echo PATHLIST=$PATHLIST
echo LIBLIST=$LIBLIST

for d in $LIBLIST
do
	if dpkg -S "$d" >/dev/null
	then
		DEPPKG=`dpkg -S "$d"`
		DEPPKG=`echo "$DEPPKG" | sed "y/:/ /"`
		DEPPKG=`first $DEPPKG`
		if not_member "$DEPPKG" $PKGLIST
		then
			PKGLIST="$PKGLIST $DEPPKG"
		fi
	fi
done

for d in rpcbind tcl ksh x11-xserver-utils xfonts-100dpi xfonts-100dpi-transcoded xfonts-75dpi xfonts-75dpi-transcoded
do
	if not_member "$d" $PKGLIST
	then
		PKGLIST="$PKGLIST $d"
	fi
done

echo PKGLIST=$PKGLIST

dpkg -l $PKGLIST

DEPENDS=

for d in $PKGLIST
do
	if test -z "$DEPENDS"
	then
		DEPENDS="$d"
	else
		DEPENDS="$DEPENDS, $d"
	fi
done

installedSize()
{
	du -sk /var/dt /etc/dt /usr/dt | (
		SIZE=0
		while read A B
		do
			SIZE=`echo $SIZE+$A | bc`
		done
		echo $SIZE
	)
}

SIZE=`installedSize`

mkdir control

cat >control/control <<EOF
Package: $PKGNAME
Version: $VERSION
Architecture: $DPKGARCH
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Depends: $DEPENDS
Section: x11
Provides: x11-dt-rte, x11-dt-lib, x11-dt-bitmaps, x11-dt-helprun, x11-dt-helpinfo, x11-dt-helpmin, x11-dt-tooltalk, x11-dt-adt
Priority: optional
Homepage: https://sourceforge.net/projects/cdesktopenv/
Installed-Size: $SIZE
Description: CDE - Common Desktop Environment
 The Common Desktop Environment, the classic UNIX desktop

EOF

cat control/control

cat >control/postinst <<EOF
#!/bin/sh -e
mkdir -p /var/spool/calendar
EOF

cat >control/postrm <<EOF
#!/bin/sh -e
case "\$1" in
	remove | purge )
		rm -rf /var/dt;
		;;
	* )
		;;
esac
EOF

chmod +x control/postinst control/postrm

echo "2.0" >debian-binary

for d in control
do
	(
		set -ex
		cd $d
		tar --owner=0 --group=0 --create --xz --file ../$d.tar.xz ./*
	)
done

(
	set -ex
	cd /
	tar --owner=0 --group=0 --create --xz --file - /usr/dt /etc/dt /var/dt
) > data.tar.xz

ar r "$PKGNAME"_"$VERSION"_"$DPKGARCH".deb debian-binary control.tar.* data.tar.*
