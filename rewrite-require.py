#!/usr/bin/env python3

import os
import re

source_to_resource = dict()

def parse_moz_build(path):
    print("Reading %s" % path)
    is_client = path.split("/")[1] == "client"
    module_base = None
    with open(path, 'r') as file:
        for line in file:
            if line.startswith("EXTRA_JS_MODULES"):
                # Replace ["foo"] with .foo
                module_base = re.sub(r"\[['\"]([\w-]+?)['\"]\]", r".\1", line)
                # Convert to resource://
                module_base = re.search(r"EXTRA_JS_MODULES(.*) \+= \[", module_base).group(1)
                module_base = module_base.replace(".", "/")
                if is_client:
                    module_base = "resource:///modules" + module_base
                else:
                    module_base = "resource://gre/modules" + module_base
            elif line == "]\n":
                module_base = None
            elif module_base is not None:
                # print("Line: %s, Base: %s" % (line, module_base))
                relative_source = re.search(r"[\"'](.*)[\"']", line).group(1)
                # Record mapping of source path to resource path
                source = os.path.join(os.path.dirname(path), relative_source)
                resource = module_base + "/" + os.path.basename(source)
                source_to_resource[source] = resource
                print("%s -> %s" % (source, resource))

for root, dirs, files in os.walk("devtools"):
    for file in files:
        if file == "moz.build":
            parse_moz_build(os.path.join(root, file))
