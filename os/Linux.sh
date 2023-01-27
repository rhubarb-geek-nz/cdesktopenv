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
# $Id: Linux.sh 225 2023-01-27 06:36:11Z rhubarb-geek-nz $
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

isELF()
{
	test " 177 105 114 106" = "$(od -b -N4 -An < $1)"
}

get_needed()
{
	if isELF "$1"
	then
		"$OBJDUMP" -p "$1" 2>/dev/null | while read A B C
		do
			case "$A" in
			NEEDED )
				echo "$B"
				;;
			* )
				;;
			esac
		done
	fi
}

get_soname()
{
	if isELF "$1"
	then
		"$OBJDUMP" -p "$1" 2>/dev/null | while read A B C
		do
			case "$A" in
			SONAME )
				echo "$B"
				;;
			* )
				;;
			esac
		done
	fi
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
	for d in rpms rpm.spec data-dev
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
MAKETAR=false
MAKEINSTALLER=false

SVNREV=$(echo 1+$SVNREV | bc)

for d in $(osLike)
do
	case "$d" in
		debian | ubuntu )
			MAKEDEB=true
			;;
		rhel | centos | fedora | suse | opensuse | mariner )
			MAKERPM=true
			;;
		slackware )
			MAKESLACK=true
			;;
		gentoo )
			MAKEINSTALLER=true
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

	if $MAKEINSTALLER
	then
		break
	fi
done

if $MAKEDEB || $MAKERPM || $MAKESLACK || $MAKEINSTALLER
then
	:
else
	MAKETAR=true
fi

cleanup

trap cleanup 0

if test -z "$OBJDUMP"
then
	OBJDUMP=objdump
fi

test -d data

os/elf.sh

(
	cd data

	for N in * */*
	do
		case "$N" in
			usr | usr/dt | var | var/dt | etc | etc/dt | etc/pam.d )
				;;
			* )
				echo DELETING "$N"
				rm -rf "$N"
				;;
		esac
	done
)

if $MAKEDEB || $MAKERPM
then
	if test ! -h data/usr/dt/include && test -d data/usr/dt/include
	then
		mkdir -p data-dev/usr/dt/lib

		mv data/usr/dt/include data-dev/usr/dt/include
	fi

	(
		cd data
		find usr/dt/lib -type l -name "lib*.so"
	) | (
		while read N
		do
			DN=$(dirname "$N")
			mkdir -p "data-dev/$DN"
			mv "data/$N" "data-dev/$DN/"
		done
	)

	(
		cd data
		find usr/dt/lib -type f -name "lib*.a"
	) | (
		while read N
		do
			DN=$(dirname "$N")
			mkdir -p "data-dev/$DN"
			mv "data/$N" "data-dev/$DN/"
		done
	)

	(
		cd data
		find usr/dt/lib -type f -name "lib*.la"
	) | (
		while read N
		do
			DN=$(dirname "$N")
			mkdir -p "data-dev/$DN"
			mv "data/$N" "data-dev/$DN/"
		done
	)

	if test -d data/usr/dt/share/man/man3
	then
		mkdir -p data-dev/usr/dt/share/man
		mv data/usr/dt/share/man/man3 data-dev/usr/dt/share/man
	fi

	if test -d data/usr/dt/share/examples
	then
		mkdir -p data-dev/usr/dt/share
		mv data/usr/dt/share/examples data-dev/usr/dt/share
	fi

	if test -h data/usr/dt/examples
	then
		mkdir -p data-dev/usr/dt
		mv data/usr/dt/examples data-dev/usr/dt
	fi

	if test -d data-dev
	then
		find data-dev -type f | xargs chmod -w
	fi
fi

find data -type f | xargs chmod -w

SIZE=$(du -sk data)
SIZE=$(first $SIZE)

. os/fakeroot.sh

if $MAKEDEB || $MAKESLACK || $MAKETAR
then
	(
		cd data
		mkdir chgrp

		DESTDIR=$(pwd)

		while read A B C
		do
			case "$A" in
				chgrp )
					echo MUST CHANGE GROUP $B FOR $C
					for D in $C
					do
						BASE=$(echo $D | sed "s!^$DESTDIR/!!")
						echo NOW $C BECOMES $BASE
						GRPDIR=$(dirname "$BASE")
						mkdir -p "chgrp/$B/$GRPDIR"
						mv "$BASE" "chgrp/$B/$GRPDIR"
					done
					;;
				chown )
					case "$B" in
						root | root:root )
							;;
						* )
							echo FAKEROOT LOG $A $B $C
							false
							;;
					esac
					;;
				* )
					echo FAKEROOT LOG $A $B $C
					false
					;;
			esac
		done < "$FAKEROOT_LOG"

		find chgrp -type f | xargs ls -ld

		DATADIRS=

		for d in */dt
		do
			if test -d "$d"
			then
				DATADIRS="$DATADIRS $d"
			fi
		done

		if test -d etc/pam.d
		then
			DATADIRS="$DATADIRS $(find etc/pam.d -type f)"
			DATADIRS="$DATADIRS $(find etc/pam.d -type l)"
		fi

		tar --owner=0 --group=0 --create --file data.tar $( ( for d in $DATADIRS; do echo $d; done ) | sort )

		for d in $(ls chgrp)
		do
			echo HANDLE GROUP $d

			(
				set -e
				cd "chgrp/$d"
				tar --owner=0 --group=$d --create --file ../../chgrp.tar $(find * -type f)
			)

			tar --concatenate --file data.tar chgrp.tar

			rm chgrp.tar
		done
	)
