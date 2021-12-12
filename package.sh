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
# $Id: package.sh 17 2021-01-17 15:56:51Z rhubarb-geek-nz $
#

description()
{
	while read A B
	do
		if test "$A" = "$1"
		then
			echo "$B"
			break 
		fi
	done << EOF
CDE-C           		CDE runtime
CDE-DE          		CDE German runtime
CDE-ES          		CDE Spanish runtime
CDE-FR          		CDE French runtime
CDE-IT          		CDE Italian runtime
CDE-JP          		CDE Japanese runtime
CDE-FONTS       		CDE fonts
CDE-DEMOS       		CDE developer environment
CDE-HELP-C      		CDE help
CDE-HELP-DE     		CDE German help
CDE-HELP-ES     		CDE Spanish help
CDE-HELP-FR     		CDE French help
CDE-HELP-IT     		CDE Italian help
CDE-HELP-JP     		CDE Japanese help
CDE-HELP-PRG    		CDE help developers\' kit 
CDE-HELP-RUN    		CDE help runtime
CDE-ICONS       		CDE icon files
CDE-INC         		CDE Dev. Env include files
CDE-INFO        		CDE public DTD and SGML data
CDE-INFOLIB-C   		CDE InfoLibs
CDE-INFOLIB-DE  		CDE German InfoLibs
CDE-INFOLIB-ES  		CDE Spanish InfoLibs
CDE-INFOLIB-FR  		CDE French InfoLibs
CDE-INFOLIB-IT  		CDE Italian InfoLibs
CDE-INFOLIB-JP  		CDE Japanese InfoLibs
CDE-MAN         		CDE man pages
CDE-MAN-DEV         	CDE developer man pages
CDE-MIN         		CDE minimum runtime
CDE-MSG-C       		CDE message files
CDE-MSG-DE      		CDE German message files
CDE-MSG-ES      		CDE Spanish message files
CDE-MSG-FR      		CDE French message files
CDE-MSG-IT      		CDE Italian message files
CDE-MSG-JP      		CDE Japanese message files
CDE-PRG         		CDE Dev. Env library
CDE-RUN         		CDE runtime
CDE-SHLIBS      		CDE shared libraries
CDE-TT          		CDE Tooltalk
X11.Dt       		   	Common Desktop Environment
X11.Dt.ToolTalk 		CDE ToolTalk Support
X11.Dt.adt				CDE Application Developers\' Toolkit
X11.Dt.bitmaps  		CDE Bitmaps
X11.Dt.compat   		CDE Compatibility
X11.Dt.helpinfo 		CDE Help Files and Volumes
X11.Dt.helpinfo.de_DE 	CDE German Help Files and Volumes
X11.Dt.helpinfo.es_ES 	CDE Spanish Help Files and Volumes
X11.Dt.helpinfo.fr_FR 	CDE French Help Files and Volumes
X11.Dt.helpinfo.it_IT 	CDE Italian Help Files and Volumes
X11.Dt.helpmin  		CDE Minimum Help Files
X11.Dt.helpmin.de_DE  	CDE German Minimum Help Files
X11.Dt.helpmin.es_ES  	CDE Spanish Minimum Help Files
X11.Dt.helpmin.fr_FR  	CDE French Minimum Help Files
X11.Dt.helpmin.it_IT  	CDE Italian Minimum Help Files
X11.Dt.helprun        	CDE Runtime Help
X11.Dt.lib	    		CDE Runtime Libraries
X11.Dt.rte	   			Common Desktop Environment
dtlogin-service			CDE login service
EOF
}

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

if test -n "$1"
then
	VERSION="$1"
else
	VERSION="2.3.2"
fi

MACHINE_ARCH=`uname -m`

cleanup()
{
	rm -rf cdesktopenv-code filesets
}

cleanup

trap cleanup 0

git clone git://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code

(
	set -e
	cd cdesktopenv-code
	if test -n "$VERSION"
	then
		git checkout "$VERSION"
	fi
	cd cde
	case "$MACHINE_ARCH" in
		aarch64 )
			patch -p0 <<'EOF'
--- programs/dtksh/ksh93/src/lib/libast/sfio/sfvprintf.c	2021-01-14 17:13:54.191401167 +0000
+++ programs/dtksh/ksh93/src/lib/libast/sfio/sfvprintf.c	2021-01-14 17:19:54.178126980 +0000
@@ -92,10 +92,10 @@
 	}
 #define GETARGL(elt,arge,argf,args,etype,type,fmt,t_user,n_user) \
 	{ if(!argf) \
-		__va_copy( elt, va_arg(args,type) ); \
+		__va_copy( elt[0], va_arg(args,type)[0] ); \
 	  else if((*argf)(fmt,(char*)(&arge),t_user,n_user) < 0) \
 		goto pop_fa; \
-	  else	__va_copy( elt, arge ); \
+	  else	__va_copy( elt[0], arge[0] ); \
 	}
 
 #if __STD_C
