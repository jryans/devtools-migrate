#!/bin/bash

# Uses "replace" from npm.

set -ex

SCRIPT_DIR=$(dirname $0)

hg mv browser/devtools devtools/client
hg mv toolkit/devtools/server devtools/server
hg mv toolkit/devtools devtools/shared

hg commit -m "Bug 912121 - Migrate major DevTools directories. r=ochameau"

hg mv devtools/client/.eslintrc* devtools
hg rm devtools/shared/.eslintrc

replace '\"../../.eslintrc.mochitests\"' '"../../../.eslintrc.mochitests"' -r devtools
replace '\"../../../../../browser/devtools/.eslintrc.mochitests\"' '"../../../.eslintrc.xpcshell"' -r devtools/server
replace '\"../../../.eslintrc.xpcshell\"' '"../../../../.eslintrc.xpcshell"' -r devtools/client
replace '\"../../../../../browser/devtools/.eslintrc.xpcshell\"' '"../../../.eslintrc.xpcshell"' -r devtools/server
replace '\"../../../../browser/devtools/.eslintrc.xpcshell\"' '"../../../.eslintrc.xpcshell"' -r devtools/shared

hg mv devtools/client/.eslintignore devtools
echo "" >> devtools/.eslintignore
cat devtools/shared/.eslintignore >> devtools/.eslintignore
hg rm devtools/shared/.eslintignore
replace browser/devtools/ client/ devtools/.eslintignore
replace toolkit/devtools/ shared/ devtools/.eslintignore

# TODO: Search for comments

hg commit -m "Bug 912121 - Adjust ESLint files. r=pbrosset"

# hg export -o %m.patch
hg import ${SCRIPT_DIR}/Bug_912121___Adjust_build_configs_and_test_manifests__r_glandium_ochameau.patch

${SCRIPT_DIR}/rewrite-chrome.py
gsed -i -e 's/browser.jar/devtools.jar/' devtools/client/jar.mn
gsed -i -e '/devtools.jar/a%   content devtools %content/' devtools/client/jar.mn
# TODO: webide jar.mn?
hg commit -m "Bug 912121 - Package DevTools client content in devtools.jar

Break DevTools content files out of browser.jar and move to a new DevTools
specific jar.  Update all paths of the form:

chrome://browser/content/devtools/<X>

to

chrome://devtools/content/<Y>

where <Y> is the source tree path that comes after /devtools/client."

hg import ${SCRIPT_DIR}/Bug_912121___Clean_up_relative_chrome____URLs_in_some_tools__r_ochameau.patch

hg import ${SCRIPT_DIR}/Bug_912121___Define_DevToolsModules_template_for_installing_JS_modules__r_glandium_ochameau.patch

${SCRIPT_DIR}/rewrite-require.py
hg commit -m "Bug 912121 - Rewrite require / import to match source tree. r=ochameau

In a following patch, all DevTools moz.build files will use DevToolsModules to
install JS modules at a path that corresponds directly to their source tree
location.  Here we rewrite all require and import calls to match the new
location that these files are installed to."

hg import ${SCRIPT_DIR}/Bug_912121___require___in_workers_should_stay_as_resource_____r_ochameau.patch

hg import ${SCRIPT_DIR}/Bug_912121___Only_one_JS_modules_section_per_moz_build__r_ochameau.patch

find devtools -name moz.build | xargs -L 1 perl -0777 -pi -e "s/EXTRA_JS_MODULES[\w. +=\[\]\"'-]*\[\n(.*?)\]/DevToolsModules(\n\1)/gs"

# Revert changes to libs from external repos
hg revert -C devtools/shared/gcli/moz.build
hg revert -C devtools/shared/acorn/moz.build
hg revert -C devtools/shared/tern/moz.build
hg revert -C devtools/shared/sourcemap/moz.build

hg commit -m "Bug 912121 - Use DevToolsModules in devtools moz.build. r=ochameau

This step finally installs all DevTools JS modules at a path that corresponds
directly to their source tree location."

hg import ${SCRIPT_DIR}/Bug_912121___Correct_GCLI_JSM_install_location__r_ochameau.patch
hg import ${SCRIPT_DIR}/Bug_912121___Update_GCLI_command_paths__r_ochameau.patch

hg import ${SCRIPT_DIR}/Bug_912121___Remove_dead_loader_paths__r_ochameau.patch