fi

ID=$(osRelease ID | sed "y/-/./")
VERSION_ID=$(osRelease VERSION_ID)
RELEASE="$SVNREV"

if $MAKEDEB
then
	dpkg --print-architecture
	DPKGARCH=$(dpkg --print-architecture)
	PATHLIST="$(libconf) data/usr/dt/lib"
	PKGLIST="rpcbind tcl ksh x11-xserver-utils xfonts-100dpi xfonts-100dpi-transcoded xfonts-75dpi xfonts-75dpi-transcoded"
	LIBLIST=
	DEPENDS=

	if test -x data/usr/dt
	then
		for d in $(find data/usr/dt -type f -executable)
		do
			if isELF "$d"
			then
				for e in $(get_needed "$d")
				do
					for f in $(findlib "$e")
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
					DEPPKG=$(dpkg -S "$d")
					DEPPKG=$(echo "$DEPPKG" | sed "y/:/ /")
					DEPPKG=$(first $DEPPKG)
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

	mkdir -p data/DEBIAN

	if test -z "$MAINTAINER"
	then
		if git config user.email > /dev/null
		then
			MAINTAINER="$(git config user.email)"
		else
			MAINTAINER="$(id -un)@$(hostname)"
		fi
	fi

	cat > data/DEBIAN/control <<EOF
Package: cdesktopenv
Version: $VERSION-$RELEASE
Architecture: $DPKGARCH
Depends: $DEPENDS
Provides: dtlogin
Section: x11
Priority: optional
Homepage: https://sourceforge.net/projects/cdesktopenv/
Installed-Size: $SIZE
Maintainer: $MAINTAINER
Description: CDE - Common Desktop Environment
EOF

	(
		cd data

		tar --owner=0 --group=0 --create --xz --file control.tar.xz -C DEBIAN control

		xz data.tar

		echo "2.0" > debian-binary

		ar r cdesktopenv_"$VERSION-$RELEASE"_"$DPKGARCH".deb debian-binary control.tar.xz data.tar.xz

		mv cdesktopenv_"$VERSION-$RELEASE"_"$DPKGARCH".deb ..
	)

	dpkg-deb -c cdesktopenv_"$VERSION-$RELEASE"_"$DPKGARCH".deb | grep "etc/pam.d/dt
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm"

SIZE=$(du -sk data-dev)
SIZE=$(first $SIZE)

	mkdir data-dev/DEBIAN

	cat > data-dev/DEBIAN/control <<EOF
Package: cdesktopenv-dev
Version: $VERSION-$RELEASE
Architecture: $DPKGARCH
Depends: cdesktopenv (= $VERSION-$RELEASE), libmotif-dev 
Section: x11
Priority: optional
Homepage: https://sourceforge.net/projects/cdesktopenv/
Installed-Size: $SIZE
Maintainer: $MAINTAINER
Description: CDE - development files
EOF

	(
		cd data-dev

		tar --owner=0 --group=0 --create --xz --file control.tar.xz -C DEBIAN control
		
		tar --owner=0 --group=0 --create --xz --file data.tar.xz \
			usr/dt/include \
			$(find usr/dt -type l) \
			$(find usr/dt/lib -type f) \
			usr/dt/share/man/man3 \
			$(if test -d usr/dt/share/examples; then echo usr/dt/share/examples ; fi )

		echo "2.0" > debian-binary

		ar r cdesktopenv-dev_"$VERSION-$RELEASE"_"$DPKGARCH".deb debian-binary control.tar.xz data.tar.xz

		mv cdesktopenv-dev_"$VERSION-$RELEASE"_"$DPKGARCH".deb ..
	)

	dpkg-deb -c cdesktopenv-dev_"$VERSION-$RELEASE"_"$DPKGARCH".deb | grep "Dt/Dt.h
lib/libDtTerm.so"

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
EOF

		DESTDIR=$(pwd)

		if test -d etc/pam.d
		then
			find etc/pam.d | while read N
			do
				if test -h "$N"
				then
					echo "/$N"
				else
					if test -f "$N"
					then
						U="root"
						G="root"
						echo "%attr(-,$U,$G) /$N"
					fi
				fi
			done
		fi

		find */dt | while read N
		do
			if test -h "$N"
			then
				echo "/$N"
			else
				if test -d "$N"
				then
					echo "%dir %attr(555,-,-) /$N"
				else
					U="root"
					G=$(fakeroot_chgrp $N)
					if test -z "$G"
					then
						G="root"
					fi
					echo "%attr(-,$U,$G) /$N"
				fi
			fi
		done

		cat <<EOF

