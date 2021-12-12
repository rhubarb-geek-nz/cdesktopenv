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
# $Id: install.sh 12 2021-01-14 23:36:51Z rhubarb-geek-nz $
#

if test -n "$1"
then
	VERSION="$1"
else
	VERSION=2.3.2
fi

cleanup()
{
	rm -rf cdesktopenv-code
}

cleanup

rm -f installCDE.*.log

trap cleanup 0

git clone git://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code

(
	set -e
	cd cdesktopenv-code
	git checkout "$VERSION"
	cd cde
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
	make World
)

CDESRC=`pwd`/cdesktopenv-code/cde

sudo "$CDESRC/admin/IntegTools/dbTools/installCDE" -s "$CDESRC"

ls -ld installCDE.*.log

if grep "missing files:" installCDE.*.log
then
	echo Missing files, see installCDE.*.log 1>&2
	false
else
	rm -f installCDE.*.log
fi
