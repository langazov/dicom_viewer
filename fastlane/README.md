fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios sync_certificates

```sh
[bundle exec] fastlane ios sync_certificates
```

Sync certificates and provisioning profiles via Match

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the Flutter iOS app (release, signed)

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

Bump build number from latest TestFlight build

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight (internal beta)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit to App Store for review

----


## Mac

### mac sync_certificates

```sh
[bundle exec] fastlane mac sync_certificates
```

Sync Mac certificates and provisioning profiles via Match

### mac build

```sh
[bundle exec] fastlane mac build
```

Build the Flutter macOS app (release, signed .pkg)

### mac bump_build

```sh
[bundle exec] fastlane mac bump_build
```

Bump build number from latest TestFlight (macOS) build

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Build and upload to TestFlight (internal beta)

### mac release

```sh
[bundle exec] fastlane mac release
```

Build and submit to the Mac App Store for review

----


## Android

### android build

```sh
[bundle exec] fastlane android build
```

Build a signed Android App Bundle (AAB)

### android bump_build

```sh
[bundle exec] fastlane android bump_build
```

Bump build number from latest Play Store internal track

### android beta

```sh
[bundle exec] fastlane android beta
```

Build and upload AAB to Play Store internal → beta track

### android release

```sh
[bundle exec] fastlane android release
```

Promote internal build to Play Store production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
