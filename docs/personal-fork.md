# Personal fork

This fork adds Left Control to the Hyper Key selector. Keep Caps Lock set to Control in macOS
Keyboard → Modifier Keys, then choose Left Control under Tinycast Settings → General → Hyper Key.
macOS reports that remapped Caps Lock as Right Control, so it continues to send ordinary Control.

## Branches and nightly sync

`main` is an unmodified upstream mirror. `codex/personal` is the fork's default branch and contains
focused changes: Left Control support, a fork-only update feed, deterministic menu cleanup checks,
and this automation.

`.github/workflows/personal-sync.yml` runs at 08:17 UTC daily, after pushes to the personal branch,
and can be run manually from Actions.
It fetches `abue-ammar/tinycast/main`, rebases the personal commits, runs all harnesses and lint,
checks model imports, builds Debug, and packages a signed arm64 Release. Only after those checks does
it atomically publish both branches, using explicit leases against their original commits. A
conflict, failed check, or concurrent push stops publication. The failed Actions run shows the reason.
The workflow skips builds when the newest published release already represents the candidate commit.
Use its `force_release` input to rebuild the same source.

The schedule runs from the default branch, so keep `codex/personal` as the GitHub default. GitHub
may delay scheduled jobs or disable them after 60 days without activity. Check Actions if releases stop.

The repository-scoped write deploy key in `PERSONAL_SYNC_SSH_KEY` permits replaying upstream workflow
changes as well as Swift changes. The release uses `GITHUB_TOKEN`; no token can write to the tap.
The stable certificate lives in `PERSONAL_SIGNING_P12_BASE64` and `PERSONAL_SIGNING_P12_PASSWORD`.
The original identity is backed up in the owner's login keychain as `Tinycast Personal Signing`.
Do not replace that identity on each build: its stability preserves Accessibility grants.

## Homebrew

```sh
brew install --cask ryanmiville/tap/tinycast-personal
brew update && brew upgrade --cask ryanmiville/tap/tinycast-personal
```

Uninstall the upstream Tinycast cask first if it is installed. Both install `Tinycast.app` with
`com.tinycast.app`, so existing settings, history and notes are preserved. Do not use `--zap`.
The first switch to the fork may require granting Accessibility again because the signer changes.

The fork publishes `personal-vUPSTREAM_VERSION-BUILD` tags containing `Tinycast-Personal.zip` and
`fork-release.json`. The cask's comma-separated version includes both the upstream version and
the monotonically increasing workflow run number, so multiple builds of the same upstream version
remain eligible for `brew upgrade`. The app's own version remains the upstream version.
The manifest records the SHA-256, fork commit and upstream commit.
Releases use a self-signed certificate, not Apple notarization; the cask clears download quarantine
after installing the verified archive, matching upstream's Homebrew installation route.

The tap's nightly workflow reads the newest public release, verifies the archive's checksum, and
updates only `Casks/tinycast-personal.rb`. It runs at 10:47 UTC, after the fork's sync, and can
also be dispatched manually. A delayed fork release is picked up by the next tap run.
The cask intentionally omits `auto_updates`: Homebrew manages upgrades. The in-app feed points
to this fork and its personal tags do not parse as app-update versions, preventing upstream replacement.

## Working locally

Nightly rebases rewrite the personal branch. Before starting work, with no local-only commits and
a clean working tree, fetch and align the checkout with `origin/codex/personal`. Do not use a normal
pull to merge the old and rebased histories. If you have local-only work, preserve it on a temporary
branch and cherry-pick those commits onto the refreshed personal branch, then push normally.

If an upstream change conflicts with the patch, rebase manually, resolve and review the conflict,
run the checks from testing.md, and push with a lease. Dispatch the sync workflow to publish a build.
Keep customization commits small so future conflicts remain easy to understand.