%clean
EOF
	) > rpm.spec

	cp rpm.spec log/rpm.spec

	PWD=$(pwd)
	rpmbuild --buildroot "$PWD/data" --define "_rpmdir $PWD/rpms" --define "_build_id_links none" -bb "$PWD/rpm.spec"

	(
		cd data-dev

		cat <<EOF
Summary: CDE - Common Desktop Environment development
Name: cdesktopenv-devel
Version: $VERSION
Release: $SVNREV
Requires: cdesktopenv = $VERSION motif-devel 
License: LGPLv2+
Group: User Interface/X
URL: https://sourceforge.net/projects/cdesktopenv/
Prefix: /

%description
This is the CDE $VERSION development environment. It includes the
header files and also static libraries necessary to build CDE applications.

%files
EOF

		DESTDIR=$(pwd)

		find */dt/include */dt/share/man */dt/share/examples | while read N
		do
			if test -d "$N"
			then
				echo "%dir %attr(555,-,-) /$N"
			fi
		done

		find */dt | while read N
		do
			if test -h "$N"
			then
				echo "/$N"
			else
				if test -f "$N"
				then
					echo "%attr(444,root,root) /$N"
				fi
			fi
		done

		cat <<EOF

%clean
EOF
	) > rpm.spec

	cp rpm.spec log/rpm.spec.devel

	PWD=$(pwd)
	rpmbuild --buildroot "$PWD/data-dev" --define "_rpmdir $PWD/rpms" --define "_build_id_links none" -bb "$PWD/rpm.spec"

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

	mkdir data/install data/root

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

	(
		set -e
		cd data

		(
			find */dt -type l | sort | while read N
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

		tar --owner=0 --group=0 --create --file install.tar install
	
		(
			cd root
			tar --owner=0 --group=0 --create --file ../root.tar .
		)

		tar --concatenate --file root.tar data.tar

		echo ADD INSTALL

		tar --concatenate --file root.tar install.tar

		echo COMPRESSING

		xz < root.tar > "../$DESTPKG"
	)

	tar tvfJ "$DESTPKG" | grep "\./
etc/pam.d/dt
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm
install/slack-desc
install/doinst.sh"

	MADEPKG=true
fi

if $MAKETAR
then

	MACHINE=$(uname -m)

	ls -ld data/data.tar

	DESTPKG="cdesktopenv"_"$VERSION-$RELEASE"_"$MACHINE.tar.gz"

	gzip < "data/data.tar" > "$DESTPKG"

	tar tvfz "$DESTPKG" | grep "etc/pam.d/dt
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm"

	MADEPKG=true
fi


if $MAKEINSTALLER
then
	DESTARCH=$(arch)
	SVNREV=$(echo $SVNREV-1 | bc)
	DESTNAME="cdesktopenv-$VERSION"
	if test "$SVNREV" -gt 0
	then
		DESTFILE="$DESTNAME-r$SVNREV-$DESTARCH.tar.gz"
	else
		DESTFILE="$DESTNAME-$DESTARCH.tar.gz"
	fi

	(
		set -e
		cd data
		DESTDIR=$(pwd)
		echo "all:"
		while read A B C
		do
			case "$A" in
				chgrp )
					echo "$B"
					;;
				chown )
					case "$B" in
						root | root:root )
							;;
						* )
							false
							;;
					esac
					;;
				* )
					false
					;;
			esac
		done < "$FAKEROOT_LOG" | sort -u | while read GRP
		do
			echo "	getent group \"$GRP\""
		done

		echo
		echo "clean:"
		echo
		echo "install:"
		find */* -type d | sort | while read N
		do
			echo "	install -d \"\$(DESTDIR)/$N\""
		done
		find * -type f | sort | while read N
		do
			ATTR=$(stat "--format=%a" "$N")
			DIRNAME=$(dirname "$N")
			G=$(fakeroot_chgrp $N)
			if test -z "$G"
			then
				G="root"
			fi
			case "$G" in
				root )
					echo "	install --mode=0$ATTR \"$N\" \"\$(DESTDIR)/$DIRNAME\""
					;;
				* )
					echo "	install --mode=0$ATTR --group=\"$G\" \"$N\" \"\$(DESTDIR)/$DIRNAME\""
					;;
			esac
		done		
		find * -type l | sort | while read N
		do
			LINKVAL=$(readlink "$N")
			echo "	ln -s \"$LINKVAL\" \"\$(DESTDIR)/$N\""
		done		
		find * -type l | xargs rm		
	) > rpm.spec

	mv rpm.spec data/Makefile

	chmod -w data/Makefile

	mv data "$DESTNAME"

	tar --create --gzip --owner=0 --group=0 --file "$DESTFILE" "$DESTNAME"

	rm -rf "$DESTNAME"

	MADEPKG=true
fi

if test -d rpms
then
	find rpms -type f -name "*.rpm" | while read N
	do
		mv "$N" .
		basename "$N"

		rpm -qlvp $(basename "$N") | grep "etc/pam.d/dt
bin/dtappgather
bin/dtmail
bin/dtsession
bin/dtterm
include/Dt/Dt.h
lib/libDtTerm.so"
	done
fi

$MADEPKG
