# gitlab-ci-android
Contains the Android SDK and common packages necessary for building Android Apps in Gitlab CI (for example)
Make sure caching is enabled for the CI environment to speed up builds.

Example yml which has dependency caching enabled:

```
image: inovex/gitlab-ci-android

stages:
- release

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
