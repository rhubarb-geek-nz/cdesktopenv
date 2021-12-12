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
# $Id: package.sh 30 2021-01-28 17:57:11Z rhubarb-geek-nz $
#

if test 0 -eq `id -u`
then
	echo This should not need to be run as root, stay safe out there. 1>&2
	false
fi

for d in de_DE es_ES fr_FR it_IT
do
	for e in iso88591 utf8
	do
		if test -z "`locale -a  | grep $d.$e`"
		then
			echo locale $d.$e not found 1>&2
			false
		fi
	done
done

getVersion()
{
	VERSION=

	(
		cpp <<EOF
#include "cdesktopenv-code/cde/exports/include/Dt/Dt.h"
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
	(
		MACHINE=`uname -m`
		if ls /etc/ld.so.conf.d/$MACHINE-*.conf 1>&2
		then
			cat  /etc/ld.so.conf.d/$MACHINE-*.conf
		else
			cat  /etc/ld.so.conf.d/*.conf 
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

cleanup()
{
	for d in cdesktopenv-code filesets rpms rpm.spec data data.tar.* control control.tar.* debian-binary
	do
		if test -w "$d"
		then
			rm -rf "$d"
		fi
	done
}

if test -n "$1"
then
	CHECKOUT_VERSION="$1"
fi

MACHINE_ARCH=`uname -m`

MAKE_DEB=false
MAKE_RPM=true

cleanup

trap cleanup 0

if test ! -d cdesktopenv-code
then
	git clone git://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code

	(
		set -e
		cd cdesktopenv-code
		if test -n "$CHECKOUT_VERSION"
		then
			git checkout "$CHECKOUT_VERSION"
		fi
		cd cde
		make World
	)
fi

ls -ld cdesktopenv-code/cde/exports/include/Dt/Dt.h cdesktopenv-code/cde/programs/dtksh/dtksh cdesktopenv-code/cde/programs/dtdocbook/instant/instant

if test -n "$2"
then
	VERSION="$2"
else
	VERSION=`getVersion`
fi

test -n "$VERSION"

if test -z "$OBJDUMP"
then
	OBJDUMP=objdump
fi

for db in cdesktopenv-code/cde/databases/CDE-*.db
do
	set -e
	FILESET=`basename $db`
	FILESET=`echo $FILESET | sed y/./\ /`
	FILESET=`first $FILESET`

	case "$FILESET" in
		*-JP )
			echo ignoring "$FILESET" 
			;;
		* )
			mkdir -p "filesets/HP/$FILESET/data"

			cdesktopenv-code/cde/admin/IntegTools/dbTools/installCDE -s cdesktopenv-code/cde -destdir "filesets/HP/$FILESET/data" -f "$FILESET" -DontRunScripts

			MISSING=false

			if grep missing installCDE*.log 
			then
				MISSING=true
			fi

			rm -rf installCDE*.log "/tmp/$FILESET.good" "/tmp/$FILESET.err" "/tmp/$FILESET.missing" "/tmp/$FILESET.lst"

			if $MISSING
			then
				case "$FILESET" in
					CDE-HELP-DE | CDE-HELP-ES | CDE-HELP-FR | CDE-HELP-IT )
						;;
					CDE-INFOLIB-DE | CDE-INFOLIB-ES | CDE-INFOLIB-FR | CDE-INFOLIB-IT )
						;;
					* )
						false
						;;
				esac
			fi
			;;
	esac
done

for d in filesets/HP/CDE-*
do
	COUNT=`find $d -type f | wc -l`
	
	if test "$COUNT" -eq 0
	then
		echo "$d" has no files at all
		rm -rf "$d"
	fi
done

if ls -ld filesets/HP/*/data/usr/usr
then
	rmdir filesets/HP/*/data/usr/usr
fi

echo duplicate file check start

(
	set -e 
	for e in filesets/HP/*/data
	do
		(
			set -e
			cd $e
			find . -type f 
		)
	done
) | while read N
do
	set -e
	COUNT=`ls -ld filesets/HP/*/data/$N | wc -l`
	if test "$COUNT" -ne "1"
	then
		COUNT2=`ls -ld filesets/HP/CDE-*RUN/data/$N | wc -l`
		COUNT3=`echo $COUNT2+1 | bc` 
		if test "$COUNT" -eq "$COUNT3"
		then
			rm filesets/HP/CDE-*RUN/data/$N
		else
			ls -ld filesets/HP/*/data/$N
			echo $COUNT "$COUNT2" "$COUNT3" 
			false
		fi
	fi
done

echo duplicate link check start

(
	set -e 
	for e in filesets/HP/*/data
	do
		(
			set -e
			cd $e
			find . -type l
		)
	done
) | while read N
do
	set -e
	COUNT=`ls -ld filesets/HP/*/data/$N | wc -l`
	if test "$COUNT" -ne "1"
	then
		if ls -ld filesets/HP/CDE-RUN/data/$N
		then
			for d in filesets/HP/*/data/$N
			do
				case "$d" in
					filesets/HP/CDE-RUN/data/$N )
						;;
					* )
						rm "$d"
						;;
				esac
			done
		else
			ls -ld filesets/HP/*/data/$N
			false
		fi
	fi
done

echo duplicate check complete

find filesets/HP -type l | (
	set -e
	while read N
	do
		set -e
		S=`readlink $N`
		case "$S" in
			./* )
				S=`echo $S | sed "s/\.\///"`
				rm "$N"
				ln -s "$S" "$N"
				;;
			* )
				;;
		esac
	done
)

echo links complete

while read L R H M
do
	mkdir -p "filesets/HP/$R/data/etc/dt/appconfig/appmanager/$L"
	mkdir -p "filesets/HP/$R/data/etc/dt/appconfig/types/$L"
	mkdir -p "filesets/HP/$H/data/etc/dt/appconfig/help/$L"
done << EOF
de_DE.ISO8859-1	CDE-DE   CDE-HELP-DE
es_ES.ISO8859-1 CDE-ES   CDE-HELP-ES
fr_FR.ISO8859-1 CDE-FR   CDE-HELP-FR
it_IT.ISO8859-1 CDE-IT   CDE-HELP-IT
C               CDE-C    CDE-HELP-C
EOF

mkdir -p filesets/HP/CDE-ICONS/data/etc/dt/appconfig/icons/C
mkdir -p filesets/HP/CDE-RUN/data/etc/dt/config/Xsession.d
mkdir -p filesets/HP/CDE-RUN/data/var/dt/appconfig/appmanager
mkdir -p filesets/HP/CDE-RUN/data/var/dt/tmp

mkdir data

echo Setup package fileset from HP filesets

for d in filesets/HP/CDE-*
do
	set -e
	(
		set -e
		cd "$d/data"
		tar cf - .
	) | (
		set -e
		cd data
		tar xf -
	)
done

du -sk data

find data/etc data/var | xargs ls -ld

ID=`osRelease ID`
VERSION_ID=`osRelease VERSION_ID`
RELEASE="1.$ID.$VERSION_ID"

if dpkg --print-architecture
then
	DPKGARCH=`dpkg --print-architecture`
	PATHLIST="`libconf` data/usr/dt/lib"
	SIZE=`du -sk data`
	SIZE=`first $SIZE`
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

	mkdir control

	cat > control/control <<EOF
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

	while read N M
	do
		set -e
		(
			set -e
			cd "$N"
			tar --owner=0 --group=0 --xz --create --file - $M
		) > "$N".tar.xz
		ls -ld "$N".tar.xz
	done << EOF
data usr/dt var/dt etc/dt
control control
EOF

	echo 2.0 > debian-binary

	ar r cdesktopenv_"$VERSION-$RELEASE"_"$DPKGARCH".deb debian-binary control.tar.* data.tar.*
fi

if rpmbuild --version
then
	cat > rpm.spec <<EOF
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
/var/dt
/etc/dt
/usr/dt

%clean
EOF

	PWD=`pwd`
	rpmbuild --buildroot "$PWD/data" --define "_rpmdir $PWD/rpms" -bb "$PWD/rpm.spec"
fi

rm -rf data data.tar.* control control.tar.*

VERSION=1.0

if rpmbuild --version
then
	mkdir data
	mkdir -p data/lib/systemd/system
	cat > data/lib/systemd/system/dtlogin.service <<EOF
[Unit]
Description=Common Desktop Environment Login Manager
Documentation=man:dtlogin(1)
Conflicts=getty@tty1.service
Requires=rpcbind.service
After=getty@tty1.service systemd-user-sessions.service plymouth-quit.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon

[Install]
Alias=display-manager.service
EOF

	cat > rpm.spec << EOF
Summary: Common Desktop Environment Login Manager
Name: dtlogin-service
Version: $VERSION
Release: $RELEASE
Requires: dtlogin, xorg-x11-server-Xorg
BuildArch: noarch
License: LGPLv2+
Group: User Interface/X
URL: https://sourceforge.net/p/cdesktopenv/wiki/CentOSBuild/
Prefix: /lib/systemd/system

%description
CDE - The Common Desktop Environment is X Windows desktop 
environment that was commonly used on commercial UNIX variants 
such as Sun Solaris, HP-UX and IBM AIX. Developed between 1993 
and 1999, it has now been released under an Open Source 
licence by The Open Group.

%files
%defattr(-,root,root)
/lib/systemd/system/dtlogin.service

%clean
EOF

	PWD=`pwd`
	rpmbuild --buildroot "$PWD/data" --define "_rpmdir $PWD/rpms" -bb "$PWD/rpm.spec"
fi

rm -rf data control

if dpkg --print-architecture
then
	mkdir data control
	mkdir -p data/etc/X11 data/etc/systemd/system data/lib/systemd/system

	echo /usr/dt/bin/dtlogin > data/etc/X11/default-display-manager

	cat > data/lib/systemd/system/dtlogin.service << EOF
[Unit]
Description=CDE Login Manager
Requires=rpcbind.service
After=systemd-user-sessions.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon
EOF

	ln -svf /lib/systemd/system/dtlogin.service data/etc/systemd/system/display-manager.service

	ln -svf /lib/systemd/system/graphical.target data/etc/systemd/system/default.target

	SIZE=`du -sk data`
	SIZE=`first $SIZE`

	cat > control/control << EOF
Package: dtlogin-service
Version: $VERSION-$RELEASE
Architecture: all
Depends: dtlogin, rpcbind, xserver-xorg-input-libinput, xserver-xorg-video-fbdev
Section: x11
Priority: optional
Homepage: https://sourceforge.net/p/cdesktopenv/wiki/CDE%20on%20the%20Raspberry%20Pi/
Installed-Size: $SIZE
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Description: CDE Login Manager
EOF

	while read N M
	do
		set -e
		(
			set -e
			cd "$N"
			tar --owner=0 --group=0 --xz --create --file - $M
		) > "$N".tar.xz
		ls -ld "$N".tar.xz
	done << EOF
data etc/systemd/system/default.target etc/systemd/system/display-manager.service etc/X11/default-display-manager lib/systemd/system/dtlogin.service
control control
EOF

	echo 2.0 > debian-binary

	ar r dtlogin-service_"$VERSION-$RELEASE"_all.deb debian-binary control.tar.* data.tar.*
fi

if test -d rpms
then
	find rpms -type f -name "*.rpm" | while read N
	do
		mv "$N" .
		basename "$N"
	done
fi

date
echo Build Complete.
