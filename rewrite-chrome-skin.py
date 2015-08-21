#!/usr/bin/env python3

import os
import re
import sys
import fileinput

source_to_chrome = {}
chrome_to_source = {}
manifest_entries = []

def record_source_to_chrome(path):
    print("Reading %s" % path)
    # Use browser.jar as default
    module_name = "browser"
    jar_base = "skin/classic/browser/"
    with open(path, "r") as file:
        for line in file:
            if not "devtools" in line:
                continue
            match = re.match(r"([\s*])\s+(\S+)\s+\((\S+)\)", line)
            if not match:
                continue
            star = match.group(1)
            # Such as: skin/classic/browser/devtools/power.svg
            jar_path = match.group(2)
            # Such as: ../shared/devtools/images/power.svg
            relative_source = match.group(3)
            # Record mapping of source path to chrome path
            source = os.path.normpath(os.path.join(os.path.dirname(path), relative_source))
            rel_jar_path = jar_path.replace(jar_base, "", 1)
            chrome = "chrome://%s/skin/%s" % (module_name, rel_jar_path)
            source_to_chrome[source] = chrome
            chrome_to_source[chrome] = source
            print("%s -> %s" % (source, chrome))
            manifest_entries.append((star, jar_path, relative_source))

def rewrite_source(path):
    print("Updating %s" % path)
    with open(path, "r") as file:
        contents = file.read()
        changed = False
        for match in re.finditer(r"[\"'](chrome://[^\"']+?)[\"']", contents):
            current = match.group(0)
            chrome = match.group(1)
            rewritten = rewrite_block(current, chrome, path)
            if rewritten:
                contents = contents.replace(current, rewritten, 1)
                changed = True
        for match in re.finditer(r"url\([\"']?([^\"')#]+?)[\"')#]", contents):
            current = match.group(0)
            chrome = match.group(1)
            rewritten = rewrite_block(current, chrome, path)
            if rewritten:
                contents = contents.replace(current, rewritten, 1)
                changed = True
        if changed:
            with open(path, "w") as writable_file:
                writable_file.write(contents)

def rewrite_block(current, chrome, path, relative = False):
    print("Current: %s" % current)
    print("Chrome: %s" % chrome)
    if relative:
        # Assume it's an image that needs images/ prefix
        if chrome.startswith("images"):
            return None
        rewritten = current.replace(chrome, "images/%s" % chrome)
        print("Updated: %s" % rewritten)
        return rewritten
    # Ignore chrome outside of devtools
    if not "devtools" in chrome:
        return None
    try:
        source = chrome_to_source[chrome]
    except KeyError:
        print("WARNING! No mapping for: %s" % chrome)
        return None
    source = source.replace("browser/themes/shared/devtools/", "")
    rewritten = current.replace(chrome, "chrome://devtools/skin/themes/%s" % source)
    print("Updated: %s" % rewritten)
    return rewritten

def rewrite_css(path):
    print("Updating %s" % path)
    with open(path, "r") as file:
        contents = file.read()
        changed = False
        for match in re.finditer(r"url\([\"']?(?!chrome)([^\"')#]+?)[\"')#]", contents):
            current = match.group(0)
            chrome = match.group(1)
            rewritten = rewrite_block(current, chrome, path, relative = True)
            if rewritten:
                contents = contents.replace(current, rewritten, 1)
                changed = True
        if changed:
            with open(path, "w") as writable_file:
                writable_file.write(contents)

def write_manifest_entries(path):
    print("Writing %s" % path)
    jar_base = "skin/classic/browser/"
    with open(path, "a") as file:
        file.write("%   skin devtools classic/1.0 %skin\n")
        for (star, jar_path, relative_source) in manifest_entries:
            relative_source = relative_source.replace("../shared/devtools/", "themes/")
            file.write("%s   skin/%s (%s)\n" % (star, relative_source, relative_source))

# Scan theme jar.mn files to record the mapping of paths in the source tree to
# chrome:// URIs.
record_source_to_chrome("browser/themes/osx/jar.mn")

# Visit all files in the tree to update various require and import paths to be
# based on source tree locations instead of arbitrary names
for top in ["browser", "devtools"]:
    for root, dirs, files in os.walk(top):
        for file in files:
            try:
                rewrite_source(os.path.join(root, file))
            except UnicodeDecodeError:
                continue

# Visit DevTools CSS only to update relative images
for root, dirs, files in os.walk("devtools/client/themes"):
    for file in files:
        try:
            rewrite_css(os.path.join(root, file))
        except UnicodeDecodeError:
            continue

write_manifest_entries("devtools/client/jar.mn")
