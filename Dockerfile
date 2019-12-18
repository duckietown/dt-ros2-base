ARG ARCH=arm32v7
ARG ROS_DISTRO=dashing
ARG OS_DISTRO=bionic
ARG BASE_TAG=${ROS_DISTRO}-ros-base-${OS_DISTRO}

FROM ${ARCH}/ros:${BASE_TAG}

ARG ARCH
ARG ROS_DISTRO
ARG OS_DISTRO

# setup environment
ENV INITSYSTEM off
ENV QEMU_EXECVE 1
ENV TERM "xterm"
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONIOENCODING UTF-8
ENV ROS_DISTRO "${ROS_DISTRO}"
ENV OS_DISTRO "${OS_DISTRO}"

# copy QEMU
COPY ./assets/qemu/${ARCH}/ /usr/bin/

# install libraries
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
  && rm -rf /var/lib/apt/lists/*

# setup keys
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

# setup sources.list
RUN echo "deb [arch=${ARCH}] http://packages.ros.org/ros2/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros2-latest.list

# copy dependencies file
COPY dependencies-apt.txt /tmp/
COPY dependencies-py.txt /tmp/

# install apt dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    $(awk -F: '/^[^#]/ { print $1 }' /tmp/dependencies-apt.txt | uniq) \
  && rm -rf /var/lib/apt/lists/*

# install python dependencies
RUN pip install -r /tmp/dependencies-py.txt

# remove dependencies files
RUN rm /tmp/dependencies*

# upgrade pip
RUN pip install --upgrade pip

# RPi libs
ADD assets/vc.tgz /opt/
COPY assets/00-vmcs.conf /etc/ld.so.conf.d
RUN ldconfig

# setup entrypoint
COPY ./assets/ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]

# configure command
CMD ["bash"]

LABEL maintainer="Andrea F. Daniele (afdaniele@ttic.edu)"
