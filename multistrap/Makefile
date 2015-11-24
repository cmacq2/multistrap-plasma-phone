#!/usr/bin/make
#
# Makefile to synthesis multistrap configuration from various repository configuration files
# and then build the resulting root filesystem.
#
override current_mkfile_path = $(abspath $(lastword $(MAKEFILE_LIST)))
override current_mkfile_dir = $(patsubst %/,%,$(dir $(current_mkfile_path)))

#
# Define a canned recipe that lists the build help. Use with $(info ...)
#
override define BUILD_HELP
$(notdir $(current_mkfile_path)) : generates Plasma Mobile images
Usage:
make -f '$(current_mkfile_path)' \
        <target> [VARIABLES]

The following (explicit) targets are useful:

build                    : build a Plasma Mobile image.
buildinfo                : print values of configurable VARIABLES.
clean                    : delete build directory (BUILDDIR)
configure                : generate multistrap configuration file.
help                     : display this 'help' text.
rebuild                  : update (redo) a previous 'build'.
reconfigure              : update (redo) a previous 'configure'.

The following paths may be set to customise the build:

SRCDIR                   : 'source' directory for locally provided
                           configuration files and scripts.
                           This directory must exist, the default is the
                           directory from which Make was invoked.
BUILDDIR                 : directory to place build artefacts. It will be
                           created if it does not exist, the default is
                           to use a 'build' subdirectory in SRCDIR.

The following variables can be used to customise output:

DEBIAN_ARCH              : 'native' architecture of the Debian image
DEBIAN_MULTIARCH         : additional 'multiarch' architectures
MULTISTRAP_ARGS          : pass options to multistrap, directly
                           Warning: do not pass -a, -c, -d or -f.
                           These will be passed by this makefile, also.
DEBIAN_PACKAGES          : set of packages to install on top of the minimal
                           Debian base installation. Applies if at least one
                           of the Debian default repositories is enabled.
DEBIAN_DEFAULT_REPO      : repository used to install DEBIAN_PACKAGES from.
                           Valid values are: 'testing', 'backports', 'sid',
                           'unstable' or 'Sid'; depending on whether the
                           corresponding default repository is enabled.
LOCAL_REPOSITORIES       : additional repository configuration files to use
                           with multistrap. By default SRCDIR is scanned for
                           repository configurationn (*.conf) files.
HOOKS                    : scripts to be called by multistrap (hooks)
                           Refer to the multistrap documentation for details.

Default Debian repositories can be enabled/disabled using boolean settings
Values which are 'true'  : $(positives)

INCLUDE_DEFAULTS         : boolean: whether to include the default
                           Debian repositories (enabled by default).
INCLUDE_TESTING_DEFAULTS : boolean: whether to include the testing suite in
                           default Debian repositories (enabled by default).
                           Overrides: INCLUDE_DEFAULTS
have_stable              : boolean whether to include the default repository
                           for the Debian 'stable' distribution.
                           Overrides: INCLUDE_DEFAULTS
have_testing             : boolean: whether to include the default repository
                           for the Debian 'testing' distribution.
                           Overrides: INCLUDE_TESTING_DEFAULTS
have_testing_security    : boolean: whether to include security updates
                           repository for the Debian 'testing' distribution.
                           Overrides: INCLUDE_TESTING_DEFAULTS
have_testing_updates     : boolean: whether to include the backports
                           repository for the Debian 'testing' distribution.
                           Overrides: INCLUDE_TESTING_DEFAULTS
have_unstable            : boolean: whether to include the default repository
                           for the Debian 'unstable' distribution.
                           Overrides: INCLUDE_DEFAULTS
endef

DESTDIR ?= .

SRCDIR ?= $(CURDIR)

#
# Check that SRCDIR exists.
# If it doesn't it's a fatal error
#
override define srcdir_error

Invalid source directory: "$(SRCDIR)"
endef

ifeq "$(wildcard $(SRCDIR))" ""
$(error $(srcdir_error))
endif

BUILDDIR ?= $(SRCDIR)/build

#
# Check that BUILDDIR is not empty.
# If it is, assume the default (./build)
#
override define builddir_warning

Ignore invalid build directory: "$(BUILDDIR)"
endef

ifeq "$(BUILDDIR)" ""
$(warning $(builddir_warning))
override BUILDDIR := $(SRCDIR)/build
endif

DEBIAN_ARCH ?=
DEBIAN_MULTIARCH ?=
MULTISTRAP_ARGS ?=
DEBIAN_PACKAGES ?= locales bash apt aptitude fakeroot fakechroot debconf-utils systemd systemd-sysv

DEBIAN_DEFAULT_REPO ?=

#
# Logic to check which default repositories are enabled. This is a bit convoluted:
#  - Support multiple 'sane' values to affirm using $(filter ...): yes, y, 1, true...
#  - Checked variables are overwritten with the result of $(filter ...)
#  - The result is: if the checked value is valid (found in the list of valid value), it will retain its value.
#    If not, it will be emptied ("").
#
override positives = yes y 1 true on enabled enable
override negatives = no n 0 false off disabled disable

INCLUDE_DEFAULTS ?= yes
INCLUDE_TESTING_DEFAULTS ?= yes
override INCLUDE_DEFAULTS := $(filter $(INCLUDE_DEFAULTS),$(positives))
override INCLUDE_TESTING_DEFAULTS := $(filter $(INCLUDE_TESTING_DEFAULTS),$(positives))

ifneq "$(INCLUDE_DEFAULTS)" ""
have_unstable ?= yes
have_stable ?= yes
ifneq "$(INCLUDE_TESTING_DEFAULTS)" ""
have_testing_security ?= yes
have_testing_updates ?= yes
have_testing ?= yes
else
have_testing_security ?= no
have_testing_updates ?= no
have_testing ?= no
endif
else
have_stable ?= no
have_unstable ?= no
ifneq "$(INCLUDE_TESTING_DEFAULTS)" ""
have_testing_security ?= yes
have_testing_updates ?= yes
have_testing ?= yes
else
have_testing_security ?= no
have_testing_updates ?= no
have_testing ?= no
endif
endif

override have_testing_security := $(filter $(have_testing_security),$(positives))
override have_testing_updates := $(filter $(have_testing_updates),$(positives))
override have_testing := $(filter $(have_testing),$(positives))
override have_unstable := $(filter $(have_unstable),$(positives))
override have_stable := $(filter $(have_stable),$(positives))

#
# Valid selected DEBIAN_DEFAULT_REPO. If the value passed doesn't conform to known values it is discared and a suitable default calculated.
# Aliases which are recognised:
#  - sid Sid unstable --> */repos/debian-unstable.conf
#  - testing --> */repos/testing.conf
#

override define debian_default_repo_warning

Ignore invalid value for DEBIAN_DEFAULT_REPO: $(DEBIAN_DEFAULT_REPO)
endef

override define debian_default_disabled_warning
$(debian_default_repo_warning)
Repository is not enabled
endef

override DEBIAN_TESTING_IDS = testing $(current_mkfile_path)/repos/debian-testing.conf
override DEBIAN_UNSTABLE_IDS= sid Sid unstable $(current_mkfile_path)/repos/debian-unstable.conf
override DEBIAN_BACKPORT_IDS= backports $(current_mkfile_path)/repos/debian-testing-updates.conf
override DEBIAN_STABLE_IDS = stable $(current_mkfile_path)/repos/debian-stable.conf
override debian_default_valid =

ifeq "$(words $(DEBIAN_DEFAULT_REPO))" "1"

# DEBIAN_DEFAULT_REPO == stable ?
ifeq "$(filter $(DEBIAN_DEFAULT_REPO),$(DEBIAN_STABLE_IDS))" "$(DEBIAN_DEFAULT_REPO)"
ifeq "$(have_stable)" "" # stable disabled?
$(warning $(debian_default_disabled_warning))
override DEBIAN_DEFAULT_REPO = guess
override debian_default_valid = false
else
override DEBIAN_DEFAULT_REPO = $(current_mkfile_path)/repos/debian-stable.conf
override debian_default_valid = true
endif
endif

# DEBIAN_DEFAULT_REPO == testing ?
ifeq "$(filter $(DEBIAN_DEFAULT_REPO),$(DEBIAN_TESTING_IDS))" "$(DEBIAN_DEFAULT_REPO)"
ifeq "$(have_testing)" "" # testing disabled?
$(warning $(debian_default_disabled_warning))
override DEBIAN_DEFAULT_REPO = guess
override debian_default_valid = false
else
override DEBIAN_DEFAULT_REPO = $(current_mkfile_path)/repos/debian-testing.conf
override debian_default_valid = true
endif
endif

