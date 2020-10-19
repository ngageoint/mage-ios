#!/bin/bash

#
#  set_build_number.sh
#  MAGE
#

BRANCH=${1:-'feeds'}
APP_BUILD_NUMBER=$(expr $(git rev-list $BRANCH --count) - $(git rev-list HEAD..$BRANCH --count))

rm -rf .mage-sdk && mkdir .mage-sdk
git clone -n https://github.com/ngageoint/mage-ios-sdk.git .mage-sdk
git -C .mage-sdk checkout $BRANCH
if [ ! $? -eq 0 ]; then
echo " git clone mage sdk error, with exit status $?"
exit 1
fi

SDK_BUILD_NUMBER=$(expr $(git -C .mage-sdk rev-list $BRANCH --count) - $(git -C .mage-sdk rev-list HEAD..$BRANCH --count))
SDK_BUILD_NUMBER=$(seq -f "%05g" $SDK_BUILD_NUMBER $SDK_BUILD_NUMBER)
rm -rf .mage-sdk

BUILD_NUMBER=${APP_BUILD_NUMBER}${SDK_BUILD_NUMBER}
echo "Updating build number to $BUILD_NUMBER using branch '$BRANCH'."

APP_INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
DSYM_INFO_PLIST="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_INFO_PLIST"
if [ -f "$DSYM_INFO_PLIST" ] ; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$DSYM_INFO_PLIST"
fi
