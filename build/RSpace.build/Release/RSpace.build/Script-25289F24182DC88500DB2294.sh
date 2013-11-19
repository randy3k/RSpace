#!/bin/sh
BUILD_NUMBER=$(printf "%04d" `git rev-list HEAD | wc -l | tr -d ' '`)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "${TARGET_BUILD_DIR}"/"${INFOPLIST_PATH}"
