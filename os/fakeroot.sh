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
# $Id: fakeroot.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
#

fakeroot_cleanup()
{
	rm -rf "$FAKEROOT"
}

fakeroot()
{
	(
		FAKEROOT=/tmp/fakeroot.bin.$$
		FAKEROOT_LOG="$FAKEROOT/fakeroot.log"

		mkdir "$FAKEROOT" 

		touch "$FAKEROOT_LOG"

		trap fakeroot_cleanup 0
	
		(
			umask 077
			for d in chgrp chown chmod
			do
				ORIGINAL=$(which $d)
				cat > "$FAKEROOT/$d" <<EOF
#!/bin/sh -e
if "$ORIGINAL" "\$@" 2>/dev/null
then
	:
else
	echo "$d" "\$@" >> "$FAKEROOT_LOG"
fi
EOF
				chmod 700 "$FAKEROOT/$d"
				ls -ld "$FAKEROOT/$d" "$ORIGINAL"
			done
		)

		FAKEROOT_LOG="$FAKEROOT_LOG" PATH="$FAKEROOT:$PATH" "$SHELL" "$@"
	)
}

fakeroot_chgrp()
{
	if test -z "$DESTDIR"
	then
		echo fakeroot_chgrp requires DESTDIR to be set to match >&2
		false
	fi

	for F in "$@"
	do
		(
			if grep "$F" < "$FAKEROOT_LOG"
			then
				:
			fi
		) | (
			while read A B C
			do
				case "$A" in
					chgrp )
						for D in $C
						do
							BASE=$(echo $D | sed "s!^$DESTDIR/!!")
							if test "$BASE" = "$F"
							then
								echo "$B"
							fi
						done
						;;
					* )
					;;
				esac
			done
		)
	done
}
