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
# $Id: Linux.sh 108 2021-12-14 23:47:54Z rhubarb-geek-nz $
#

osRelease()
{
	(
		set -e
		. /etc/os-release
		case "$1" in
			ID )
				echo "$ID"
				;;
			VERSION_ID )
				echo "$VERSION_ID"
				;;
			* )
			;;
		esac
	)
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
	(
		MACHINE=$(uname -m)
		if ls /etc/ld.so.conf.d/$MACHINE-*.conf 1>&2
		then
			cat /etc/ld.so.conf.d/$MACHINE-*.conf
		else
			cat /etc/ld.so.conf.d/*.conf 
		fi
	) | grep -v "# " | while read libconf_i
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

osLike()
{
	test -f /etc/os-release 

	(
		. /etc/os-release
		echo $ID $ID_LIKE 	
	)
}

cleanup()
{
	for d in rpms rpm.spec
	do
		if test -w "$d"
		then
			rm -rf "$d"
		fi
	done

	rm -rf data.tar.* control.tar.* debian-binary
}

test -n "$1"
test -n "$2"

DIRNAME=$(dirname "$0")
MACHINE_ARCH=$(uname -m)
VERSION="$1"
SVNREV="$2"
MAKERPM=false
MAKEDEB=false
MADEPKG=false
MAKESLACK=false
MAILAPPS="usr/dt/bin/dtmail usr/dt/bin/dtmailpr"
ROOTAPPS="usr/dt/bin/dtappgather"

SVNREV=$(echo 1+$SVNREV | bc)

for d in $(osLike)
do
	case "$d" in
		debian | ubuntu )
			MAKEDEB=true
			;;
		rhel | centos | fedora | suse | opensuse )
			MAKERPM=true
			;;
		slackware )
			MAKESLACK=true
			;;
		* )
			;;
	esac

	if $MAKEDEB
	then
		break
	fi

	if $MAKERPM
	then
		break
	fi

	if $MAKESLACK
	then
		break
	fi
done

cleanup

trap cleanup 0

if test -z "$OBJDUMP"
then
	OBJDUMP=objdump
fi

test -d data

find data -type f | while read N
do
	if test -x "$N"
	then
		if "$OBJDUMP" -p "$N" >/dev/null 2>&1
		then
			strip "$N"
		fi
	else
		BN=$(basename "$N")
		case "$BN" in
			lib*.so* )
				if "$OBJDUMP" -p "$N"
				then
					strip "$N"
				fi
				;;
			* )
				;;
		esac
	fi
done

ID=$(osRelease ID | sed "y/-/./")
VERSION_ID=$(osRelease VERSION_ID)
RELEASE="$SVNREV.$ID.$VERSION_ID"

if $MAKEDEB
then
	find data/usr -type f | xargs chmod -w

	dpkg --print-architecture
	DPKGARCH=$(dpkg --print-architecture)
	PATHLIST="$(libconf) data/usr/dt/lib"
	SIZE=$(du -sk data)
	SIZE=$(first $SIZE)
	PKGLIST="rpcbind tcl ksh x11-xserver-utils xfonts-100dpi xfonts-100dpi-transcoded xfonts-75dpi xfonts-75dpi-transcoded"
	LIBLIST=
	DEPENDS=

	if test -x data/usr/dt
	then
		for d in `find data/usr/dt -type f`
		do
			if $OBJDUMP -p "$d" 2>/dev/null >/dev/null
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
	fi

	for d in $LIBLIST
	do
		case "$d" in
			data/usr/dt/lib/* )
				;;
			* )
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
				;;
		esac
	done

	for d in $PKGLIST
	do
		if test -z "$DEPENDS"
		then
			DEPENDS="$d"
		else
			DEPENDS="$DEPENDS, $d"
		fi
	done

	mkdir -p data/control/DEBIAN

	cat > data/control/DEBIAN/control <<EOF
Package: cdesktopenv
Version: $VERSION-$RELEASE
Architecture: $DPKGARCH
Depends: $DEPENDS
Provides: dtlogin
Section: x11
Priority: optional
Homepage: https://sourceforge.net/projects/cdesktopenv/
Installed-Size: $SIZE
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Description: CDE - Common Desktop Environment
EOF

	(
		set -e

		cd data

		dpkg-deb --build control control.deb

		ar x control.deb

		mv debian-binary control.tar.* ..

		DATA_TAR=$(ls data.tar.*)

		ls -ld "$DATA_TAR"

		rm -rf data.tar.* control control.deb

		if test -n "$MAILAPPS"
		then
			mkdir mailbox

			mv $MAILAPPS mailbox
		fi

		if test -n "$ROOTAPPS"
		then
			chmod 4555 $ROOTAPPS
		fi

		tar --owner=0 --group=0 --create --file data.tar */dt

		if test -n "$MAILAPPS"
		then
			mv mailbox/* usr/dt/bin

			rmdir mailbox

			chmod 2555 $MAILAPPS

			tar --owner=0 --group=mail --create --file mail.tar $MAILAPPS

			tar --catenate --file data.tar mail.tar
		fi

		case "$DATA_TAR" in
			data.tar.gz )
				gzip data.tar
				;;
			data.tar.xz )
				xz data.tar
				;;
			data.tar.zst )
				zstd --rm data.tar
				;;
			* )
				echo unknown format "$DATA_TAR" >&2
				false
				;;
		esac

		mv "$DATA_TAR" ..
	)

	ar r cdesktopenv_"$VERSION-$RELEASE"_"$DPKGARCH".deb debian-binary control.tar.* data.tar.*

	MADEPKG=true
fi

if $MAKERPM
then
	find data/usr -type f | xargs chmod -w

	rpmbuild --version

	(
		cd data

		cat <<EOF
Summary: CDE - Common Desktop Environment
Name: cdesktopenv
Version: $VERSION
Release: $RELEASE
Provides: dtlogin
License: LGPLv2+
Group: User Interface/X
URL: https://sourceforge.net/projects/cdesktopenv/
Prefix: /

%description
CDE - The Common Desktop Environment is X Windows desktop 
environment that was commonly used on commercial UNIX variants 
such as Sun Solaris, HP-UX and IBM AIX. Developed between 1993 
and 1999, it has now been released under an Open Source 
licence by The Open Group.

%files
%defattr(-,root,root)
EOF

		find */dt | while read N
		do
			if test -h "$N"
			then
				echo "/$N"
			else
				if test -d "$N"
				then
					echo "%dir %attr(555,root,root) /$N"
				else
					case "$N" in
						usr/dt/bin/dtappgather )
							echo "%attr(4555,root,root) /$N"
							;;
						usr/dt/bin/dtmail | usr/dt/bin/dtmailpr )
							echo "%attr(2555,root,mail) /$N"
							;;
						* )
							if test -x "$N"
							then
								echo "%attr(555,root,root) /$N"
							else
								echo "%attr(444,root,root) /$N"
							fi
							;;
					esac
				fi
			fi
		done

		cat <<EOF