@@ -309,7 +309,7 @@
 #else
 			GETARGL(argsp,argsp,argf,args,va_list*,va_list*,'2',t_user,n_user);
 			__va_copy( fa->args, args );
-			__va_copy( args, argsp );
+			__va_copy( args, argsp[0] );
 #endif
 			fa->argf.p = argf;
 			fa->extf.p = extf;
EOF
			;;
		* )
			;;
	esac

	make World
)

ls -ld cdesktopenv-code/cde/exports/include/Dt/Dt.h cdesktopenv-code/cde/programs/dtksh/dtksh

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

echo packaging for $VERSION on $DPKGARCH

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
			rm -rf installCDE*.log "/tmp/$FILESET.good" "/tmp/$FILESET.err" "/tmp/$FILESET.missing" "/tmp/$FILESET.lst"
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

mkdir -p filesets/HP/dtlogin-service/data

(
	set -e
	cd filesets/HP/dtlogin-service/data
	mkdir -p etc/systemd/system lib/systemd/system etc/X11
	ln -s /lib/systemd/system/graphical.target etc/systemd/system/default.target
	ln -s /lib/systemd/system/dtlogin.service etc/systemd/system/display-manager.service
	echo /usr/dt/bin/dtlogin > etc/X11/default-display-manager	
	cat > lib/systemd/system/dtlogin.service  << EOF
[Unit]
Description=CDE Login Manager
Requires=rpcbind.service
After=systemd-user-sessions.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon
EOF
)

echo Setup IBM filesets from HP filesets

mkdir filesets/IBM

while read N M
do
	set -e
	echo $N
	mkdir filesets/IBM/$N

	for d in $M
	do
		(
			set -e
			cd filesets/HP/$d
			tar cf - data
		) | (
			set -e
			cd filesets/IBM/$N
			tar xf - 
		)
	done
done <<EOF
X11.Dt.rte CDE-MAN CDE-MIN CDE-RUN CDE-C
X11.Dt.lib CDE-SHLIBS
X11.Dt.adt CDE-INC CDE-DEMOS CDE-HELP-PRG CDE-MAN-DEV
X11.Dt.bitmaps CDE-ICONS
X11.Dt.ToolTalk CDE-TT
X11.Dt.helprun CDE-HELP-RUN CDE-HELP-C
X11.Dt.helpmin CDE-MSG-C CDE-FONTS
X11.Dt.helpinfo CDE-INFOLIB-C CDE-INFO
X11.Dt.helpinfo.de_DE CDE-HELP-DE
X11.Dt.helpinfo.es_ES CDE-HELP-ES
X11.Dt.helpinfo.fr_FR CDE-HELP-FR
X11.Dt.helpinfo.it_IT CDE-HELP-IT
X11.Dt.helpmin.de_DE CDE-MSG-DE CDE-DE
X11.Dt.helpmin.es_ES CDE-MSG-ES CDE-ES
X11.Dt.helpmin.fr_FR CDE-MSG-FR CDE-FR
X11.Dt.helpmin.it_IT CDE-MSG-IT CDE-IT
dtlogin-service dtlogin-service
EOF

mkdir -p filesets/HP/CDE-DESKTOP/data  filesets/IBM/X11.Dt/data

echo duplicate check confirm

