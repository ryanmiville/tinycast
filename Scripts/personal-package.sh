#!/bin/bash
set -euo pipefail

UPSTREAM_VERSION="$(gh api repos/abue-ammar/tinycast/releases/latest --jq '.tag_name' | sed 's/^v//')"
if ! [[ "$UPSTREAM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid upstream release version: $UPSTREAM_VERSION" >&2
    exit 1
fi
export UPSTREAM_VERSION
export PERSONAL_TAG="personal-v$UPSTREAM_VERSION-$GITHUB_RUN_NUMBER"

xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$RUNNER_TEMP/Release" ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Tinycast Personal Signing" \
    OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    MARKETING_VERSION="$UPSTREAM_VERSION" CURRENT_PROJECT_VERSION="$GITHUB_RUN_NUMBER" build

APP="$RUNNER_TEMP/Release/Build/Products/Release/Tinycast.app"
./Scripts/verify-signature.sh "$APP"
for BINARY in "$APP/Contents/MacOS/Tinycast" "$APP/Contents/Helpers/ClipboardTextHelper" \
    "$APP/Contents/Helpers/Tinycast Dictation.app/Contents/MacOS/Tinycast Dictation"; do
    test "$(lipo -archs "$BINARY")" = arm64
done
mkdir -p dist
ditto -c -k --keepParent --sequesterRsrc "$APP" dist/Tinycast-Personal.zip
export PERSONAL_SHA256="$(shasum -a 256 dist/Tinycast-Personal.zip | cut -d ' ' -f1)"
export PERSONAL_SOURCE="$(git rev-parse HEAD)"
export PERSONAL_UPSTREAM="$(git rev-parse upstream/main)"
node <<'NODE'
const fs = require("node:fs");
const env = process.env;
const metadata = {
  version: env.UPSTREAM_VERSION + "," + env.GITHUB_RUN_NUMBER,
  tag: env.PERSONAL_TAG,
  sha256: env.PERSONAL_SHA256,
  source: env.PERSONAL_SOURCE,
  upstream: env.PERSONAL_UPSTREAM
};
fs.writeFileSync("dist/fork-release.json", JSON.stringify(metadata, null, 2) + "\n");
fs.writeFileSync("dist/release-notes.md", [
  "Personal fork: Left Control can serve as Hyper while Caps Lock remains Control.",
  "",
  "Upstream commit: " + metadata.upstream,
  "Fork commit: " + metadata.source,
  "",
  "Update with: brew update && brew upgrade --cask ryanmiville/tap/tinycast-personal",
  "",
  "The first switch from upstream requires granting Accessibility to this signing identity."
].join("\n") + "\n");
NODE