%clean
EOF
	) > rpm.spec

	PWD=$(pwd)
	rpmbuild --buildroot "$PWD/data" --define "_rpmdir $PWD/rpms" --define "_build_id_links none" -bb "$PWD/rpm.spec"

	MADEPKG=true
fi

if $MAKESLACK
then
	OSID=slack
	OSVER=$(. /etc/os-release ; echo $VERSION_ID)
	PKGARCH=$(uname -m)
	PKGNAME=cdesktopenv

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

	DESTPKG=$PKGNAME-"$VERSION"-"$PKGARCH"-"$SVNREV"_"$OSID$OSVER".txz

	mkdir data/install data/mailbox data/root

	cat > data/install/slack-desc << EOF
        |-----handy-ruler------------------------------------------------------|
$PKGNAME: CDE - Common Desktop Environment
$PKGNAME:
$PKGNAME: The Common Desktop Environment was created by a collaboration of Sun,
$PKGNAME: HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of
$PKGNAME: commercial UNIXs, it is now available as open-source software for the
$PKGNAME: first time.
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
EOF

	find data -type f | xargs chmod -w

	(
		set -e
		cd data

		chmod 4555 $ROOTAPPS
		chmod 2555 $MAILAPPS

		mv $MAILAPPS mailbox

		(
			find */dt -type l | while read N
			do
				D=$(dirname $N)
				B=$(basename $N)
				L=$(readlink $N)
	
				echo "( cd $D ; rm -rf $B )"
				echo "( cd $D ; ln -sf $L $B )"

				rm "$N"
			done 
		) > install/doinst.sh

		chmod +x install/doinst.sh

		tar --owner=0 --group=0 --create --file data.tar */dt
		tar --owner=0 --group=0 --create --file install.tar install
	
		mv mailbox/* usr/dt/bin
		tar --owner=0 --group=mail --create --file mail.tar $MAILAPPS

		(
			cd root
			tar  --owner=0 --group=0 --create --file ../root.tar .
		)

		tar --concatenate --file root.tar data.tar
		tar --concatenate --file root.tar mail.tar
		tar --concatenate --file root.tar install.tar

		xz < root.tar > "../$DESTPKG"
	)

	MADEPKG=true
fi

if test -d rpms
then
	find rpms -type f -name "*.rpm" | while read N
	do
		mv "$N" .
		basename "$N"
	done
fi

if $MADEPKG
then
	:
else
	(
		set -e
		cd data
		tar --owner=0 --group=0 --gzip --create --file data.tar.gz */dt
	)

	mv data/data.tar.gz cdesktopenv_"$VERSION"_"$SVNREV".tar.gz

	MADEPKG=true
fi

$MADEPKG
