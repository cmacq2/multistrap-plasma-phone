# multistrap
Provides a core for building Debian repositories based on reprepro. To use it, create your own project which
wraps the core in an integration layer that provides additional local configuration options and files.
See /phone-image/ for an example.

## Requirements

A [Debian](http://www.debian.org) machine/VM/container, with the following additional packages installed:

 * reprepro
 * make
 * gpg/gnupg2
 * (optionally) a web or ftp server to publish the repository.

## Quick guide to creating your own layer
At minimum the following steps are required to create project that can be turned into a Debian repository using the /reprepro/ core:

 1. Create a directory structure like this:
 ```sh
    mkdir -p project_dir/reprepro
    touch project_dir/build.sh
    chmod u+x project_dir/build.sh
 ```
 2. Edit the `build.sh` script to wrap /driver/driver.sh like this:
 ```sh
    #!/bin/sh
    . path/to/driver/driver.sh && run_driver reprepro HELP_DESCRIPTION="builds my repo" -- "$@"
 ```
 3. Add repository configuration templates to project_dir/reprepro.
 In particular add project_dir/reprepro/distributions.in file to configure the distributions in your repository, as well
 as a project_dir/reprepro/incoming.in to set up a local queue of 'incoming' packages to be processed by reprepro whenever you `build`
 the repository.
 4. Review the output of the Makefile `help` target and use the `buildinfo` target to experiment with build options.
 For example:
 ```sh
    project_dir/build.sh -h # get help
    project_dir/build.sh -t help # get Makefile 'help' output
    project_dir/build.sh -t buildinfo DEBIAN_ARCH=i386
 ```
 6. (Re)build with your chosen options:
 ```sh
    # build repository for armhf architecture
    project_dir/build.sh -t rebuild DEBIAN_ARCH=armhf REPO_KEY=repo_signing_key UPLOAD_KEYS=my_package_signing_key
 ```
 7. Test and debug... until you are happy with your repository configuration.
 8. Alter your driver script (`build.sh`) to pass the correct options directly so you don't have to repeat them in the build command every time.
 9. To update/populate your repository put your packages/*.changes files in the incoming queue directory, and run:
 ```
 project_dir/build.sh -t build
 ```

Please note: rebuilding/reconfiguring the repository currently throws away the old data, including any packages you uploaded. So it's not very
useful other than to start over from scratch. For updating your repository, set up the incoming queue in your repository configuration
(project_dir/reprepro/incoming.in), upload the packages with *.changes files to the incoming directory and use the `build` target to process
incoming packages.

