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
# $Id: SunOSdir2pkg.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
#

. os/fakeroot.sh

getField()
{
	(
		IFS_ORIG="$IFS"
		IFS="="
		while read N M
		do
			(
				IFS="$IFS_ORIG"

				if test "$N" = "$2"
				then
					sh -c "echo $M"
					break
				fi	
			)
		done <"$1"
	)
}

INTDIR=$1
SRCDIR=$2
PKGDIR=$3

ARCH_P=`uname -p`
ARCH_M=`uname -m`

test -d "$INTDIR"
test -d "$SRCDIR"
test -d "$PKGDIR"

PKGINFO="$INTDIR/pkginfo"

cat >"$PKGINFO"

PKG=`getField "$PKGINFO" PKG`
BASEDIR=`getField "$PKGINFO" BASEDIR`
VERSION=`getField "$PKGINFO" VERSION`
ARCH=`getField "$PKGINFO" ARCH`

test "$PKG" != ""
test "$BASEDIR" != ""
test "$VERSION" != ""

if test "$ARCH" = ""
then
	ARCH=$ARCH_P
	echo "ARCH=\"$ARCH\"" >>"$PKGINFO"
fi

USRGRP=$(stat -c%G /usr)
BINGRP=$(stat -c%G /usr/bin)

PKGFILE="$PKGDIR/$PKG-$VERSION-$ARCH_P.pkg"

PKGPROTO="$INTDIR/prototype.$PKG"

mapDirs()
{
	(
		cd "$SRCDIR/$BASEDIR"
		ls
	) | while read N
	do
		if test -d "$SRCDIR/$BASEDIR/$N"
		then
			echo "$SRCDIR/$BASEDIR/$N=$N"
		else
			if test -H "$SRCDIR/$BASEDIR/$N"
			then
				echo "$SRCDIR/$BASEDIR/$N"
			else
				echo "$SRCDIR/$BASEDIR/$N=$N"
			fi
		fi
	done
}

setOwner()
{
	while read A B C D E F
	do
		case "$A" in
		f )
			case "$D" in
			*5* )
				case "$C" in
					*=* )
						LEFT=$(echo $C | sed "y/=/ /" | sed "y/'/ /" | while read A B C; do echo $A; break; done )
						RIGHT=$(echo $C | sed "y/=/ /" | sed "y/'/ /" | while read A B C; do echo $B; break; done )
						GROUP=$(fakeroot_chgrp $LEFT)
						if test -z "$GROUP"
						then
							GROUP=bin
						fi
						echo "$A" "$B" "$C" "$D" root $GROUP
						;;
					* )
						echo "$A" "$B" "$C" "$D" root bin
						;;
				esac
				;;
			* )
				echo "$A" "$B" "$C" "$D" root root
				;;
			esac
			;;
		s )
			echo "$A" "$B" "$C"
			;;
		d )
			if test -d "/$D"
			then
				echo "DIR $D already exists" >&2
			else
				case "$C" in
				*/bin | */lib | */lib/amd64 | */lib/sparcv9 )
					echo "$A" "$B" "$C" "$D"  root "$BINGRP"
					;;
				* )
					echo "$A" "$B" "$C" "$D"  root "$USRGRP"
					;;
				esac
			fi
			;;
		* )
			;;
		esac
	done
}

addInfo()
{
	echo "i" "pkginfo"
	echo "i" "depend"
	cat
}

pkgproto `mapDirs` | setOwner | addInfo > "$PKGPROTO"

PKGTMP="$INTDIR/image.$PKG"

rm -rf "$PKGTMP"

mkdir "$PKGTMP"

cp "$PKGPROTO" "log/prototype.$PKG"

pkgmk -o -r . -d "$PKGTMP" -f "$PKGPROTO" "$PKG"

cat </dev/null >"$PKGFILE"

pkgtrans -s "$PKGTMP" "$PKGFILE" "$PKG"

rm -rf "$PKGTMP" "$PKGPROTO" "$PKGINFO"
