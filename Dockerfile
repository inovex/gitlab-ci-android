#
# inovex GitLab CI: Android
# https://hub.docker.com/r/inovexgmbh/gitlab-ci-android/
# https://www.inovex.de
# For JDK 17 (Gradle 8+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
# For JDK 21 (Gradle 8+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
# For JDK 25 (Gradle 9.1+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
# For JDK 26 (Gradle 9.4+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-26-openjdk-amd64
#

FROM ubuntu:26.04
LABEL maintainer="inovex GmbH"

ENV ANDROID_HOME="/sdk"
ENV ANDROID_SDK_ROOT="/sdk"
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin"

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get -qq update && apt-get install -y locales \
  && localedef -i en_US -c -f UTF-8 en_US.UTF-8
ENV LANG="en_US.UTF-8"

# install necessary packages
RUN apt-get update && apt-get install -qqy --no-install-recommends \
    android-tools-adb \
    apt-utils \
    openjdk-17-jdk \
    openjdk-21-jdk \
    openjdk-25-jdk \
    openjdk-26-jdk \
    checkstyle \
    unzip \
    curl \
    cmake \
    lldb \
    git \
    python-is-python3 \
    ninja-build \
    build-essential \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# pre-configure some ssl certs
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Default JVM for sdkmanager during the build; CI jobs can override it in before_script
ENV JAVA_HOME="/usr/lib/jvm/java-25-openjdk-amd64"
# Point java/javac on PATH at the same JDK as JAVA_HOME (apt would pick the highest installed version)
RUN update-alternatives --set java ${JAVA_HOME}/bin/java \
  && update-alternatives --set javac ${JAVA_HOME}/bin/javac

# download and unzip latest command line tools
RUN export CMD_LINE_TOOLS_VERSION="$(curl -fsSL https://developer.android.com/studio/index.html | grep -oP 'commandlinetools-linux-\K\d+' | sort -un | tail -n 1)" && \
  : "${CMD_LINE_TOOLS_VERSION:?could not determine command line tools version}" && \
  curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-${CMD_LINE_TOOLS_VERSION}_latest.zip -o /tools.zip && \
  unzip /tools.zip -d /tmp/cmdline-tools && \
  mkdir -p /sdk/cmdline-tools && mv /tmp/cmdline-tools/cmdline-tools /sdk/cmdline-tools/latest && \
  rm -rv /tools.zip /tmp/cmdline-tools

# Copy pkg.txt to sdk folder and create repositories.cfg
ADD pkg.txt /sdk
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg

RUN mkdir -p $ANDROID_SDK_ROOT/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK_ROOT/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_SDK_ROOT/licenses/android-sdk-preview-license

# Accept licenses
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses --sdk_root=${ANDROID_SDK_ROOT}

# Update (gradle comes with the commondline tools and the gradle-wrapper is to be expected to be included in clients project)
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --update --sdk_root=${ANDROID_SDK_ROOT}

RUN while read -r pkg; do PKGS="${PKGS}${pkg} "; done < /sdk/pkg.txt && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager ${PKGS} --sdk_root=${ANDROID_SDK_ROOT}
