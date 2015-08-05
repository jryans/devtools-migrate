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

# hg export -o %m.patch
hg import Bug_912121___Adjust_build_configs_and_test_manifests__r_glandium_bgrins.patch

gsed -i -e 's/browser.jar/devtools.jar/' devtools/client/jar.mn
gsed -i -e '/devtools.jar/a%   content devtools %content/' devtools/client/jar.mn
replace 'content/browser/devtools/' 'content/' devtools/client/jar.mn
replace 'chrome://browser/content/devtools/' 'chrome://devtools/content/' -r browser devtools
hg commit -m "Bug 912121 - Package DevTools client content in devtools.jar

Break DevTools content files out of browser.jar and move to a new DevTools
specific jar.  Update all paths of the form:

chrome://browser/content/devtools/

to

chrome://devtools/content/"
