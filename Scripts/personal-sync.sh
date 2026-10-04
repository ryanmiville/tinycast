#!/bin/bash
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add upstream https://github.com/abue-ammar/tinycast.git
git fetch --no-tags upstream main
git fetch --no-tags origin main codex/personal
git merge-base --is-ancestor origin/main upstream/main
PERSONAL_START="$(git rev-parse origin/codex/personal)"
MAIN_START="$(git rev-parse origin/main)"
git switch -C codex/personal origin/codex/personal
git rebase upstream/main
{
    echo "PERSONAL_START=$PERSONAL_START"
    echo "MAIN_START=$MAIN_START"
} >> "$GITHUB_ENV"

CHANGED=true
if gh api repos/ryanmiville/tinycast/releases/latest \
    > "$RUNNER_TEMP/latest-release.json" 2> "$RUNNER_TEMP/latest-release-error"; then
    RELEASE_COMMIT="$(node -p 'require(process.env.RUNNER_TEMP + "/latest-release.json").target_commitish')"
    if [ "$RELEASE_COMMIT" = "$(git rev-parse HEAD)" ] && [ "$FORCE_RELEASE" != true ]; then
        CHANGED=false
    fi
elif ! grep -q 'HTTP 404' "$RUNNER_TEMP/latest-release-error"; then
    cat "$RUNNER_TEMP/latest-release-error" >&2
    exit 1
fi
echo "changed=$CHANGED" >> "$GITHUB_OUTPUT"
