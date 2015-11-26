# multistrap
Provides a core for building Debian images based on multistrap. To use it, create your own project which
wraps the core in an integration layer that provides additional local configuration options and files.
See /phone-image/ for an example.

## Requirements

A [Debian](http://www.debian.org) machine/VM/container, with the following additional packages installed:

 * multistrap
 * make
 * fakeroot
 * fakechroot

## Quick guide to creating your own layer
At minimum the following steps are required to create project that can be turned into a Debian image using the /multistrap/ core:

 1. Create a directory structure like this:
 ```sh
    mkdir -p project_dir/multistrap/hooks
    touch project_dir/build.sh
    chmod u+x project_dir/build.sh
 ```
 2. Edit the `build.sh` script to wrap /multistrap/driver.sh like this:
 ```sh
    #!/bin/sh
    . path/to/multistrap/driver.sh && run_driver HELP_DESCRIPTION="builds my project" -- "$@"
 ```
 3. Optional: add a repository `*.conf` file. It will be merged into a configuration file for multistrap during build.
 ```sh
    cat << EOF > project_dir/multistrap/repo.conf
    source = http://repository.domain/debian
    suite = suite-name
    keyring = repo-keyring-package-name
    EOF;
 ```
 Each repository `*.conf` file should contain the contents of a single repository section (minus the `[SectionName]`).
 4. Optional: put multistrap hook scripts in `project_dir/multistrap/hooks`. Hook scripts can be used to fixup the
 rootfs (in particular: run dpkg --configure) before it is packaged into a tarball.
 5. Review the output of the Makefile `help` target and use the `buildinfo` target to experiment with build options.
 For example:
 ```sh
    project_dir/build.sh -h # get help
    project_dir/build.sh -t help # get Makefile 'help' output
    project_dir/build.sh -t buildinfo DEBIAN_ARCH
 ```
 6. (Re)build with your chosen options:
 ```sh
    # build for armhf using only Debian unstable plus any repository *.conf created in step #3.
    project_dir/build.sh -t rebuild DEBIAN_ARCH=armhf DEBIAN_REPO_DEFAULT=unstable INCLUDE_DEFAULTS=n have_unstable=y
 ```
 7. Test and debug... until you are happy with your images.
 8. Alter your driver script (`build.sh`) to pass the correct options directly so you don't have to repeat them in the build command every time.

