#
# BUILD CONTAINER
# (Note that this is a multi-phase Dockerfile)
# To build run `docker build --rm -t tebedwel/snort3-alpine:latest`
#
FROM alpine:latest as builder

ENV PREFIX_DIR=/usr/local
ENV HOME=/root

# Update APK adding the @testing repo for hwloc (as of Alpine v3.7)
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >>/etc/apk/repositories

# Prep APK for installing packages
RUN apk update
RUN apk upgrade

# BUILD DEPENDENCIES:
RUN apk add --no-cache \
    # Build Tools
    wget \
    build-base \
    git \
    cmake \
    bison \
    flex \
    lcov@testing \
    cppcheck \
    cpputest \
    # Libraries
    flatbuffers-dev@testing \
    hwloc-dev@testing \
    libdnet-dev \
    libpcap-dev \
    libtirpc-dev \
    luajit-dev \
    openssl-dev \
    pcre-dev \
    libuuid \
    xz-dev

# BUILD Daq on alpine:
# Note that this is the old DAQ and will eventually be replaced w/
# DAQ-NG. Please pardon the sed hack for Alpine compilation

WORKDIR $HOME
RUN wget https://snort.org/downloads/snortplus/daq-2.2.2.tar.gz
RUN tar zxvf daq-2.2.2.tar.gz
WORKDIR $HOME/daq-2.2.2

# Hack around compiler errors in daq on Alpine
RUN find . -name '*.c' -exec sed -i -e 's/sys\/unistd\.h/unistd\.h/g' {} \;

# BUILD daq
RUN ./configure --prefix=${PREFIX_DIR} && make
RUN make install


# BUILD Snort on alpine
WORKDIR $HOME
RUN git clone https://github.com/snort3/snort3.git

WORKDIR $HOME/snort3
RUN ./configure_cmake.sh --prefix=${PREFIX_DIR}


WORKDIR $HOME/snort3/build
RUN make VERBOSE=1
RUN make install

#
# RUNTIME CONTAINER
#
FROM alpine:latest

ENV PREFIX_DIR=/usr/local/
WORKDIR ${PREFIX_DIR}

# Update APK adding the @testing repo for hwloc (as of Alpine v3.7)
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >>/etc/apk/repositories

# Prep APK for installing packages
RUN apk update
RUN apk upgrade

# RUNTIME DEPENDENCIES:
RUN apk add --no-cache hwloc@testing \
    flatbuffers@testing \
    libdnet \
    luajit \
    openssl \
    libpcap \
    pcre \
    libtirpc \
    musl \
    libstdc++ \
    libuuid \
    xz

# Copy the build artifacts from the build container to the runtime file system
COPY --from=builder ${PREFIX_DIR}/etc/ ${PREFIX_DIR}/etc/
COPY --from=builder ${PREFIX_DIR}/lib/ ${PREFIX_DIR}/lib/
COPY --from=builder ${PREFIX_DIR}/lib64/ ${PREFIX_DIR}/lib64/
COPY --from=builder ${PREFIX_DIR}/bin/ ${PREFIX_DIR}/bin/

WORKDIR /
RUN snort --version

