#!/bin/bash

# This script will perform a complete migration of DevTools code over to the
# new layout and paths described in the README.md.

# To use this script, you will need:
#   * a Mercurial checkout
#   * replace from npm
#   * Python 3
#   * GNU sed (OS X default sed is not enough)

set -ex

SCRIPT_DIR=$(dirname $0)

# *** MOVE FILES ***
hg mv browser/devtools devtools/client
hg mv toolkit/devtools/server devtools/server
hg mv toolkit/devtools devtools/shared

hg commit -m "Bug 912121 - Migrate major DevTools directories. rs=devtools

Move major DevTools files to new directories using the following steps:

hg mv browser/devtools devtools/client
hg mv toolkit/devtools/server devtools/server
hg mv toolkit/devtools devtools/shared

No other changes are made."

# *** ESLINT ***
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

hg commit -m "Bug 912121 - Adjust ESLint files. r=pbrosset

Move ESList files up to /devtools to represent the entire DevTools tree.

Various relative paths and ignore files are also updated."

# *** BUILD CONFIG / TEST MANIFESTS ***
# hg export -o %m.patch
hg import ${SCRIPT_DIR}/Bug_912121___Adjust_build_configs_and_test_manifests__r_glandium.patch

# *** CHROME CONTENT ***
${SCRIPT_DIR}/rewrite-chrome-content.py
gsed -i -e 's/browser.jar/devtools.jar/' devtools/client/jar.mn
gsed -i -e '/devtools.jar/a%   content devtools %content/' devtools/client/jar.mn
hg commit -m "Bug 912121 - Package DevTools client content in devtools.jar. rs=devtools

Break DevTools content files out of browser.jar and move to a new DevTools
specific jar.  Update all paths of the form:

chrome://browser/content/devtools/<X>

to

chrome://devtools/content/<Y>

where <Y> is the source tree path that comes after /devtools/client."

hg import ${SCRIPT_DIR}/Bug_912121___Package_DevTools_with_browser__rs_devtools.patch
hg import ${SCRIPT_DIR}/Bug_912121___Clean_up_relative_chrome____URLs_in_some_tools__rs_devtools.patch
hg import ${SCRIPT_DIR}/Bug_912121___Clean_up_misc__chrome_content_uses__rs_devtools.patch

# *** REQUIRE / JS MODULES ***
hg import ${SCRIPT_DIR}/Bug_912121___Define_DevToolsModules_template_for_installing_JS_modules__r_glandium.patch

${SCRIPT_DIR}/rewrite-require.py
hg commit -m "Bug 912121 - Rewrite require / import to match source tree. rs=devtools

In a following patch, all DevTools moz.build files will use DevToolsModules to
install JS modules at a path that corresponds directly to their source tree
location.  Here we rewrite all require and import calls to match the new
location that these files are installed to."

hg import ${SCRIPT_DIR}/Bug_912121___Rewrite_URLs_outside_call_sites__rs_devtools.patch

hg import ${SCRIPT_DIR}/Bug_912121___Only_one_JS_modules_section_per_moz_build__rs_devtools.patch

find devtools -name moz.build | xargs -L 1 perl -0777 -pi -e "s/EXTRA_JS_MODULES[\w. +=\[\]\"'-]*\[\n(.*?)\]/DevToolsModules(\n\1)/gs"

# Revert changes to libs from external repos
hg revert -C devtools/shared/gcli/moz.build
hg revert -C devtools/shared/acorn/moz.build
hg revert -C devtools/shared/tern/moz.build
hg revert -C devtools/shared/sourcemap/moz.build

hg commit -m "Bug 912121 - Use DevToolsModules in devtools moz.build. rs=devtools

This step finally installs all DevTools JS modules at a path that corresponds
directly to their source tree location."

hg import ${SCRIPT_DIR}/Bug_912121___Repair_react_dev_build_with_DevToolsModules__rs_devtools.patch
hg import ${SCRIPT_DIR}/Bug_912121___Correct_GCLI_JSM_install_location__rs_devtools.patch
hg import ${SCRIPT_DIR}/Bug_912121___Update_GCLI_command_paths__rs_devtools.patch

# *** LOADER PATHS ***
hg import ${SCRIPT_DIR}/Bug_912121___Remove_dead_loader_paths__rs_devtools.patch
hg import ${SCRIPT_DIR}/Bug_912121___Update_srcdir_manifest_paths_in_loader__r_ochameau.patch

# *** THEMES / CHROME SKIN ***
hg import ${SCRIPT_DIR}/Bug_912121___Move_straggler_images_next_to_other_DevTools_images__rs_devtools.patch

hg mv browser/themes/shared/devtools devtools/client/themes

hg commit -m "Bug 912121 - Migrate DevTools themes. rs=devtools

Move DevTools themes to a new directory using the following step:

hg mv browser/themes/shared/devtools devtools/client/themes

No other changes are made."

${SCRIPT_DIR}/rewrite-chrome-skin.py
gsed -i -e '/devtools/d' browser/themes/shared/jar.inc.mn
replace ../shared/devtools/ ../../../devtools/client/themes/ -r browser
replace ' ../../shared/devtools/' ' ' -r devtools/client/themes

hg commit -m "Bug 912121 - Package DevTools client themes in devtools.jar. rs=devtools

Break DevTools theme files out of browser.jar and move to a new DevTools
specific jar.  Update all paths of the form:

chrome://browser/skin/devtools/<X>

to

chrome://devtools/skin/<Y>

where <Y> is the source tree path that comes after /devtools/client."

hg import ${SCRIPT_DIR}/Bug_912121___Clean_up_misc__theme_uses__rs_devtools.patch

# *** TEST PATHS / COMMENTS ***
replace browser/devtools devtools/client -r . --exclude=obj-*
hg revert -C browser/locales/jar.mn
replace toolkit/devtools/server devtools/server -r . --exclude=obj-*
replace toolkit/devtools devtools/shared -r . --exclude=obj-*
replace chrome/toolkit/ chrome/ -r devtools
replace browser/themes/shared/devtools/ devtools/client/themes/ -r devtools/client

hg commit -m "Bug 912121 - Update misc. DevTools paths and comments. rs=devtools"

# *** ADD-ON COMPAT ***

hg import ${SCRIPT_DIR}/Bug_912121___Create_shims_for_popular_DevTools_modules_in_add_ons__rs_devtools.patch
hg import ${SCRIPT_DIR}/Bug_912121___Create_shims_for_popular_DevTools_themes_in_add_ons__rs_devtools.patch

# *** TESTS ***

hg import ${SCRIPT_DIR}/Bug_912121___Misc__DevTools_test_fixes_after_migration__rs_devtools.patch
