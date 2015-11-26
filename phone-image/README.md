# phone-image
Provides the necessary integration on top of /multistrap/ components to build a Plasma Mobile phone image.

## Requirements

A [Debian](http://www.debian.org) machine/VM/container, with the following additional packages installed:

 * multistrap
 * make
 * fakeroot
 * fakechroot
 * qemu-system-arm
 * qemu-user-static

## Usage

The following steps should eventually be sufficient to build a Plasma Mobile phone image:

```sh
    mkdir -p build
    cd build
    ./build-phone-image --target build
```