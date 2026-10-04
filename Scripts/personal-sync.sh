#!/bin/bash
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add upstream https://github.com/abue-ammar/tinycast.git
git fetch --no-tags upstream main
git fetch --no-tags origin main codex/personal
git merge-base --is-ancestor origin/main upstream/main
gh api --paginate --slurp repos/abue-ammar/tinycast/releases > "$RUNNER_TEMP/upstream-releases.json"
node Scripts/personal-beta.mjs < "$RUNNER_TEMP/upstream-releases.json" > "$RUNNER_TEMP/upstream-beta.json"
UPSTREAM_TAG="$(node -p 'require(process.argv[1]).tag' "$RUNNER_TEMP/upstream-beta.json")"
UPSTREAM_VERSION="$(node -p 'require(process.argv[1]).version' "$RUNNER_TEMP/upstream-beta.json")"
git fetch --no-tags upstream "refs/tags/$UPSTREAM_TAG:refs/personal/upstream-beta"
UPSTREAM_COMMIT="$(git rev-parse 'refs/personal/upstream-beta^{commit}')"
git merge-base --is-ancestor "$UPSTREAM_COMMIT" upstream/main
PERSONAL_START="$(git rev-parse origin/codex/personal)"
MAIN_START="$(git rev-parse origin/main)"
git switch -C codex/personal origin/codex/personal
git rebase "$UPSTREAM_COMMIT"
{
    echo "PERSONAL_START=$PERSONAL_START"
    echo "MAIN_START=$MAIN_START"
    echo "UPSTREAM_TAG=$UPSTREAM_TAG"
    echo "UPSTREAM_VERSION=$UPSTREAM_VERSION"
    echo "UPSTREAM_COMMIT=$UPSTREAM_COMMIT"
} >> "$GITHUB_ENV"

CHANGED=true
gh api repos/ryanmiville/tinycast/releases > "$RUNNER_TEMP/latest-release.json"
RELEASE_COMMIT="$(node -p 'require(process.env.RUNNER_TEMP + "/latest-release.json").find(release => !release.draft && release.prerelease && release.tag_name.startsWith("personal-v" + process.argv[1] + "-"))?.target_commitish ?? ""' "$UPSTREAM_VERSION")"
if [ "$RELEASE_COMMIT" = "$(git rev-parse HEAD)" ] && [ "$FORCE_RELEASE" != true ]; then
    CHANGED=false
fi
echo "changed=$CHANGED" >> "$GITHUB_OUTPUT"
