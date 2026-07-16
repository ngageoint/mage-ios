#!/bin/bash

#
#  set_build_number.sh
#  MAGE
#

BUILD_NUMBER=$(expr $(git rev-list main --count) - $(git rev-list HEAD..main --count))
echo "Updating build number to $BUILD_NUMBER."

APP_INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
DSYM_INFO_PLIST="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_INFO_PLIST"
if [ -f "$DSYM_INFO_PLIST" ] ; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$DSYM_INFO_PLIST"
fi
