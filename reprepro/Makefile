#
# Makefile to synthesise reprepro configuration from various template configuration files
# and then build the resulting Debian repository.
#

#
# For future reference: determine current makefile path and directory.
#
override current_mkfile_path = $(abspath $(lastword $(MAKEFILE_LIST)))
override current_mkfile_dir = $(patsubst %/,%,$(dir $(current_mkfile_path)))

HELP_DESCRIPTION ?= generates Debian repository using reprepro

#
# Define a canned recipe that lists the build help. Use with $(info ...)
#
override define BUILD_HELP
$(notdir $(current_mkfile_path)) : $(HELP_DESCRIPTION)
Usage:
make -f '$(current_mkfile_path)' \
        <target> [VARIABLES]

The following (explicit) targets are useful:

build                    : build/update a Debian repository
buildinfo                : print values of configurable VARIABLES.
clean                    : delete build directory (BUILDDIR)
configure                : generate multistrap configuration file.
help                     : display this 'help' text.
rebuild                  : update (clean and redo) a previous 'build'.
reconfigure              : update (clean and redo) a previous 'configure'.

The following paths may be set to customise the build:

SRCDIR                   : 'source' directory for locally provided
                           configuration files and scripts.
                           This directory must exist, the default is the
                           directory from which Make was invoked.
BUILDDIR                 : directory to place build artefacts. It will be
                           created if it does not exist, the default is
                           to use a 'build' subdirectory in SRCDIR.

The following variables can be used to customise output:

REPO_CODE_NAME           : set the 'code name' of the distribution.
                           All instances of @CODENAME@ in configuration
                           templates will be replaced by this value.
REPO_VERSION             : set the 'version' string of the repository.
                           All instances of @VERSION@ in configuration
                           templates will be replaced by this value.
REPO_DOMAIN_NAME         : set the 'origin' domain of the repository.
                           All instances of @DOMAIN@ in configuration
                           templates will be replaced by this value.
REPO_KEY                 : specify the key to use for signing the repository.
                           All instances of @REPOKEY@ in configuration
                           templates will be replaced by this value.
DEBIAN_ARCH              : specify binary architecture of the repository.
                           All instances of @ARCH@ in configuration
                           templates will be replaced by this value.
UPLOAD_KEYS              : specify a list of signing keys which will be
                           accepted for 'uploads' by default. Multiple keys
                           should be separated using spaces.

Additionally the generated directory structure may be customised using:

BASE_DIR                 : specify a value for the reprepro 'basedir' option.
                           All instances of @BASEDIR@ in configuration
                           templates will be replaced by this value.
POOL_DIR                 : specify a value for the reprepro 'outdir' option.
                           All instances of @POOL@ in configuration
                           templates will be replaced by this value.
DB_DIR                   : specify a value for the reprepro 'dbdir' option.
                           All instances of @DB@ in configuration
                           templates will be replaced by this value.
INCOMING_DIR             : specify the directory which contains the queued
                           'incoming' packages for reprepro to process.
                           All instances of @INCOMING@ in configuration
                           templates will be replaced by this value.
TEMP_DIR                 : specify the 'temporary'/work directory for reprepro
                           to use while processing 'incoming' packages.
                           All instances of @TEMP@ in configuration
                           templates will be replaced by this value.
LIST_DIR                 : specify a value for the reprepro 'listdir' option.
                           All instances of @LISTS@ in configuration
                           templates will be replaced by this value.
LOG_DIR                  : specify a value for the reprepro 'logdir' option.
                           All instances of @LOG@ in configuration
                           templates will be replaced by this value.
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

override positives = yes y 1 true on enabled enable
override negatives = no n 0 false off disabled disable

REPO_CODE_NAME ?= sparkly
REPO_VERSION ?= 1.0
REPO_DOMAIN_NAME ?= $(shell hostname -f)
REPO_KEY ?= default
UPLOAD_KEYS ?= default
DEBIAN_ARCH ?=


DB_DIR ?=
LIST_DIR ?=
LOG_DIR  ?=
POOL_DIR ?=
BASE_DIR ?=
INCOMING_DIR ?=
TEMP_DIR ?=

override BUILD_ROOT:= $(BUILDDIR)/reprepro

override DB_DIR := $(if $(strip $(DBDIR)),$(DBDIR),$(BUILD_ROOT)/db)
override LIST_DIR := $(if $(strip $(LISTDIR)),$(LISTDIR),$(BUILD_ROOT)/lists)
override LOG_DIR := $(if $(strip $(LOGDIR)),$(LOGDIR),$(BUILD_ROOT)/log)
override POOL_DIR := $(if $(strip $(POOLDIR)),$(POOLDIR),$(BUILD_ROOT)/pool)
override BASE_DIR := $(if $(strip $(BASEDIR)),$(BASEDIR),$(BUILD_ROOT))
override INCOMING_DIR := $(if $(strip $(INCOMING_DIR)),$(INCOMING_DIR),$(BUILD_ROOT)/incoming)
override TEMP_DIR := $(if $(strip $(TEMP_DIR)),$(TEMP_DIR),$(BUILD_ROOT)/temp)
override CONF_DIR := $(BUILD_ROOT)/conf

