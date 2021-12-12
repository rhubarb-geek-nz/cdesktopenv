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
# $Id: package.sh 96 2021-12-12 01:00:35Z rhubarb-geek-nz $
#

if test 0 -eq $(id -u)
then
	echo This should not need to be run as root, stay safe out there. 1>&2
	false
fi

MACHINE_ARCH="$(uname -m)"
OPSYS="$(uname -s)"

case "$OPSYS" in
	SunOS )
		for d in de es fr it
		do
			pkg info "system/osnet/locale/$d"
		done
		;;
	* )
		for d in de_DE es_ES fr_FR it_IT
		do
			MISSINGLANG=true

			for e in $( locale -a | if grep $d; then true; fi  )
			do
				case "$e" in
					$d.utf8 | $d.UTF-8 )
						MISSINGLANG=false
						;;
					* )
						;;
				esac
			done 

			if $MISSINGLANG
			then
				echo locale for $d not found 1>&2
				false
			fi
		done
		;;
esac

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
#include "cdesktopenv-code/cde/exports/include/Dt/Dt.h"
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

first()
{
	echo $1
}

cleanup()
{
	for d in cdesktopenv-code filesets rpms rpm.spec data meta
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

cleanup

trap cleanup 0

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

	(
		set -e

		cd cdesktopenv-code/cde

		make World
	)
fi

ls -ld cdesktopenv-code/cde/exports/include/Dt/Dt.h cdesktopenv-code/cde/programs/dtksh/dtksh cdesktopenv-code/cde/programs/dtdocbook/instant/instant

GITREV=$(cd cdesktopenv-code ; git rev-parse HEAD)
GITHASH=$(echo $GITREV | dd bs=8 count=1 2>/dev/null )

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
		svn log -q "$d" > /dev/null

		SVNREV=$( echo $SVNREV + $( svn log -q "$d" | grep -v "\-----------" | wc -l) | bc)
	fi
done

echo VERSION=$VERSION SVNREV=$SVNREV

test -n "$VERSION"

for db in cdesktopenv-code/cde/databases/CDE-*.db
do
	set -e
	FILESET=$(basename $db)
	FILESET=$(echo $FILESET | sed y/./\ /)
	FILESET=$(first $FILESET)

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
	COUNT=$(find $d -type f | wc -l)
	
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
	COUNT=$(ls -ld filesets/HP/*/data/$N | wc -l)
	if test "$COUNT" -ne "1"
	then
		COUNT2=$(ls -ld filesets/HP/CDE-*RUN/data/$N | wc -l)
		COUNT3=$(echo $COUNT2+1 | bc)
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
	COUNT=$(ls -ld filesets/HP/*/data/$N | wc -l)
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
			if ls -ld filesets/HP/CDE-MAN/data/$N
			then
				for d in filesets/HP/*/data/$N
				do
					case "$d" in
						filesets/HP/CDE-MAN/data/$N )
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
	fi
done

echo duplicate check complete

find filesets/HP -type l | (
	set -e
	while read N
	do
		set -e
		S=$(readlink $N)
		case "$S" in
			./* )
				S=$(echo $S | sed "s/\.\///")
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

if test -x "os/$(uname).sh"
then
	"os/$(uname).sh" "$VERSION" "$SVNREV"
else
	TARNAME="cdesktopenv"_"$VERSION"

	if test "$SVNREV" -gt 0
	then
		TARNAME="$TARNAME"_"$SVNREV"
	fi

	TARNAME="$TARNAME".tar

	(
		set -e
		cd data
		tar cf "$TARNAME" */dt
	)

	mv "data/$TARNAME" .
	ls -ld "$TARNAME"
fi
