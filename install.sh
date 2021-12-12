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
# $Id: install.sh 10 2021-01-11 21:09:06Z rhubarb-geek-nz $
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
