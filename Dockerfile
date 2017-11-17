#
# inovex GitLab CI: Android v1.0
# Build Tools: v26.0.2
# Target SDK: 26, 27
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

# Copy pkg.txt to sdk folder and create repositories.cfg
ADD pkg.txt /sdk
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg

# Accept licenses
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses

# Update
RUN ${ANDROID_HOME}/tools/bin/sdkmanager --update 

RUN while read -r pkg; do PKGS="${PKGS}${pkg} "; done < /sdk/pkg.txt && \
    ${ANDROID_HOME}/tools/bin/sdkmanager ${PKGS}
