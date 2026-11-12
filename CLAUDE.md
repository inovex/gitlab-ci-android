# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Source for the Docker image `inovexgmbh/gitlab-ci-android` (https://hub.docker.com/r/inovexgmbh/gitlab-ci-android/): Ubuntu + multiple JDKs + Android SDK/NDK for building Android apps in GitLab CI. The whole product is `Dockerfile` plus `pkg.txt`. There is no application code, no test suite, and no CI config in the repo.

## Build and verify

The image is amd64-only: Linux SDK build-tools/NDK are x86_64 binaries and JDK paths are hardcoded as `*-openjdk-amd64`. On Apple Silicon, always pass `--platform` (runs emulated, slow); without it the build fails with `JAVA_HOME is set to an invalid directory`:

```sh
docker build --platform linux/amd64 -t gitlab-ci-android .
```

No tests exist. Verify a change by building the image, then inspecting it, for example:

```sh
docker run --rm --platform linux/amd64 gitlab-ci-android ls /usr/lib/jvm /sdk /sdk/ndk
docker run --rm --platform linux/amd64 gitlab-ci-android sdkmanager --list_installed
```

## How the Dockerfile fits together

- **JDKs** come from Ubuntu apt (`openjdk-NN-jdk`). Consumers pick one by exporting `JAVA_HOME=/usr/lib/jvm/java-NN-openjdk-amd64` in `before_script`. The image default `JAVA_HOME` is JDK 25 and is what `sdkmanager` runs on during the build; `update-alternatives` points `java`/`javac` on `PATH` at the same JDK.
- **Android command-line tools** version is not pinned: the build scrapes the current `commandlinetools-linux-<N>` number from developer.android.com. A change to that page breaks the build.
- The tools zip is moved into the standard `/sdk/cmdline-tools/latest/` layout, which lets `sdkmanager` find the SDK root on its own. `/sdk/cmdline-tools/latest/bin` is on `PATH`; the Dockerfile still calls `sdkmanager` by full path with `--sdk_root=${ANDROID_SDK_ROOT}`.
- **SDK licenses** are pre-seeded by writing known hashes into `/sdk/licenses/`, then `yes | sdkmanager --licenses` accepts the rest.
- **`pkg.txt`** lists one `sdkmanager` package id per line (`build-tools;X`, `platforms;android-N`, `ndk;X`, ...). It is read with `while read`, so the file must end with a newline or the last package is silently skipped. Adding/removing SDK components = editing this file only.
- The NDK is installed via `pkg.txt` into `/sdk/ndk/<version>`; consumer CI looks for it there.

## Gotchas

- Base image is `ubuntu:26.04`. It ships no `locale.alias`, so `localedef` runs without `-A`.
- The JDK list appears in the Dockerfile header comment and in `README.md`; keep both in sync when changing JDKs.
- Record every user-visible image change (especially breaking ones) under `## Unreleased` in `CHANGELOG.md` (create it above the latest release; releases are headed `## <docker tag> - <date>`), not in `README.md`.
