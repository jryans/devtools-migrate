#!/usr/bin/env python3

import os
import re
import sys
import fileinput

source_to_chrome = {}
chrome_to_source = {}

def record_source_to_chrome(path):
    print("Reading %s" % path)
    # Use browser.jar as default
    module_name = "browser"
    jar_base = "content/browser/"
    with fileinput.input(path, inplace = True) as file:
        for line in file:
            match = re.match(r"%\s+content\s+(\w+)\s+%([\w/]+)", line)
            if match:
                module_name = match.group(1)
                jar_base = match.group(2)
                print(line, end = "")
                continue
            match = re.match(r"([\s*])\s+(\S+)\s+\((\S+)\)", line)
            if not match:
                print(line, end = "")
                continue
            star = match.group(1)
            # Such as: content/browser/devtools/netmonitor.xul
            jar_path = match.group(2)
            # Such as: netmonitor/netmonitor.xul
            relative_source = match.group(3)
            # Record mapping of source path to chrome path
            source = os.path.join(os.path.dirname(path), relative_source)
            rel_jar_path = jar_path.replace(jar_base, "", 1)
            chrome = "chrome://%s/content/%s" % (module_name, rel_jar_path)
            source_to_chrome[source] = chrome
            chrome_to_source[chrome] = source
            # print("%s -> %s" % (source, chrome))
            # Create replacement entry
            line = "%s   content/%s (%s)" % (star, relative_source, relative_source)
            print(line)

def rewrite_source(path):
    print("Updating %s" % path)
    with open(path, 'r') as file:
        contents = file.read()
        changed = False
        for match in re.finditer(r"[\"'](chrome://[^\"']+?)[\"']", contents):
            current = match.group(0)
            chrome = match.group(1)
            rewritten = rewrite_block(current, chrome, path)
            if rewritten:
                contents = contents.replace(current, rewritten, 1)
                changed = True
        if changed:
            with open(path, 'w') as writable_file:
                writable_file.write(contents)

def rewrite_block(current, chrome, path):
    print("Current: %s" % current)
    print("Chrome: %s" % chrome)
    # Ignore chrome outside of devtools
    if not "devtools" in chrome:
        return None
    try:
        source = chrome_to_source[chrome]
    except KeyError:
        print("WARNING! No mapping for: %s" % chrome)
        return None
    source = source.replace("devtools/client/", "")
    rewritten = current.replace(chrome, "chrome://devtools/content/%s" % source)
    print("Updated: %s" % rewritten)
    return rewritten

# Scan all devtools jar.mn files to record the mapping of paths in the source
# tree to chrome:// URIs.
record_source_to_chrome("devtools/client/jar.mn")

# Visit all files in the tree to update various require and import paths to be
# based on source tree locations instead of arbitrary names
for top in ["browser", "devtools"]:
    for root, dirs, files in os.walk(top):
        for file in files:
            try:
                rewrite_source(os.path.join(root, file))
            except UnicodeDecodeError:
                continue
