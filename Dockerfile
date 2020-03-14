FROM raspbian/jessie:latest as builder
ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i "s/archive.raspbian.org/mirror.tuna.tsinghua.edu.cn\/raspbian/g" /etc/apt/sources.list \
 && sed -i "s/archive.raspberrypi.org/mirror.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010

RUN apt-get update && apt-get install -y \
                              git \
                              cmake \
                              build-essential \
                              debhelper \
                              librtlsdr-dev \
                              pkg-config \
                              dh-systemd \
                              libncurses5-dev \
                              libboost-system-dev \
                              libboost-program-options-dev \
                              libboost-regex-dev \
                              libusb-1.0-0-dev \
                              doxygen \
                              libtecla-dev \
                              libtecla1 \
                              help2man \
                              pandoc
RUN git clone https://gitee.com/bclswl0827/bladeRF /tmp/src/bladeRF \
 && git clone https://gitee.com/bclswl0827/beast-splitter /tmp/src/beast-splitter \
 && git clone https://gitee.com/bclswl0827/dump1090 /tmp/src/dump1090
RUN cd /tmp/src/bladeRF \
 && git checkout 2017.12-rc1 \
 && dpkg-buildpackage -b
RUN cd /tmp/src/beast-splitter \
 && dpkg-buildpackage -b
RUN cd /tmp/src/dump1090 \
 && dpkg-buildpackage -b

FROM raspbian/jessie:latest

ENV LAT=31.17 LON=108.40 PASSWORD=20020204ZY. container=docker
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir /tmp/src \
 && sed -i "s/archive.raspbian.org/mirror.tuna.tsinghua.edu.cn\/raspbian/g" /etc/apt/sources.list \
 && sed -i "s/archive.raspberrypi.org/mirror.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010
RUN apt-get update && apt-get install -y \
                              openssh-server \
                              sudo \
                              lighttpd \
                              libfam0 \
                              mime-support \
                              spawn-fcgi

COPY --from=builder /tmp/src/libbladerf1_2017.07_armhf.deb /tmp/src/libbladerf1_2017.07_armhf.deb
COPY --from=builder /tmp/src/libbladerf-dev_2017.07_armhf.deb /tmp/src/libbladerf-dev_2017.07_armhf.deb
COPY --from=builder /tmp/src/libbladerf-udev_2017.07_armhf.deb /tmp/src/libbladerf-udev_2017.07_armhf.deb
COPY --from=builder /tmp/src/bladerf_2017.07_armhf.deb /tmp/src/bladerf_2017.07_armhf.deb
COPY --from=builder /tmp/src/bladerf-firmware-fx3_2017.07_armhf.deb /tmp/src/bladerf-firmware-fx3_2017.07_armhf.deb
COPY --from=builder /tmp/src/bladerf-fpga-hostedx115_2017.07_armhf.deb /tmp/src/bladerf-fpga-hostedx115_2017.07_armhf.deb
COPY --from=builder /tmp/src/bladerf-fpga-hostedx40_2017.07_armhf.deb /tmp/src/bladerf-fpga-hostedx40_2017.07_armhf.deb
COPY --from=builder /tmp/src/beast-splitter_3.8.0_armhf.deb /tmp/src/beast-splitter_3.8.0_armhf.deb
COPY --from=builder /tmp/src/dump1090-fa_3.8.0_armhf.deb /tmp/src/dump1090-fa_3.8.0_armhf.deb
COPY --from=builder /tmp/src/dump1090_3.8.0_all.deb /tmp/src/dump1090_3.8.0_all.deb

RUN dpkg --install /tmp/src/libbladerf1_2017.07_armhf.deb \
 && dpkg --install /tmp/src/libbladerf-dev_2017.07_armhf.deb \
 && dpkg --install /tmp/src/libbladerf-udev_2017.07_armhf.deb \
 && dpkg --install /tmp/src/bladerf_2017.07_armhf.deb \
 && dpkg --install /tmp/src/bladerf-firmware-fx3_2017.07_armhf.deb \
 && dpkg --install /tmp/src/bladerf-fpga-hostedx115_2017.07_armhf.deb \
 && dpkg --install /tmp/src/bladerf-fpga-hostedx40_2017.07_armhf.deb \
 && dpkg --install /tmp/src/beast-splitter_3.8.0_armhf.deb \
 && dpkg --install /tmp/src/dump1090-fa_3.8.0_armhf.deb \
 && dpkg --install /tmp/src/dump1090_3.8.0_all.deb

RUN rm -rf /tmp/src /home/* \
 && useradd -m meow -d /home/meow -s /bin/bash \
 && echo "meow:$PASSWORD" | chpasswd \
 && echo "meow  ALL=(ALL:ALL) ALL" >> /etc/sudoers

RUN sed -i "s/<env1>/$LAT/g" /etc/default/dump1090-fa \
 && sed -i "s/<env2>/$LON/g" /etc/default/dump1090-fa

RUN /etc/init.d/lighttpd restart
RUN /usr/share/beast-splitter/start-beast-splitter --status-file %t/beast-splitter/status.json >/dev/null 2>&1 &
RUN /usr/share/dump1090-fa/start-dump1090-fa --write-json %t/dump1090-fa --quiet >/dev/null 2>&1 &

EXPOSE 22 80
