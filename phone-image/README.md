# phone-image
Provides the necessary integration on top of /multistrap/ components to build a Plasma Mobile phone image.

## Requirements

A [Debian](http://www.debian.org) machine/VM/container, with the following additional packages installed:

 * multistrap
 * reprepro
 * make
 * gpg/gnupg2
 * fakeroot
 * fakechroot
 * qemu-system-arm
 * qemu-user-static
 * (optionally) a web or ftp server to publish your Debian repository with custom Plasma Mobile packages.

## Usage

The following steps should eventually be sufficient to build a Plasma Mobile phone image:

```sh
    mkdir -p build
    cd build
    /path/to/phone-image/build-phone-repository --target build
    /path/to/phone-image/build-phone-image --target build
```