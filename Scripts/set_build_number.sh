#!/bin/bash

#
#  set_build_number.sh
#  MAGE
#

BRANCH=${1:-'master'}
BUILD_NUMBER=$(expr $(git rev-list $BRANCH --count) - $(git rev-list HEAD..$BRANCH --count))
echo "Updating build number to $BUILD_NUMBER using branch '$BRANCH'."

APP_INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
DSYM_INFO_PLIST="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_INFO_PLIST"
if [ -f "$DSYM_INFO_PLIST" ] ; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$DSYM_INFO_PLIST"
fi
