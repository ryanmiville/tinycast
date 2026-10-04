import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";

const command = new URL("../Scripts/personal-beta.mjs", import.meta.url);
const release = (tag_name, overrides = {}) => ({
  tag_name, draft: false, prerelease: true, ...overrides
});
const select = (input) => spawnSync(process.execPath, [command.pathname], {
  input: JSON.stringify(input), encoding: "utf8"
});

test("selects the newest beta numerically across API pages", () => {
  const result = select([
    [release("v0.11.21-beta.9"), release("v0.11.21-beta.120")],
    [release("v0.11.20-beta.999"), release("v0.11.21-beta.10")]
  ]);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(result.stdout), {
    tag: "v0.11.21-beta.120", version: "0.11.21-beta.120"
  });
});

test("ignores stable, draft, and non-beta releases", () => {
  const result = select([
    release("v1.0.0", { prerelease: false }),
    release("v1.0.0-beta.1", { draft: true }),
    release("v1.0.0-rc.1"),
    release("v0.11.21-beta.120")
  ]);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(JSON.parse(result.stdout).tag, "v0.11.21-beta.120");
});

test("fails rather than silently selecting stable when no beta exists", () => {
  const result = select([release("v1.0.0", { prerelease: false })]);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /No published upstream beta release found/);
});
