# Common Desktop Environment

The goal is to quickly get CDE up and running on a target system.

## Build Script

This script is designed to create a formal package for [CDE - Common Desktop Environment](https://sourceforge.net/projects/cdesktopenv/) for the host system. 

- No root or sudo access is required to build the packages

Before running the host system needs the requirement packages and libraries as detailed at [CDE Wiki](https://sourceforge.net/p/cdesktopenv/wiki/Home/).

- Solaris/OpenIndiana users will need a new [motif](https://github.com/rhubarb-geek-nz/motif-solaris).

The package.sh script takes a single parameter to checkout a specific tag, without arguments it will build the current [master](https://sourceforge.net/p/cdesktopenv/code/ci/master/tree/) branch.

Eg

~~~
$ ./package.sh 2.5.2
~~~

The steps it takes are:

1. confirm the locale contains de_DE, es_ES, fr_FR, and it_IT.
2. clones the repository and checks out the tag if required
3. applies a patch from [patches](patches) if one matches.
4. builds the project
5. extracts the file sets and validates what is missing
6. builds the final target image
7. calls the appropriate packager from [os](os).

The result should be a versioned package with referenced dependencies appropriate for the host system.

# Running

The script at [dtlogin-service](https://github.com/rhubarb-geek-nz/dtlogin-service) is designed to add the final dependencies and a start up script for Linux, for example with 

~~~
# systemctl enable dtlogin
# systemctl set-default graphical.target
~~~

Tested with i386,  amd64, arm32, arm64, riscv64 with Linux (Debian/Ubuntu/Centos/Fedora/openSUSE), FreeBSD, NetBSD and OpenBSD.
