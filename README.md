# Overview

We are moving all DevTools files out of `/browser` and `/toolkit` and into a new
`/devtools` directory.

This page gives an overview of what changes to expect and also how to adapt
patches you may have in progress.

# Changes Made

## Directory Structure

Files will move in the following way:

```
mv browser/devtools               devtools/client
mv toolkit/devtools/server        devtools/server
mv toolkit/devtools               devtools/shared
mv browser/themes/shared/devtools devtools/client/themes
```

This gives the following structure:

* `/devtools/client`: Front end tool UI (only ships with desktop Firefox)
* `/devtools/server`: Back end server and actors
* `/devtools/shared`: Common files used by both the client and server

l10n files have not been moved yet.  This will be done later in [bug
1182722][l10n].  For now, they still exist at:

* `/browser/locales/en-US/chrome/browser/devtools`
* `/toolkit/locales/en-US/chrome/global/devtools`

For the moment this structure has some redundant / silly paths such as
`/devtools/shared/shared`. These issues will be handled in a [follow
up][shared], as they are more manual.

## Building

To build all of DevTools, use:

```
mach build devtools/*
```

or specify some subdirectory, as usual.

Just `devtools` is unfortunately not enough: no products directly include the
entire DevTools tree, so the build system won't understand you.  I'm hopeful we
can improve this in a [follow up][build].

## JS Modules

### Build Config

JS modules are still installed via `moz.build` files.  You should use the new
syntax `DevToolsModules` (added by this migration) instead of
`EXTRA_JS_MODULES`.  Also, this new syntax is a function you call, rather than
an array you append to.  See the example below.

Also, a `moz.build` file using `DevToolsModules` *must* live in the same
directory as the files to be installed.  Don't list files from a subdirectory in
a `moz.build` from a parent directory.

Following these steps ensures that `require` and `resource://` paths map
directly to locations in the source tree, instead of being totally arbitrary.

A few libraries we import have not been updated to follow these rules, pending
further [discussion][libs] about how they should handled.

Example:

* File: `/devtools/server/actors/layout.js`
* In `/devtools/server/actors/moz.build`:

```
# New way, please do this!
DevToolsModules(
    'layout.js'
)

# Old way, don't use this!
EXTRA_JS_MODULES.devtools.server.actors += [
    'layout.js',
]
```

### require()

To `require()` a file, the module ID is exactly its source tree path.

Example:

* File: `/devtools/server/actors/layout.js`
* Usage:
  * `require("devtools/server/actors/layout")`
  * `loader.lazyRequireGetter(this, "layout", "devtools/server/actors/layout")`

### Cu.import()

To `import()` a file, the `resource://` path is derived directly from the source
tree path, but does have the `gre` difference between client and server as
before.  In more detail:

* `/devtools/client/<X>`: `resource:///modules/devtools/client/<X>`
* `/devtools/server/<X>`: `resource://gre/modules/devtools/server/<X>`
* `/devtools/shared/<X>`: `resource://gre/modules/devtools/shared/<X>`

Example:

* File: `/devtools/shared/Loader.jsm`
* Usage:
  * `Cu.import("resource://gre/modules/devtools/shared/Loader.jsm")`

Example:

* File: `/devtools/client/framework/gDevTools.jsm`
* Usage:
  * `Cu.import("resource:///modules/devtools/client/framework/gDevTools.jsm")`
  * `loader.lazyImporter(this, "gDevTools", "resource:///modules/devtools/client/framework/gDevTools.jsm")`

## Chrome Content

### Packaging

There is a new `jar.mn` located at `/devtools/client/jar.mn` for packaging
chrome files.

Please ensure that any new files are added so their entire source tree path is
part of the URL. To do so, the `jar.mn` entry should look like:

```
    content/<X> (<X>)
```

where `<X>` is the path to your file after removing the `/devtools/client`
prefix.

Example:

* File: `/devtools/client/webaudioeditor/models.js`
* Entry: `content/webaudioeditor/models.js (webaudioeditor/models.js)`

### Usage

Chrome content URLs almost match their source tree path, with one difference:
the segment `client` is replaced by `content`.  This is a requirement of the
`chrome://` protocol handler.

Example:

* File: `/devtools/client/webaudioeditor/models.js`
* Usage: `chrome://devtools/content/webaudioeditor/models.js`

For files within a single tool, consider relative URLs.  They're shorter!

## Chrome Themes

This is nearly identical to the previous chrome content section.

### Packaging

There is a new `jar.mn` located at `/devtools/client/jar.mn` for packaging
chrome files.

Please ensure that any new files are added so their entire source tree path is
part of the URL. To do so, the `jar.mn` entry should look like:

```
    skin/<X> (<X>)
```

where `<X>` is the path to your file after removing the `/devtools/client`
prefix.

Example:

* File: `/devtools/client/themes/images/add.svg`
* Entry: `skin/themes/images/add.svg (themes/images/add.svg)`

### Usage

Chrome theme URLs almost match their source tree path, with one difference:
the segment `client` is replaced by `skin`.  This is a requirement of the
`chrome://` protocol handler.

Example:

* File: `/devtools/client/themes/images/add.svg`
* Usage: `chrome://devtools/skin/themes/images/add.svg`

For files within a single tool, consider relative URLs.  They're shorter!

# Updating Your Patches

You have several options for updating any patches you started before the file
move landed.

## Rebase

You should get reasonable results by letting your VCS tool rebase your work
however you normally do this.

I tested a small feature branch using bookmark-style Mercurial development, and
it worked quite well.  There were only a few conflicts to address in expected
places, like import paths.

I would expect bookmark-style Mercurial and Git to work well.  MQ-style
Mercurial may not work as well, as I don't believe it handles the situation as
nicely.  Another reason to stop using it, I suppose.

## Migrate Locally

Another option would be to run the [`migrate.sh`](migrate.sh) script in this
repo on your own feature branch.  You would need to capture the changes by
comparing with the pre-migration file tree.  Doable, but a bit tricky since the
files are moving around.

Read the comments in the script about setup before attempting this.  The script
assumes a Mercurial repo is used.

## Update Manually

If your feature branch is relatively small, it shouldn't be too hard to update
manually, applying all the guidelines described in this file as you go.

[l10n]: https://bugzilla.mozilla.org/show_bug.cgi?id=1182722
[shared]: https://bugzilla.mozilla.org/show_bug.cgi?id=1196047
[libs]: https://bugzilla.mozilla.org/show_bug.cgi?id=1201710
[build]: https://bugzilla.mozilla.org/show_bug.cgi?id=1202977
