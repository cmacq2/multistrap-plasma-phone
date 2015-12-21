#!/usr/bin/sed -f
###############################################
##
## Meta-info of the repository
##
s:@CODENAME@:$REPO_CODE_NAME:
s:@VERSION@:$REPO_VERSION:
s:@DOMAIN@:$REPO_DOMAIN_NAME:
s:@ARCH@:$DEBIAN_ARCH:
s:@SUITE@:$DEBIAN_SUITE:
#
# repokey should be something that maps to a
# unique value as reported by e.g.:
# gpg −−list−secret−keys
#
# Alternatively: use 'yes' or 'default' to pick
# the default signing key from your key ring.
#
s:@REPOKEY@:$REPO_KEY:
###############################################
##
##
s:@AUTO_GROUP_ID@:$AUTO_GROUP_ID:
###############################################
##
## Repo directory layout on the reprepro host.
##
##
s:@INCOMING@:$INCOMING_DIR:
s:@TEMP@:$TEMP_DIR:
s:@BASEDIR@:$BASE_DIR:
s:@CONF@:$CONF_DIR:
s:@POOL@:$POOL_DIR:
s:@LOG@:$LODG_DIR:
s:@LISTS@:$LIST_DIR:
s:@DB@:$DB_DIR: