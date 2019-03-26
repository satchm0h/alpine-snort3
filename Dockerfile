#
# BUILD CONTAINER
# (Note that this is a multi-phase Dockerfile)
# To build run `docker build --rm -t tebedwel/snort3-alpine:latest`
#
FROM alpine:3.8 as builder

ENV PREFIX_DIR=/usr/local
ENV HOME=/root

# Update APK adding the @testing repo for hwloc (as of Alpine v3.7)
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >>/etc/apk/repositories

# Prep APK for installing packages
RUN apk update && \
    apk upgrade

# BUILD DEPENDENCIES:
RUN apk add --no-cache \
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
    libdnet-dev \
    libpcap-dev \
    libtirpc-dev \
    luajit-dev \
    libressl-dev \
    zlib-dev \
    pcre-dev \
    libuuid \
    xz-dev

# One of the quirks of alpine is that unistd.h is in /usr/include. Lots of
# software looks for it in /usr/include/linux or /usr/include/sys.
# So, we'll make symlinks
RUN mkdir /usr/include/linux && \
    ln -s /usr/include/unistd.h /usr/include/linux/unistd.h && \
    ln -s /usr/include/unistd.h /usr/include/sys/unistd.h

# The Alpine hwloc on testing is not reliable from a build perspective.
# So, lets just build it ourselves.
#
WORKDIR $HOME
RUN wget https://download.open-mpi.org/release/hwloc/v2.0/hwloc-2.0.3.tar.gz &&\
    tar zxvf hwloc-2.0.3.tar.gz
WORKDIR $HOME/hwloc-2.0.3
RUN ./configure --prefix=${PREFIX_DIR} && \
    make && \
    make install

# BUILD Daq on alpine:
# Note that this is the old DAQ and will eventually be replaced w/ DAQ-NG

WORKDIR $HOME
RUN wget https://snort.org/downloads/snortplus/daq-2.2.2.tar.gz
RUN tar zxvf daq-2.2.2.tar.gz
WORKDIR $HOME/daq-2.2.2

# BUILD daq
RUN ./configure --prefix=${PREFIX_DIR} && make && make install


# BUILD Snort on alpine
WORKDIR $HOME
RUN git clone https://github.com/snort3/snort3.git

WORKDIR $HOME/snort3
RUN ./configure_cmake.sh \
    --prefix=${PREFIX_DIR} \
    --enable-unit-tests \
    --disable-docs


WORKDIR $HOME/snort3/build
RUN make VERBOSE=1
RUN make check && \
    make install

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
RUN apk add --no-cache  \
    flatbuffers@testing \
    libdnet \
    luajit \
    libressl \
    libpcap \
    pcre \
    libtirpc \
    musl \
    libstdc++ \
    libuuid \
    zlib \
    xz

# Copy the build artifacts from the build container to the runtime file system
COPY --from=builder ${PREFIX_DIR}/etc/ ${PREFIX_DIR}/etc/
COPY --from=builder ${PREFIX_DIR}/lib/ ${PREFIX_DIR}/lib/
COPY --from=builder ${PREFIX_DIR}/lib64/ ${PREFIX_DIR}/lib64/
COPY --from=builder ${PREFIX_DIR}/bin/ ${PREFIX_DIR}/bin/

WORKDIR /
RUN snort --version

