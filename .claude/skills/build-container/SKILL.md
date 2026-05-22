---
name: build-container
description: Build the perpixel-silverblue OCI image locally with `make container` and report the result. Use when asked to build the image, do a local build, test the Containerfile, or verify that changes to packages.sh / build_files actually build.
---

# Build the container image locally

`make container` runs `build.sh`, which calls `buildah bud` with `--no-cache --pull=always`.
This pulls the full Fedora Silverblue base and runs every `dnf install` in `packages.sh`, so a
clean build takes many minutes and a lot of disk/network. The output is an OCI archive at
`/tmp/${TARGET_IMAGE_NAME}.tar.gz` (`/tmp/perpixel-silverblue.tar.gz`).

## Steps

1. **Run it in the background** — it is long-running. From the repo root:
   ```sh
   make container
   ```
   Launch with `run_in_background: true` so you keep getting progress and aren't blocked.

2. **Watch for the common failure modes.** `set -oeux pipefail` means the build aborts on the
   first error and the failing line is printed. Most failures are in `packages.sh`:
   - **Package not found / obsoleted** — a package name changed or moved. Read the exact `dnf`
     error; fix the name in `build_files/scripts/packages.sh`.
   - **RPM Fusion "freeworld" conflict** — `mesa-va-drivers-freeworld` / `mesa-vdpau-drivers-freeworld`
     replace the stock `mesa-*-drivers`. If `dnf install` reports a conflict, switch that line to
     `dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y` (and the vdpau equivalent).
   - **i686/multilib not found** — the 32-bit gaming drivers (`*.i686`) require the x86_64 base
     package and matching repos; confirm the exact arch-qualified name with `dnf`.

3. **On success**, report the archive path and the rebase command:
   ```sh
   make rebase   # bootc switch onto ostree-unverified-image:oci-archive:/tmp/perpixel-silverblue.tar.gz
   ```
   Do not run `make rebase` unless the user asks — it switches the running system's deployment.

4. **On failure**, surface the exact failing `dnf`/`buildah` line (not a paraphrase), propose the
   one-line fix, and offer to apply it and rebuild.

## Notes

- buildah runs rootless here (subuid is configured for the user); no `sudo` is needed.
- A failed or interrupted build can leave large layers behind. `buildah images` / `buildah rm --all`
  and `make clean` (removes the `/tmp` tarball) help reclaim space.
