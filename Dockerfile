#
# inovex GitLab CI: Android —— 练天星 fork
# upstream: https://github.com/inovex/gitlab-ci-android
#
# 本 fork 相对上游的改动：
#   - 基础镜像 ubuntu:20.04 → 26.04 LTS（20.04 已 EOL）
#   - JDK：17/21/25/26 官方源（移除 8/11；25 供 Gradle 9.5 的 daemon JVM criteria，
#     26 为后续 Gradle 支持 26 之后的储备，当前 Gradle 9.5.1 最高支持 25）
#   - NDK：pkg.txt 固化 ndk;28.2.13676358 装进 /sdk/ndk（CI before_script 的探测路径），
#     移除上游 /ndk 的 r25c 下载块（CI 从未使用过它）
#   - pkg.txt 增补 platforms;android-36 与 build-tools;36.0.0（compileSdk 36 所需）
#
# JAVA_HOME 用法：
# For JDK 17 (Gradle 8+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
# For JDK 21 (Gradle 8+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
# For JDK 25 (Gradle 9.1+) use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
# For JDK 26 use: before_script: - export JAVA_HOME=/usr/lib/jvm/java-26-openjdk-amd64
#

FROM ubuntu:26.04
LABEL maintainer="inovex GmbH"
ENV REPO_SHA256="6cba294d6218bbd4a1500598207b3979c752c7a122aef9429e4d7fef688833b5"

ENV ANDROID_SDK_ROOT="/sdk"
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/bin"

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get -qq update && apt-get install -y locales \
  && localedef -i en_US -c -f UTF-8 -A /etc/locale.alias en_US.UTF-8
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

# 镜像内默认 JVM 用 25（sdkmanager 等工具的确定性运行环境）；CI 的 before_script 可覆盖
ENV JAVA_HOME="/usr/lib/jvm/java-25-openjdk-amd64"

# Install Google's repo tool (https://source.android.com/setup/build/downloading#installing-repo)
RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
 && echo "${REPO_SHA256} /usr/local/bin/repo" | sha256sum --strict -c - \
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

# Update (gradle comes with the commondline tools and the gradle-wrapper is to be expected to be included in clients project)
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --update --sdk_root=${ANDROID_SDK_ROOT}

RUN while read -r pkg; do PKGS="${PKGS}${pkg} "; done < /sdk/pkg.txt && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager ${PKGS} --sdk_root=${ANDROID_SDK_ROOT}
