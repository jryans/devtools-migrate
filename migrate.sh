#!/bin/bash

# Uses "replace" from npm.

set -ex

hg mv browser/devtools devtools/client
hg mv toolkit/devtools/server devtools/server
hg mv toolkit/devtools devtools/shared

hg commit -m "Bug 912121 - Migrate major DevTools directories. r=bgrins"

hg mv devtools/client/.eslintrc* devtools
hg rm devtools/shared/.eslintrc

replace '\"../../.eslintrc.mochitests\"' '"../../../.eslintrc.mochitests"' -r devtools
replace '\"../../../../../browser/devtools/.eslintrc.mochitests\"' '"../../../.eslintrc.xpcshell"' -r devtools/server
replace '\"../../../.eslintrc.xpcshell\"' '"../../../../.eslintrc.xpcshell"' -r devtools/client
replace '\"../../../../../browser/devtools/.eslintrc.xpcshell\"' '"../../../.eslintrc.xpcshell"' -r devtools/server
replace '\"../../../../browser/devtools/.eslintrc.xpcshell\"' '"../../../.eslintrc.xpcshell"' -r devtools/shared

hg commit -m "Bug 912121 - Adjust ESLint files. r=bgrins"

hg import Bug_912121___Adjust_build_configs_and_test_manifests__r_glandium_bgrins.patch