override STAMP_FILE = $(BUILD_ROOT)/build.stamp
override UPDATE_STAMP_FILE=$(BUILD_ROOT)/update.stamp

override INCLUDE_SRCS = $(abspath $(wildcard $(SRCDIR)/*))
override CONFIG_FILES = $(patsubst $(abspath $(SRCDIR))/%.in,$(CONF_DIR)/%,$(INCLUDE_SRCS))
override INCOMING_CHANGES= $(abspath $(wildcard $(INCOMING_DIR)/*.changes))

#
# Check that BUILDDIR setting will not clobber sources.
#
override define builddir_error
Ignore invalid build directory: "$(BUILDDIR)"
Build directory collides with sources
endef

override BUILDFILE_PATTERNS = $(BUILD_ROOT)/%
#override BUILDFILE_PATTERNS = $(REPOSITORY_DIR)/% $(MULTISTRAP_HOOK_DIR)/% $(MULTISTRAP_ROOT_DIR)/% $(MULTISTRAP_CFG) $(STAMP_FILE)

override define check_builddir_error
$(if $(filter $(BUILDFILE_PATTERNS),$(INCLUDE_SRCS)),$(error $(builddir_error)),)
endef

override define no_incoming_file_warning
Source directory does not contain a 'incoming' config file.
Missing: $(SRCDIR)/incoming.in
endef

override define no_distro_file_error
Source directory does not contain a 'distributions' config file.
Missing: $(SRCDIR)/distributions.in
endef

override define check_incoming_file_warning
$(if $(wildcard $(SRCDIR)/incoming.in),,$(warning $(no_incoming_file_warning)))
endef

override define check_distro_file_error
$(if $(wildcard $(SRCDIR)/distributions.in),,$(error $(no_distro_file_error)))
endef

#
# Define a canned recipe that lists the buildinfo. Use with $(info ...)
#
override define BUILD_INFO
================================= BUILD PATHS ================================

Makefile                 : $(current_mkfile_path)
Makefile directory       : $(current_mkfile_dir)
Source directory         : $(SRCDIR)
Build directory          : $(BUILDDIR)
Using build root         : $(BUILD_ROOT)
Destination directory    : $(DESTDIR)

================================== REPREPRO ==================================

Code name                : $(REPO_CODE_NAME)
Version                  : $(REPO_VERSION)
Domain name              : $(REPO_DOMAIN_NAME)
Repository signing key   : $(REPO_KEY)
Repository architecture  : $(DEBIAN_ARCH)

Additional directory layout information:

Base directory           : $(BASE_DIR)
Configuration            : $(CONF_DIR)

db                       : $(DB_DIR)
pool                     : $(POOL_DIR)
lists                    : $(LIST_DIR)

Incoming Queue:

incoming                 : $(INCOMING_DIR)
temp (work) directory    : $(TEMP_DIR)

Log files                : $(LOG_DIR)

$(if $(UPLOAD_KEYS),
The following keys will be automatically configured as allowed uploaders:
$(UPLOAD_KEYS),
No keys will be automatically configured as allowed uploaders)
endef

#
# Define a canned recipe to separate buildinfo output from 'build' output.
# Use with $(info ...)
#
override define BUILD_SEPARATOR
==============================================================================

---------------------------- Starting the build ------------------------------

endef

override define DEFINE_REPO_CONFIG_VARS
BASE_DIR="$(BASE_DIR)"; \
CONF_DIR="$(CONF_DIR)"; \
LOG_DIR="$(LOG_DIR)"; \
INCOMING_DIR="$(INCOMING_DIR)"; \
POOL_DIR="$(POOL_DIR)"; \
DB_DIR="$(DB_DIR)"; \
LIST_DIR="$(LIST_DIR)"; \
TEMP_DIR="$(TEMP_DIR)"; \
AUTO_GROUP_ID="AUTO_GROUP_ID"; \
REPO_CODE_NAME="$(REPO_CODE_NAME)"; \
REPO_DOMAIN_NAME="$(REPO_DOMAIN_NAME)"; \
REPO_KEY="$(REPO_KEY)"; \
REPO_VERSION="$(REPO_VERSION)"; \
DEBIAN_ARCH="$(DEBIAN_ARCH)";
endef

override define DEFINE_CONFIGURE_UPLOADERS
cat_uploader_auto_group () \
{ \
	$(DEFINE_REPO_CONFIG_VARS) \
	keys="$(UPLOAD_KEYS)"; \
	if [ -n "$$keys" ]; \
	then \
		for k in $$keys; \
		do \
			echo "group $$AUTO_GROUP_ID add key $$k"; \
		done; \
	fi; \
	cat "$$1" | sed -f "$(abspath $(current_mkfile_path)/configure.sed)"; \
};
endef

override define DEFINE_CONFIGURE_FILE
cat_config_file () \
{ \
	$(DEFINE_REPO_CONFIG_VARS) \
	cat "$$1" | sed -f "$(abspath $(current_mkfile_path)/configure.sed)"; \
};
endef

override define CALL_CONFIGURE_UPLOADERS
$(DEFINE_CONFIGURE_UPLOADERS) \
cat_uploader_auto_group "$<" | tee "$@";
@echo ""
endef

override define CALL_CONFIGURE_FILE
$(DEFINE_CONFIGURE_UPLOADERS) \
cat_config_file "$<" | tee "$@";
@echo ""
endef

override INIT_DIRS = $(BUILD_ROOT) $(BASE_DIR) $(CONF_DIR) $(DB_DIR) $(TEMP_DIR) $(INCOMING_DIR) $(POOL_DIR) $(LOG_DIR)

override define CREATE_BUILD_DIR
$(info Create directory: $@)
mkdir -p "$@"
@echo ""
endef

override define clean_files_left_info
Leave the following files:
$(wildcard $(BUILDDIR)/*)
endef

override define remove_build_files
$(info Remove build output in: $(BUILDDIR))
rm -rf "$(BUILD_ROOT)"
#rm -rf "$(REPOSITORY_DIR)" "$(MULTISTRAP_ROOT_DIR)" "$(MULTISTRAP_HOOK_DIR)"
#rm -f "$(MULTISTRAP_CFG)" "$(STAMP_FILE)" "$(MULTISTRAP_IMAGE_TAR)"
@echo ""
endef

override define rm_builddir
$(info Remove build directory: $(BUILDDIR))
rmdir "$(BUILDDIR)"
@echo ""
endef

override define remove_builddir
$(if $(wildcard $(BUILDDIR)/*),$(info $(clean_files_left_info)),$(rm_builddir))
endef

override define process_updates
reprepro --confdir "$(CONF_DIR)" --basedir "$(BASE_DIR)" \
         --dbdir "$(DB_DIR)" --outdir "$(POOL_DIR)" --distdir "$(POOL_DIR)/dists" \
         --listdir "$(LISTDIR)" --logdir "$(LOG_DIR)" \
         processincoming
endef

help: |
	$(info $(BUILD_HELP))
	@: # silence a warning about 'nothing to be done'

buildinfo: |
	$(info $(BUILD_INFO))
	@: # silence a warning about 'nothing to be done'

$(STAMP_FILE): | $(INIT_DIRS)
	$(info Generate build timestamp file)
	touch "$(STAMP_FILE)"

$(CONF_DIR)/%: $(SRCDIR)/%.in | $(STAMP_FILE)
	$(info Generate: $@)
	$(CALL_CONFIGURE_FILE)

$(CONF_DIR)/uploaders: $(SRCDIR)/uploaders.in | $(STAMP_FILE)
	$(info Generate: $@)
	$(CALL_CONFIGURE_UPLOADERS)

$(BUILD_ROOT)/%: |
	$(CREATE_BUILD_DIR)

$(UPDATE_STAMP_FILE): $(INCOMING_CHANGES) | configure
	$(if $(wildcard $(SRCDIR)/incoming.in),$(process_updates),)
	touch "$(UPDATE_STAMP_FILE)"

configure: | buildinfo -separator $(CONFIG_FILES)
	@: # silence a warning about 'nothing to be done' when there is nothing to do.

build: | buildinfo -separator $(UPDATE_STAMP_FILE)
	@: # silence a warning about 'nothing to be done' when there is nothing to do.

reconfigure: | buildinfo -separator clean configure
	@: # silence a warning about 'nothing to be done' when there is nothing to do.

rebuild: | reconfigure build
	@: # silence a warning about 'nothing to be done' when there is nothing to do.

-remove-build-files: |
	$(check_builddir_error)
	$(if $(wildcard $(BUILDDIR)),$(remove_build_files),$(info Build directory does not exist: "$(BUILDDIR)"))

clean: | -remove-build-files
	$(if $(wildcard $(BUILDDIR)),$(remove_builddir),)
	@: # silence a warning about 'nothing to be done' when there is nothing to do.

# used to print an indicator that an actual build started, and build output will follow in Makefile output
-separator:
	$(info $(BUILD_SEPARATOR))
	$(check_builddir_error)
	$(check_distro_file_error)
	$(check_incoming_file_warning)

.PHONY: configure build clean -separator -remove-build-files help buildinfo reconfigure rebuild