# DEBIAN_DEFAULT_REPO == backports ?
ifeq "$(filter $(DEBIAN_DEFAULT_REPO),$(DEBIAN_BACKPORT_IDS))" "$(DEBIAN_DEFAULT_REPO)"
ifeq "$(have_testing_updates)" "" # backports disabled?
$(warning $(debian_default_disabled_warning))
override DEBIAN_DEFAULT_REPO = guess
override debian_default_valid = false
else
override DEBIAN_DEFAULT_REPO = $(current_mkfile_path)/repos/debian-testing-updates.conf
override debian_default_valid = true
endif
endif

# DEBIAN_DEFAULT_REPO == unstable ?
ifeq "$(filter $(DEBIAN_DEFAULT_REPO),$(DEBIAN_UNSTABLE_IDS))" "$(DEBIAN_DEFAULT_REPO)"
ifeq "$(have_unstable)" "" # unstable disabled?
$(warning $(debian_default_disabled_warning))
override DEBIAN_DEFAULT_REPO = guess
override debian_default_valid = false
else
override DEBIAN_DEFAULT_REPO = $(current_mkfile_path)/repos/debian-unstable.conf
override debian_default_valid = true
endif
endif
endif

ifeq "$(debian_default_valid)" ""
ifneq "$(origin DEBIAN_DEFAULT_REPO)" "file"
$(warning $(debian_default_repo_warning))
endif
override DEBIAN_DEFAULT_REPO = guess
endif

