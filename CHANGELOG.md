# Changelog

## Unreleased

### Breaking changes
- JDK 8 and 11 were removed.
- The standalone NDK r25c in `/ndk` and the `ANDROID_NDK_HOME` variable were removed. Use the NDK under `/sdk/ndk` instead.
- Google's `repo` tool is no longer installed.
- Command-line tools moved from `/sdk/cmdline-tools/bin` to the standard `/sdk/cmdline-tools/latest/bin`.

### Changed
- Base image upgraded from Ubuntu 20.04 to 26.04.
- Default JDK is 25: `JAVA_HOME` and the `java`/`javac` on `PATH` point to it.
- `sdkmanager` is on `PATH` and works without `--sdk_root`.

### Added
- JDK 25 and 26.
- `ANDROID_HOME=/sdk` (alongside the deprecated `ANDROID_SDK_ROOT`).
- NDK 28.2.13676358 in `/sdk/ndk`.
- `platforms;android-36` and `build-tools;36.0.0`.
