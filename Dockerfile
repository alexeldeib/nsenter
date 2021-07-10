FROM debian:buster as builder

RUN apt-get update && apt-get install -yq make wget git rsync gcc gettext autopoint bison libtool automake pkg-config gperf texinfo patch

WORKDIR /code

# download util-linux sources
ARG UTIL_LINUX_VER=2.37
ADD https://github.com/karelzak/util-linux/archive/v${UTIL_LINUX_VER}.tar.gz .
RUN tar -xf v${UTIL_LINUX_VER}.tar.gz && mv util-linux-${UTIL_LINUX_VER} util-linux

# make static version
WORKDIR /code/util-linux
RUN ./autogen.sh && ./configure
RUN make LDFLAGS="--static" nsenter

# download coreutils sources
ARG COREUTILS_VER=8.32
RUN git clone https://github.com/coreutils/coreutils /code/coreutils
WORKDIR /code/coreutils
RUN git checkout v${COREUTILS_VER}

# make static version
RUN ./bootstrap
RUN FORCE_UNSAFE_CONFIGURE=1 ./configure
RUN cp /usr/lib/gcc/x86_64-linux-gnu/8/crtbeginT.o /usr/lib/gcc/x86_64-linux-gnu/8/crtbeginT.orig.o
RUN cp /usr/lib/gcc/x86_64-linux-gnu/8/crtbeginS.o /usr/lib/gcc/x86_64-linux-gnu/8/crtbeginT.o
RUN make SHARED=0 CFLAGS='-static -std=gnu99 -static-libgcc -static-libstdc++ -fPIC' -j $(nproc) src/sleep
