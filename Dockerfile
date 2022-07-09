#
# inovex GitLab CI: Android v1.0
# https://hub.docker.com/r/inovex/gitlab-ci-android/
# https://www.inovex.de
# For JDK 11 (Gradle 7+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# For JDK 8: before_script: - export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#

FROM ubuntu:20.04
LABEL maintaner="amatsehor"

ENV NDK_VERSION r21d

ENV ANDROID_SDK_ROOT "/sdk"
ENV ANDROID_NDK_HOME "/ndk"
ENV PATH "$PATH:${ANDROID_SDK_ROOT}/bin"

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get -qq update && apt-get install -y locales \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.UTF-8

# install necessary packages
# prevent installation of openjdk-11-jre-headless with a trailing minus,
# as openjdk-8-jdk can provide all requirements and will be used anyway
RUN apt-get install -qqy --no-install-recommends \
    apt-utils \
    openjdk-8-jdk \
    openjdk-11-jdk \
    checkstyle \
    libc6-i386 \
    lib32stdc++6 \
    lib32gcc1 \
    lib32ncurses6 \
    lib32z1 \
    unzip \
    curl \
    cmake \
    lldb \
    git \
    ninja-build \
    build-essential \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# pre-configure some ssl certs
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Install Google's repo tool version 1.23 (https://source.android.com/setup/build/downloading#installing-repo)
RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
 && echo "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 /usr/local/bin/repo" | sha256sum --strict -c - \
 && chmod a+x /usr/local/bin/repo

# download and unzip latest command line tools
RUN export CMD_LINE_TOOLS_VERSION="$(curl -s https://developer.android.com/studio/index.html | grep -oP 'commandlinetools-linux-\K\d+' | uniq)" && \
  curl -s https://dl.google.com/android/repository/commandlinetools-linux-${CMD_LINE_TOOLS_VERSION}_latest.zip -o /tools.zip && \
  unzip /tools.zip -d /sdk && \
  rm -v /tools.zip

# Copy pkg.txt to sdk folder and create repositories.cfg
ADD pkg.txt /sdk
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg

RUN mkdir -p $ANDROID_SDK_ROOT/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK_ROOT/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_SDK_ROOT/licenses/android-sdk-preview-license

# Accept licenses
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --licenses --sdk_root=${ANDROID_SDK_ROOT}

# Update
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --update --sdk_root=${ANDROID_SDK_ROOT}

RUN while read -r pkg; do PKGS="${PKGS}${pkg} "; done < /sdk/pkg.txt && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager ${PKGS} --sdk_root=${ANDROID_SDK_ROOT}

# uncomment in case NDK is needed

#RUN mkdir /tmp/android-ndk && \
#    cd /tmp/android-ndk && \
#    curl -s -O https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip && \
#    unzip -q android-ndk-${NDK_VERSION}-linux-x86_64.zip && \
#    mv ./android-ndk-${NDK_VERSION} ${ANDROID_NDK_HOME} && \
#    cd ${ANDROID_NDK_HOME} && \
#    rm -rf /tmp/android-ndk
