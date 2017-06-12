#
# inovex GitLab CI: Android v1.0
# SDK Tools v25.2.3
# Build Tools: v25.0.3
# Target SDK: 25
# https://hub.docker.com/r/inovex/gitlab-ci-android/
# https://www.inovex.de
#

FROM ubuntu:16.04
LABEL maintainer inovex GmbH

ENV SDK_TOOLS_VERSION "3859397"

ENV ANDROID_HOME "/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

# install necessary packages
RUN apt-get -qq update && apt-get install -qqy --no-install-recommends \
    apt-utils \
    openjdk-8-jdk \
    libc6-i386 \
    lib32stdc++6 \
    lib32gcc1 \
    lib32ncurses5 \
    lib32z1 \
    unzip \
    curl \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# pre-configure some ssl certs
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# download and unzip sdk
RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${SDK_TOOLS_VERSION}.zip > /tools.zip && \
    unzip /tools.zip -d /sdk && \
    rm -v /tools.zip

# licensing stuff
RUN mkdir -p $ANDROID_HOME/licenses/
RUN echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > $ANDROID_HOME/licenses/android-sdk-license
RUN echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

ADD pkg.txt /sdk
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update && \
  (while [ 1 ]; do sleep 5; echo y; done) | ${ANDROID_HOME}/tools/bin/sdkmanager --package_file=/sdk/pkg.txt
