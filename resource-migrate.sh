#!/bin/bash

set -ex

SCRIPT_DIR=$(dirname $0)

replace 'resource://gre/modules/devtools' 'resource://devtools' --exclude='obj-*'
replace 'resource:///modules/devtools' 'resource://devtools' --exclude='obj-*'

git ci -am "Bug 1203159 - Rewrite DevTools resource URLs. r=ochameau"
