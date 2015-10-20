# Overview

As a follow up to the large DevTools file move, we are refining the
`resource://` URLs used by DevTools files in [bug 1203159][resource].

This only affects JavaScript files loaded as direct `resource://` URLs, such as
JSMs via `Cu.import`.  No changes are needed for JS modules coming from our
loader via `require`.

This page gives an overview of what changes to expect and also how to adapt
patches you may have in progress.

# Motivation

We are moving all DevTools `resource://` URLs under `resource://devtools/`.

There are several benefits to this including:

* DevTools `resource://` URLs will exactly match source tree path, like module
  IDs currently do
* Reloading DevTools without restarting Firefox will become even simpler and
  cover more files than before
* DevTools will be structured "more like" an add-on (this does not mean it is
  removable, it's only about file loading)
* Future products will be able to include DevTools more easily

# Changes Made

## JS Modules

### Cu.import()

To `import()` a file, the `resource://` path is exactly the source tree path.  
The previous details about sometimes needing `gre` no longer apply.  

In more detail:

* `/devtools/client/<X>`: `resource://devtools/client/<X>`
* `/devtools/server/<X>`: `resource://devtools/server/<X>`
* `/devtools/shared/<X>`: `resource://devtools/shared/<X>`

Example:

* File: `/devtools/shared/Loader.jsm`
* Usage:
  * `Cu.import("resource://devtools/shared/Loader.jsm")`

Example:

* File: `/devtools/client/framework/gDevTools.jsm`
* Usage:
  * `Cu.import("resource://devtools/client/framework/gDevTools.jsm")`
  * `loader.lazyImporter(this, "gDevTools", "resource://devtools/client/framework/gDevTools.jsm")`

### require()

As stated above, no changes are needed for modules loaded via `require()`.

Under the hood, the DevTools loader finds these files using the same new
`resource://` URLs, but this just works without any changes.

## Building

As a happy side effect of the implementation, building is 2 characters easier
than before.  The `/*` suffix is no longer needed.

To build all of DevTools, use:

```
mach build devtools
```

or specify some subdirectory, as usual.

Another option worth trying these days is:

```
mach build faster
```

`devtools` covers DevTools files of all kinds, while `faster` covers non-C++
things across the tree.  They have roughly the same run time on an already built
checkout (4 seconds) for me.

# Updating Your Patches

You have several options for updating any patches you started before the file
move landed.

## Update Manually

The changes needed should involve only two replacements:

* `resource://gre/modules/devtools` → `resource://devtools`
* `resource://modules/devtools` → `resource://devtools`

## Rebase

You should get reasonable results by letting your VCS tool rebase your work
however you normally do this.

I tested a small feature branch using bookmark-style Mercurial development, and
it worked quite well.  There were only a few conflicts to address in expected
places, like import paths.

I would expect bookmark-style Mercurial and Git to work well.  MQ-style
Mercurial may not work as well, as I don't believe it handles the situation as
nicely.  Another reason to stop using it, I suppose.

# Add-on Impact

This change requires updates for any add-on using DevTools `resource://` URLs.
Such add-ons would need to make the same replacements as patches do above.

If you have already updated your add-ons for the earlier file migration and are
maintaining two paths for 43 and earlier vs. 44 and later, I would suggest just
replacing the 44 path with these changes.  One reason this change was made in 44
was to avoid creating yet a 3rd set of paths for add-ons to maintain.

For the moment, the same set of shimmed files are available at all paths
they have lived at over time (43 and earlier, early 44, and late 44), so for the
following files, add-ons will continue to work:

* `Console.jsm`
* `dbg-client.jsm`
* `dbg-server.jsm`
* `event-emitter.js`
* `gDevTools.jsm`
* `Loader.jsm`
* `Simulator.jsm`

We'll soon enable deprecation warnings when loading these files by their old
paths in [bug 1204127][deprecation], so upgrading is still a good idea.

[resource]: https://bugzilla.mozilla.org/show_bug.cgi?id=1203159
[deprecation]: https://bugzilla.mozilla.org/show_bug.cgi?id=1204127
