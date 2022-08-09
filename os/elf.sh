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
# $Id: elf.sh 129 2021-12-31 05:33:35Z rhubarb-geek-nz $
#

if test -z "$OBJDUMP"
then
	OBJDUMP=objdump
fi

get_soname()
{
	$OBJDUMP -p "$1" 2>/dev/null | while read A B C
	do
		case "$A" in
		SONAME )
			echo "$B"
			;;
		* )
			;;
		esac
	done
}

find data -type f | while read N
do
	BN=$(basename "$N")
	case "$BN" in
		lib*.so* )
			if "$OBJDUMP" -p "$N" >/dev/null 2>&1
			then
				echo STRIP "$N"
				strip "$N"
			fi
			;;
		* )
			if test -x "$N"
			then
				if "$OBJDUMP" -p "$N" >/dev/null 2>&1
				then
					echo STRIP "$N"
					ISGRP=false
					ISUSR=false
					if test -g "$N"
					then
						ISGRP=true
					fi
					if test -u "$N"
					then
						ISUSR=true
					fi
					GRP=$(ls -ld "$N" | while read A B C D E; do echo $D; done)
					strip "$N"
					ACT=$(ls -ld "$N" | while read A B C D E; do echo $D; done)
					if test "$ACT" != "$GRP"
					then
						echo GROUP "$GRP" "$N"
						chgrp "$GRP" "$N"
					fi
					if $ISGRP
					then
						echo SETGID "$N"
						chmod g+s "$N"
					fi
					if $ISUSR
					then
						echo SETUID "$N"
						chmod u+s "$N"
					fi
				fi
			fi
			;;
	esac
done

# here want the unversioned link to point to the SONAME

find data -type l -name "lib*.so" | while read N
do
	(
		set -e
		BN=$(basename "$N")
		cd $(dirname "$N")
		RL=$(readlink "$BN")
		if test ! -h "$RL"
		then
			if test -f "$RL"
			then
				SN=$(get_soname "$RL")
				if test "$SN" != "$RL"
				then
					if test "$SN" != "$BN"
					then
						if test -h "$SN"
						then
							echo CHANGING "$BN" from "$RL" to "$SN"
							rm "$BN"
							ln -s "$SN" "$BN"
						fi
					fi
				fi
			fi
		fi
	)
done
