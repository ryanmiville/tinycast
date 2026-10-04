# Personal fork

This fork follows upstream's published beta releases. There are no custom feature patches: upstream
now supports Left Control as Hyper, so the original patch and the test workaround were retired.
Keep Caps Lock set to Control in macOS Keyboard → Modifier Keys and Left Control selected in Tinycast.
The stored key choice, app identity and signing certificate stay the same across this change.

## Branches and nightly sync

`main` is an unmodified mirror of upstream `main`. `codex/personal` is the fork's default branch and
tracks the newest published `vMAJOR.MINOR.PATCH-beta.N` release, with only the fork update feed and
release automation on top. It can therefore lag the development commits on `main` until a beta ships.

`.github/workflows/personal-sync.yml` runs at 08:17 UTC daily, after pushes to the personal branch,
and can be run manually from Actions.
It selects the highest beta version across upstream's published, non-draft prereleases, fetches that
tag and rebases the personal commits onto its exact commit. It runs the beta selector checks, all
harnesses and lint, checks model imports, builds Debug, and packages a signed arm64 Release. After those
checks it atomically publishes both branches, using explicit leases against their original commits. A
conflict, failed check, or concurrent push stops publication. The failed Actions run shows the reason.
The workflow skips builds when the newest personal build of that beta represents the candidate commit.
It still fast-forwards the clean `main` mirror when the beta has not changed.
Hosted visual checks use Dark appearance, which the upstream bright-ink rendering fixture assumes.
Use its `force_release` input to rebuild the same source.

The schedule runs from the default branch, so keep `codex/personal` as the GitHub default. GitHub
may delay scheduled jobs or disable them after 60 days without activity. Check Actions if releases stop.

The repository-scoped write deploy key in `PERSONAL_SYNC_SSH_KEY` permits replaying upstream workflow
changes as well as Swift changes. The release uses `GITHUB_TOKEN`; no token can write to the tap.
Git operations use GitHub's SSH endpoint on port 443, with the connection checked before validation.
The stable certificate lives in `PERSONAL_SIGNING_P12_BASE64` and `PERSONAL_SIGNING_P12_PASSWORD`.
The original identity is backed up in the owner's login keychain as `Tinycast Personal Signing`.
Do not replace that identity on each build: its stability preserves Accessibility grants.
Validation, compilation, signing and artifact publication run on GitHub-hosted runners. Local
maintenance edits and pushes source only; Homebrew downloads the finished release to this laptop.

## Homebrew

```sh
brew install --cask ryanmiville/tap/tinycast-personal
brew update && brew upgrade --cask ryanmiville/tap/tinycast-personal
```

Uninstall the upstream Tinycast cask first if it is installed. Both install `Tinycast.app` with
`com.tinycast.app`, so existing settings, history and notes are preserved. Do not use `--zap`.
The first switch to the fork may require granting Accessibility again because the signer changes.

The fork publishes `personal-vUPSTREAM_BETA_VERSION-BUILD` prerelease tags containing
`Tinycast-Personal.zip` and `fork-release.json`. The cask's comma-separated version includes the upstream version and
the monotonically increasing workflow run number, so multiple builds of the same upstream version
remain eligible for `brew upgrade`. The app's own version is the full upstream beta version.
The manifest records the SHA-256, fork commit, exact upstream commit, upstream tag and beta channel.
Releases use a self-signed certificate, not Apple notarization; the cask clears download quarantine
after installing the verified archive, matching upstream's Homebrew installation route.

The tap's nightly workflow reads the newest public personal beta, verifies the archive's checksum, and
updates only `Casks/tinycast-personal.rb`. It runs at 10:47 UTC, after the fork's sync, and can
also be dispatched manually. A delayed fork release is picked up by the next tap run.
The cask intentionally omits `auto_updates`: Homebrew manages upgrades. The in-app feed points
to this fork and its personal tags do not parse as app-update versions, preventing upstream replacement.
Both workflows read the release list because GitHub's latest-release endpoint excludes prereleases.

## Working locally

Nightly rebases rewrite the personal branch. Before starting work, with no local-only commits and
a clean working tree, fetch and align the checkout with `origin/codex/personal`. Do not use a normal
pull to merge the old and rebased histories. If you have local-only work, preserve it on a temporary
branch and cherry-pick those commits onto the refreshed personal branch, then push normally.

If an upstream change conflicts with the patch, rebase manually, resolve and review the conflict,
run the checks from testing.md, and push with a lease. Dispatch the sync workflow to publish a build.
Keep customization commits small so future conflicts remain easy to understand.

Add future feature patches as separate commits on `codex/personal`; keep them apart from the two
distribution commits so a patch can be retired cleanly when upstream adopts it.
