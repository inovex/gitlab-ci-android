# gitlab-ci-android

https://hub.docker.com/r/inovex/gitlab-ci-android/

Contains the Android SDK, NDK and common packages necessary for building Android Apps in Gitlab CI (for example).
Make sure caching is enabled for the CI environment to speed up builds.

Example yml which has dependency caching enabled:

```
image: inovex/gitlab-ci-android

stages:
- release

variables:
  GRADLE_OPTS: "-Dorg.gradle.daemon=false"

before_script:
- export GRADLE_USER_HOME=$(pwd)/.gradle
- chmod +x ./gradlew

cache:
  key: ${CI_PROJECT_ID}
  paths:
  - .gradle/

build:
    stage: release
    script:
        - ./gradlew clean assembleRelease
    artifacts:
        expire_in: 2 weeks
        paths:
            - app/build/outputs/apk/*.apk
    only:
        - develop
```

### JDK 11 / 8
The Docker image supports both JDK 8 and 11, which is required for Gradle 7+.

To use the correct version within your builds, it is recommended to define `JAVA_HOME` accordingly.

```
before_script: 
  - export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
  or
  - export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
```


## License

```
Gitlab CI Android
Copyright (c) 2017 inovex GmbH (https://www.inovex.de)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
