#########################################
##       CRASHPLAN GUI CONTAINER       ##
#########################################

FROM ubuntu
MAINTAINER simulot <jfcassan+github@gmail.com>


# I have been insprired by
# - Jessie Frazelle's blog post at https://blog.jessfraz.com/post/docker-containers-on-the-desktop/
# - this post on stackoverflow for running X11 in a container  http://stackoverflow.com/a/25280523
# - this work for installing CrashPlan Desktop gfjardim/crashplan-desktop

#
# Copy .ui_info file from the remote Crashplan machine in to current folder
#    and edit the address part to match host IP/Name:
#  4243,XXXXXXX-a49d-4413-b9b6-YYYYYYYYYYYYYYYY,192.168.0.1
#

# To run the container, create a script with following or use provided script:

# #!/bin/bash
#
# XSOCK=/tmp/.X11-unix
# XAUTH=/tmp/.docker.xauth
# touch $XAUTH
# xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
#
# docker run  \
#   -v /etc/localtime:/etc/localtime \
#   -v $(realpath .ui_info):/var/lib/crashplan/.ui_info \
#   -v $XSOCK:$XSOCK -v $XAUTH:$XAUTH -e XAUTHORITY=$XAUTH \
#   crashplan-desktop
#


# Crashplan version
ENV CP_VERSION 4.4.1

# Add needed packages
RUN apt-get update -qq \
    && apt-get install -y --force-yes --no-install-recommends \
    cpio \
    grep \
    gzip \
    openjdk-7-jre \
    sed \
  && rm -rf /var/lib/apt/lists/*

# Get application files from code42.com
ADD https://download.code42.com/installs/linux/install/CrashPlan/CrashPlan_${CP_VERSION}_Linux.tgz /tmp/CrashPlan.tgz

# Add install script
ADD scripts/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh; /tmp/install.sh; rm /tmp/install.sh

ENV DISPLAY :0

ENTRYPOINT  ["/usr/local/crashplan/bin/CrashPlanDesktop"]
