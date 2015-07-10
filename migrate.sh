#!/bin/bash

set -ex

hg mv browser/devtools devtools/client
hg mv toolkit/devtools/server devtools/server
hg mv toolkit/devtools devtools/shared

hg commit -m "Bug 912121 - Migrate major DevTools directories. r=bgrins"
