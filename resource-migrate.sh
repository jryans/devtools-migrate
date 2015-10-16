#!/bin/bash

set -ex

SCRIPT_DIR=$(dirname $0)

replace 'resource://gre/modules/devtools' 'resource://devtools' --exclude='obj-*'
replace 'resource:///modules/devtools' 'resource://devtools' --exclude='obj-*'

git ci -am "Bug 1203159 - Rewrite DevTools resource URLs. r=ochameau"

replace 'resource://devtools/Console' 'resource://gre/modules/Console' browser/base/content/sanitize.js
replace 'resource://devtools/ViewHelpers.jsm' 'resource://devtools/client/shared/widgets/ViewHelpers.jsm' -r testing/eslint-plugin-mozilla
replace 'resource://devtools/event-emitter.js' 'resource://devtools/shared/event-emitter.js' browser/components/newtab/PlacesProvider.jsm
replace 'resource://devtools/Loader.jsm' 'resource://devtools/shared/Loader.jsm' -r devtools/client
