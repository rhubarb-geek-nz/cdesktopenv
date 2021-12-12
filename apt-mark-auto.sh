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
# $Id: apt-mark-auto.sh 10 2021-01-11 21:09:06Z rhubarb-geek-nz $
#

relax()
{
	case "$1" in
	x11-dt* )
		apt show "$1" 2>/dev/null | while read N M O
		do
			case "$N" in
				APT-Manual-Installed: )
					if test "$M" = "yes"
					then
						sudo apt-mark auto "$1"
					fi				
					;;
				* )
					;;
			esac
		done

		apt-cache depends "$1" | while read N M O
		do
			case "$N" in 
			Depends: )
				relax "$M"
				;;
			* )
				;;
			esac
		done
		;;
	* )
		;;
	esac
}

apt-cache depends "dtlogin-service" | grep Depends | while read N M O
do
	case "$N" in 
		Depends: )
			relax "$M"
			;;
		* )
			;;
	esac
done
