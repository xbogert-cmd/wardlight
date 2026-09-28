#!/bin/bash
# Cloud sessions: install the pinned Godot build and import the project. Godot is hosted as a
# release asset on this repo because cloud sessions can only fetch release assets from attached
# repos. Safe to re-run; skips the download when Godot 4.7.1 is already installed.
REPO=xbogert-cmd/wardlight
TAG=godot-4.7.1-stable
ZIP=Godot_v4.7.1-stable_linux.x86_64.zip
cd "$(dirname "$0")/.." || exit 1

if ! godot --version 2>/dev/null | grep -q "^4.7.1.stable"; then
	tmp=$(mktemp -d)
	gh release download "$TAG" --repo "$REPO" -p "$ZIP" -D "$tmp" \
		|| { echo "cloud_setup: could not download $ZIP from $REPO release $TAG"; exit 1; }
	unzip -qo "$tmp/$ZIP" -d "$tmp" && install -m 755 "$tmp/${ZIP%.zip}" /usr/local/bin/godot
fi

# Best effort: virtual display + software OpenGL so demo screenshots can render (see CLAUDE.md).
if ! command -v xvfb-run >/dev/null; then
	(apt-get update -qq && apt-get install -y -qq xvfb libgl1-mesa-dri libglx-mesa0 libegl1) >/dev/null 2>&1 \
		|| echo "cloud_setup: xvfb/mesa install failed (screenshots unavailable; headless checks still work)"
fi

godot --headless --path . --import > /tmp/godot_import.log 2>&1
echo "cloud_setup: $(godot --version 2>/dev/null || echo 'godot missing'); project imported"
