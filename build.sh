#!/usr/bin/env bash
#
# Public Domain
#
# new script to build gregorio binaries (inspired from LuaTeX's one).
# ----------
# Options:
#      --mingw     : crosscompile for mingw32 from i-386linux
#      --warn      : enables all sorts of warnings
#      --static    : compiles one binary containing everything
#      --host=     : target system for mingw32 cross-compilation
#      --build=    : build system for mingw32 cross-compilation
#      --arch=     : crosscompile for ARCH on OS X
      
# try to find bash, in case the standard shell is not capable of
# handling the generated configure's += variable assignments
if which bash >/dev/null
then
 CONFIG_SHELL=`which bash`
 export CONFIG_SHELL
fi

WARNINGS=yes
MINGWCROSS=FALSE
CONFHOST=
CONFBUILD=
MACCROSS=FALSE

CFLAGS="$CFLAGS -Wdeclaration-after-statement"

until [ -z "$1" ]; do
  case "$1" in
    --mingw     ) MINGWCROSS=TRUE    ;;
    --static    ) STATIC=TRUE    ;;
    --warn      ) WARN=TRUE    ;;
    --host=*    ) CONFHOST="$1"      ;;
    --build=*   ) CONFBUILD="$1"     ;;
    --arch=*    ) MACCROSS=TRUE; ARCH=`echo $1 | sed 's/--arch=\(.*\)/\1/' ` ;;
    *           ) echo "ERROR: invalid build.sh parameter: $1"; exit 1       ;;
  esac
  shift
done

STATICFLAGS=

if [ "$STATIC" = "TRUE" ]
then
  STATICFLAGS="--enable-static-ltdl --disable-shared --enable-all-static"
fi

B=build

ARCHFLAGS=

if [ "$WARN" = "TRUE" ]
then
  CFLAGS="-Wall -Wextra \
 -Wformat-y2k -Wno-format-extra-args\
 -Wno-format-zero-length -Wformat-nonliteral\
 -Wformat-security -Wformat=2 -Wnormalized=nfc $CFLAGS"
fi

if [ "$MINGWCROSS" = "TRUE" ]
then
  MINGWBUILD=$HOSTTYPE-$OSTYPE
  MINGWSTR=mingw32
  if [ -d /usr/mingw32 ]; then
    MINGWSTR=mingw32
  else
    if [ -d /usr/i386-mingw32msvc ]; then
      MINGWSTR=i386-mingw32msvc
    else
      if [ -d /usr/i586-mingw32msvc ]; then
        MINGWSTR=i586-mingw32msvc
      fi
    fi
  fi
  OLDPATH=$PATH
  PATH=/usr/$MINGWSTR/bin:$PATH
  CFLAGS="-mtune=pentiumpro -msse2 -O2 $CFLAGS"
  STATICFLAGS="--enable-static-ltdl --disable-shared --enable-all-static"
  LDFLAGS="-Wl,--large-address-aware $CFLAGS"
  ARCHFLAGS="--target=\"$MINGWSTR\" \
    --with-gnu-ld \
    --disable-nls \
    --host=$MINGWSTR \
    --build=$MINGWBUILD \
    --prefix=/usr/$MINGWSTR"
else
ARCHFLAGS="--enable-xml-read"
if [ "$MACCROSS" = "TRUE" ]
then
  # make sure that architecture parameter is valid
  case $ARCH in
    i386 | x86_64 | ppc | ppc64 ) ;;
    * ) echo "ERROR: architecture $ARCH is not supported"; exit 1;;
  esac
  ARCHFLAGS="$ARCHFLAGS --enable-static-ltdl"
  CFLAGS="-arch $ARCH -g -O2 $CFLAGS"
  LDFLAGS="-arch $ARCH $LDFLAGS" 
fi  
fi


export CFLAGS LDFLAGS

./configure  $CONFHOST $CONFBUILD $STATICFLAGS $ARCHFLAGS

make

if [ "$MINGWCROSS" = "TRUE" ]
then
  PATH=$OLDPATH
fi