#
# Check that *if* LOCAL_REPOSITORIES are specified/included, all repositories are valid.
# If not, warn about this: only valid repositories will be used.
#
LOCAL_REPOSITORIES ?= $(wildcard $(SRCDIR)/*.conf)

override define invalid_local_repositories_warning

Ignored some (invalid) repositories specified in LOCAL_REPOSITORIES:
$(LOCAL_REPOSITORIES)
endef

# we know the LOCAL_REPOSITORIES result to be valid if it was defined by the makefile
ifeq "$(origin LOCAL_REPOSITORIES)" "file"
override INCLUDE_REPOS = $(LOCAL_REPOSITORIES)
else
# we need to check validity:
# no repositories is a valid option
ifeq "$(LOCAL_REPOSITORIES)" ""
override INCLUDE_REPOS =
else
# $(wildcard) expansion to filter LOCAL_REPOSITORIES down to list of valid files.
override INCLUDE_REPOS = $(wildcard $(LOCAL_REPOSITORIES))
# reverse filtering to undo wildcard expansion (edge case: files with ? or * in their name)
override INCLUDE_REPOS := $(filter $(LOCAL_REPOSITORIES),$(INCLUDE_REPOS))
# warn about any discrepancies in the result
ifneq "$(INCLUDE_REPOS)" "$(LOCAL_REPOSITORIES)"
$(warning $(invalid_local_repositories_warning))
endif
endif # endif for is LOCAL_REPOSITORIES empty?
endif # endif for origin of LOCAL_REPOSITORIES

override DEFAULT_REPOS =

#
# Order of the debian-unstable.conf & debian-testing.conf blocks is significant:
# The first block will be given priority for 'default' status for DEBIAN_DEFAULT_REPO over the other.
# This applies only if no DEBIAN_DEFAULT_REPO has been configured explicitly yet,
# and both '-testing' and '-unstable' repos are used.
#
ifneq "$(have_unstable)" ""
override DEFAULT_REPOS += $(current_mkfile_dir)/repos/debian-unstable.conf
ifeq "$(DEBIAN_DEFAULT_REPO)" "guess"
override DEBIAN_DEFAULT_REPO = $(current_mkfile_dir)/repos/debian-unstable.conf
override debian_default_valid := true
endif
else
override have_unstable = no
endif

ifneq "$(have_testing)" ""
override DEFAULT_REPOS += $(current_mkfile_dir)/repos/debian-testing.conf
ifeq "$(DEBIAN_DEFAULT_REPO)" "guess"
override DEBIAN_DEFAULT_REPO = $(current_mkfile_dir)/repos/debian-testing.conf
override debian_default_valid := true
endif
else
override have_testing = no
endif

ifneq "$(have_stable)" ""
override DEFAULT_REPOS += $(current_mkfile_dir)/repos/debian-stable.conf
ifeq "$(DEBIAN_DEFAULT_REPO)" "guess"
override DEBIAN_DEFAULT_REPO = $(current_mkfile_dir)/repos/debian-stable.conf
override debian_default_valid := true
endif
else
override have_stable = no
endif

ifneq "$(have_testing_security)" ""
override DEFAULT_REPOS += $(current_mkfile_dir)/repos/debian-testing-security.conf
else
override have_testing_security = no
endif

ifneq "$(have_testing_updates)" ""
override DEFAULT_REPOS += $(current_mkfile_dir)/repos/debian-testing-updates.conf
else
override have_testing_updates = no
endif

#
# Check that *if* HOOKS are specified/included, all hooks are valid.
# If not, warn about this: only valid hook scripts will be used.
#
HOOKS ?= $(wildcard $(SRCDIR)/hooks/*)

override define invalid_hooks_warning

Ignored some (invalid) scripts specified in HOOKS:
$(HOOKS)
endef

# we know the HOOKS result to be valid if it was defined by the makefile
ifeq "$(origin HOOKS)" "file"
override INCLUDE_HOOKS = $(HOOKS)
else
# we need to check validity:
# no hooks is a valid option
ifeq "$(HOOKS)" ""
override INCLUDE_HOOKS =
else
# $(wildcard) expansion to filter HOOKS down to list of valid files.
override INCLUDE_HOOKS = $(wildcard $(HOOKS))
# reverse filtering to undo wildcard expansion (edge case: files with ? or * in their name)
override INCLUDE_HOOKS := $(filter $(HOOKS),$(INCLUDE_HOOKS))
# warn about any discrepancies in the result
ifneq "$(INCLUDE_HOOKS)" "$(HOOKS)"
$(warning $(invalid_hooks_warning))
endif
endif # endif for is HOOKS empty?
endif # endif for origin of HOOKS

override MULTISTRAP_ROOT_DIR = $(BUILDDIR)/root
override MULTISTRAP_HOOK_DIR = $(BUILDDIR)/hooks
override REPOSITORY_DIR = $(BUILDDIR)/repos
override MULTISTRAP_CFG = $(BUILDDIR)/multistrap.cfg
override MULTISTRAP_IMAGE_TAR = $(BUILDDIR)/$(if $(DEBIAN_ARCH),rootfs-$(DEBIAN_ARCH).tar,rootfs.tar)
override STAMP_FILE = $(BUILDDIR)/build.stamp

#
# Check that CONFIG_REPOS is not empty.
# If it is, bail out with an error because we/multistrap can't be expected to cope without any apt repositories to work with.
#
# This error should be deferred until -separator is called to let buildinfo output help debug the problem.
#
override define empty_config_repos_error

No APT repositories to be configured.
Check that you have LOCAL_REPOSITORIES or at least one 'default' repository
endef

override CONFIG_REPOS = $(patsubst $(current_mkfile_dir)/repos/%,$(REPOSITORY_DIR)/defaults/%,$(DEFAULT_REPOS))
override CONFIG_REPOS += $(patsubst $(abspath $(SRCDIR))/%,$(REPOSITORY_DIR)/%,$(abspath $(INCLUDE_REPOS)))
override CONFIG_HOOKS = $(patsubst $(abspath $(SRCDIR))/%,$(MULTISTRAP_HOOK_DIR)/%,$(abspath $(INCLUDE_HOOKS)))

override INCLUDE_SRCS = $(INCLUDE_HOOKS) $(INCLUDE_REPOS) $(DEFAULT_REPOS)

override DEBIAN_DEFAULT_REPO := $(patsubst $(BUILDDIR)/%,%,$(patsubst $(current_mkfile_dir)/repos/%,$(REPOSITORY_DIR)/defaults/%,$(DEBIAN_DEFAULT_REPO)))

#
# Check that BUILDDIR setting will not clobber sources.
#
override define builddir_error
Ignore invalid build directory: "$(BUILDDIR)"
Build directory collides with sources
endef

override BUILDFILE_PATTERNS = $(REPOSITORY_DIR)/% $(MULTISTRAP_HOOK_DIR)/% $(MULTISTRAP_ROOT_DIR)/% $(MULTISTRAP_CFG) $(STAMP_FILE)

override define check_builddir_error
$(if $(filter $(BUILDFILE_PATTERNS),$(INCLUDE_SRCS)),$(error $(builddir_error)),)
endef

#
# Calculate the contents of the '[General]' section of the multistrap configuration file.
# Cannot use a canned recipe (define block) because the variable must be echo'ed in a shell expression.
#
override MULTISTRAP_GENERAL_SECTION = "\#\n\
\# Multistrap configuration for Plasma Mobile (phone)\n\
\# Generated by: $(current_mkfile_path)\n\
\#\n\
[General]\n\
arch = $(DEBIAN_ARCH)\
$(if $(DEBIAN_MULTIARCH),\nmultiarch = $(DEBIAN_MULTIARCH)\n,\n)\
directory = $(patsubst $(abspath $(BUILDDIR))/%,%,$(abspath $(MULTISTRAP_ROOT_DIR)))\n\
bootstrap = $(patsubst $(abspath $(BUILDDIR))/%,%,$(abspath $(CONFIG_REPOS)))\n\
aptsources = $(patsubst $(abspath $(BUILDDIR))/%,%,$(abspath $(CONFIG_REPOS)))\n\
hookdir = $(patsubst $(abspath $(BUILDDIR))/%,%,$(abspath $(MULTISTRAP_HOOK_DIR)))\n\
tarball = $(patsubst $(abspath $(BUILDDIR))/%,%,$(abspath $(MULTISTRAP_IMAGE_TAR)))\n\
markauto = true\n\
cleanup = true\n\
noauth = false \n\
unpack = true \n\
explicitsuite = false\n\
allowrecommends = false\n\
omitrequired = false\n\
\n"

#
# Define a canned recipe that lists the buildinfo. Use with $(info ...)
#
override define BUILD_INFO
================================= BUILD PATHS ================================

Makefile                 : $(current_mkfile_path)
Makefile directory       : $(current_mkfile_dir)
Source directory         : $(SRCDIR)
Build directory          : $(BUILDDIR)
Destination directory    : $(DESTDIR)

================================= MULTISTRAP =================================

Configuration            : $(MULTISTRAP_CFG)
Tarball file             : $(MULTISTRAP_IMAGE_TAR)
Root fs directory        : $(MULTISTRAP_ROOT_DIR)
Hooks directory          : $(MULTISTRAP_HOOK_DIR)
Architecture             : $(DEBIAN_ARCH)
$(if $(MULTISTRAP_ARGS),Additional arguments passed to multistrap:
$(MULTISTRAP_ARGS),No extra arguments for multistrap)
$(if $(INCLUDE_HOOKS),The following hooks will be exposed to multistrap:
$(INCLUDE_HOOKS),No hook scripts will be called by multistrap)

Debian repositories will be configured for the following architectures:
Native arch              : $(DEBIAN_ARCH)
Multiarch                : $(DEBIAN_MULTIARCH)

================================== DEFAULT ===================================

The following 'default' repositories are included in multistrap:
stable                   : $(have_stable)
testing                  : $(have_testing)
testing security updates : $(have_testing_security)
testing backports        : $(have_testing_updates)
unstable (sid)           : $(have_unstable)

$(if $(debian_default_valid),Additional Debian packages may be installed:
From distribution        : $(patsubst debian-%.conf,%,$(notdir $(DEBIAN_DEFAULT_REPO)))
Packages to install:
$(DEBIAN_PACKAGES)
,No additional Debian packages will be installed by default)

=================================== LOCAL ====================================
$(if $(INCLUDE_REPOS),
The following local repository configurations are included in multistrap:
$(INCLUDE_REPOS),
No local repositories included in multistrap)
endef

#
# Define a canned recipe to separate buildinfo output from 'build' output.
# Use with $(info ...)
#
override define BUILD_SEPARATOR
==============================================================================

---------------------------- Starting the build ------------------------------

endef

override define DEFINE_CAT_SECTION_FN
cat_section () \
{ \
	echo "[$$2]"; \
	if [ "$$2" = "$(DEBIAN_DEFAULT_REPO)" ]; \
	then \
		echo "packages = $(DEBIAN_PACKAGES)"; \
	else \
		if [ "$$3" = "default" ]; \
		then \
			echo "packages ="; \
		fi; \
	fi; \
	cat "$$1"; \
	echo ""; \
};
endef

override define RUN_MULTISTRAP
$(info Generate rootfs (multistrap))
run_multistrap () \
{ \
	cd "$(BUILDDIR)"; \
	multistrap -f $(MULTISTRAP_CFG); \
}; run_multistrap;
@echo ""
endef

override define CALL_CAT_SECTION_DEFAULT
$(DEFINE_CAT_SECTION_FN) \
cat_section "$@" "$(patsubst $(BUILDDIR)/%,%,$@)" "default" | tee -a "$(MULTISTRAP_CFG)";
@echo ""
endef

override define CALL_CAT_SECTION_LOCAL
$(DEFINE_CAT_SECTION_FN) \
cat_section "$@" "$(patsubst $(BUILDDIR)/%,%,$@)" "local" | tee -a "$(MULTISTRAP_CFG)";
@echo ""
endef

override INIT_DIRS = $(REPOSITORY_DIR)/defaults $(MULTISTRAP_HOOK_DIR) $(MULTISTRAP_ROOT_DIR)

override define CREATE_BUILD_DIR
$(info Create directory: $@)
mkdir -p "$@"
@echo ""
endef

override define INSTALL_REPO_FILE
$(info Including repository: $<")
install -m 0644 -T "$<" "$@"
@echo ""
endef

override define INSTALL_HOOK_SCRIPT
$(info Including hook script: $<")
install -m 0755 -T "$<" "$@"
@echo ""
endef

override define clean_files_left_info
Leave the following files:
$(wildcard $(BUILDDIR)/*)

endef

override define remove_build_files
$(info Remove build output in: $(BUILDDIR))
rm -rf "$(REPOSITORY_DIR)" "$(MULTISTRAP_ROOT_DIR)" "$(MULTISTRAP_HOOK_DIR)"
rm -f "$(MULTISTRAP_CFG)" "$(STAMP_FILE)" "$(MULTISTRAP_IMAGE_TAR)"
endef

override define rm_builddir
$(info Remove build directory: $(BUILDDIR))
rmdir "$(BUILDDIR)"
endef

override define remove_builddir
$(if $(wildcard $(BUILDDIR)/*),$(info $(clean_files_left_info)),$(rm_builddir))
endef

help:
	$(info $(BUILD_HELP))
	@echo ""

buildinfo:
	$(info $(BUILD_INFO))
	@echo ""

$(STAMP_FILE): | $(INIT_DIRS)
	$(info Generate build timestamp file)
	touch "$(STAMP_FILE)"
	@echo ""

$(MULTISTRAP_CFG): | $(STAMP_FILE)
	$(info Generate $(MULTISTRAP_CFG))
	echo $(subst \n ,\n,$(MULTISTRAP_GENERAL_SECTION)) | tee $(MULTISTRAP_CFG)

$(BUILDDIR)/hooks/%: $(INCLUDE_HOOKS)
	$(INSTALL_HOOK_SCRIPT)

$(BUILDDIR)/repos/%.conf: $(INCLUDE_REPOS) | $(MULTISTRAP_CFG)
	$(INSTALL_REPO_FILE)
	$(CALL_CAT_SECTION_LOCAL)

$(BUILDDIR)/repos/defaults/%.conf: $(current_mkfile_dir)/repos/%.conf | $(MULTISTRAP_CFG)
	$(INSTALL_REPO_FILE)
	$(CALL_CAT_SECTION_DEFAULT)

$(BUILDDIR)/%: |
	$(CREATE_BUILD_DIR)

$(MULTISTRAP_IMAGE_TAR): | configure $(CONFIG_HOOKS)
	$(RUN_MULTISTRAP)

configure: | buildinfo -separator $(MULTISTRAP_CFG) $(CONFIG_REPOS)

build: | buildinfo -separator $(MULTISTRAP_IMAGE_TAR)

reconfigure: | buildinfo -separator clean configure
rebuild: | reconfigure build

-remove-build-files:
	$(check_builddir_error)
	$(if $(wildcard $(BUILDDIR)),$(remove_build_files),$(info Build directory does not exist: "$(BUILDDIR)"))
	@echo "" # silence a warning about 'nothing to be done' when clean has nothing to do.

clean: | -remove-build-files
	$(if $(wildcard $(BUILDDIR)),$(remove_builddir),)

# used to print an indicator that an actual build started, and build output will follow in Makefile output
-separator:
	$(info $(BUILD_SEPARATOR))
	$(check_builddir_error)
	$(if $(strip $(CONFIG_REPOS)),,$(error $(empty_config_repos_error)))

.PHONY: configure build update clean -separator -remove-build-files help buildinfo reconfigure rebuild