for d in filesets/*
do
	set -e
	(
		set -e 
		for e in $d/*/data
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
		COUNT=`ls -ld $d/*/data/$N | wc -l`
		if test "$COUNT" -ne "1"
		then
			ls -ld $d/*/data/$N
		fi
	done
done

echo duplicate check complete

(
	set -e
	for d in filesets/*
	do
		(
			set -e
			cd $d
			du -sk * | while read A B C
			do
				echo "$A" > "$B/size"
				echo "$B" | sed "s/de_DE/de/" | sed "s/es_ES/es/" | sed "s/fr_FR/fr/" | sed "s/it_IT/it/" | tr '[:upper:]' '[:lower:]' | sed "y/\./-/" | sed "y/_/-/" > "$B/name"
			done
		)
	done
)

# use filesets/* to build both filesets/HP and filesets/IBM

for fileset in filesets/IBM
do
	set -e
	PATHLIST="`libconf` $fileset/CDE-SHLIBS/data/usr/dt/lib $fileset/X11.Dt.lib/data/usr/dt/lib"

	for PKGROOT in $fileset/*
	do
		PROVIDES=
		LIBLIST=
		PKGVER="$VERSION"
		PKGLIST=
		PKGNAME=`cat $PKGROOT/name`
		SIZE=`cat $PKGROOT/size`
		CDENAME=`basename $PKGROOT`

		if test -x $PKGROOT/data/usr/dt
		then
			for d in `find $PKGROOT/data/usr/dt -type f`
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
				$fileset/CDE-SHLIBS/data/usr/dt/lib/* )
					DEPPKG=cde-shlibs
					if test "$PKGNAME" != "$DEPPKG"
					then
						if not_member "$DEPPKG" $PKGLIST
						then
							PKGLIST="$PKGLIST $DEPPKG"
						fi
					fi
					;;
				$fileset/X11.Dt.lib/data/usr/dt/lib/* )
					DEPPKG=x11-dt-lib
					if test "$PKGNAME" != "$DEPPKG"
					then
						if not_member "$DEPPKG" $PKGLIST
						then
							PKGLIST="$PKGLIST $DEPPKG"
						fi
					fi
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

		if test -x $PKGROOT/data/usr/dt/bin/dtlogin
		then
			PROVIDES=dtlogin

			for d in rpcbind tcl ksh x11-xserver-utils xfonts-100dpi xfonts-100dpi-transcoded xfonts-75dpi xfonts-75dpi-transcoded
			do
				if not_member "$d" $PKGLIST
				then
					PKGLIST="$PKGLIST $d"
				fi
			done
		fi

		if test -d $PKGROOT/data/usr/dt
		then
			PACKARCH=$DPKGARCH
		else
			PACKARCH=all

			if test -d $PKGROOT/data/etc/X11
			then
				PKGVER=1.0
				for x in rpcbind dtlogin xserver-xorg-input-libinput xserver-xorg-video-fbdev
				do
					if not_member "$x" $PKGLIST
					then
						PKGLIST="$PKGLIST $x"
					fi						
				done
			else
				for x in `cat $fileset/*/name`
				do
					if not_member "$x" $PKGLIST dtlogin-service $PKGNAME
					then
						PKGLIST="$PKGLIST $x"
					fi						
				done
			fi
		fi

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

		mkdir $PKGROOT/control

		DESC=`description $CDENAME`
	
		if test -z "$DESC"
		then
			DESC="Common Desktop Environment"
		fi

		(
			cat  <<EOF
Package: $PKGNAME
Version: $PKGVER
Architecture: $PACKARCH
Maintainer: rhubarb-geek-nz@users.sourceforge.net
EOF

			if test -n "$DEPENDS"
			then
				cat <<EOF
Depends: $DEPENDS
EOF
			fi

			if test -n "$PROVIDES"
			then
				cat <<EOF
Provides: $PROVIDES
EOF
			fi

			cat <<EOF
Section: x11
Priority: optional
Homepage: https://sourceforge.net/projects/cdesktopenv/
Installed-Size: $SIZE
Description: $DESC
EOF
		) > $PKGROOT/control/control

	
		case "$PKGNAME" in
			cde-run | x11-dt-rte )
				cat >$PKGROOT/control/postinst <<EOF
#!/bin/sh -e
mkdir -p /var/spool/calendar
EOF

				cat >$PKGROOT/control/postrm <<EOF
#!/bin/sh -e
case "\$1" in
	remove | purge )
		rm -rf /var/dt/*
		;;
	* )
		;;
esac
EOF
				chmod +x $PKGROOT/control/postinst $PKGROOT/control/postrm
				;;
			* )
				;;
		esac

		(
			set -e
			cd $PKGROOT
			echo "2.0" >debian-binary

			for e in control data
			do
				(
					set -e
					cd $e
					tar --owner=0 --group=0 --create --xz --file ../$e.tar.xz .
				)
			done

			ar r "$PKGNAME"_"$PKGVER"_"$PACKARCH".deb debian-binary control.tar.* data.tar.*
		)
	done

	(
		BASE=`basename $fileset`
		case "$BASE" in
			IBM )
				BASE=x11-dt
				;;
			HP )
				BASE=cde-desktop
				;;
			* )
				;;
		esac
		cd $fileset
		mv */*.deb .
		tar --owner=0 --group=0 --create --file ../../"$BASE"_"$VERSION"_"$DPKGARCH".deb.tar *.deb 
		rm *.deb
	)
done

date
echo Build Complete.
