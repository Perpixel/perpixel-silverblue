---
description: Build the perpixel-silverblue OCI image locally (make container) and report the result
---

Build the container image locally by running the `build-container` skill: run `make container`
in the background, watch for `dnf`/`buildah` failures, and report the resulting OCI archive path
(or the exact failing line plus a proposed fix). Do not run `make rebase` unless I ask.
