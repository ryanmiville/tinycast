import { readFileSync } from "node:fs";

const releases = JSON.parse(readFileSync(0, "utf8")).flat();
const candidates = releases.flatMap((release) => {
  const match = /^v(\d+)\.(\d+)\.(\d+)-beta\.(\d+)$/.exec(release.tag_name);
  return !release.draft && release.prerelease && match
    ? [{ release, version: match.slice(1).map(Number) }]
    : [];
});
candidates.sort((left, right) => {
  for (let index = 0; index < left.version.length; index++) {
    const difference = right.version[index] - left.version[index];
    if (difference !== 0) return difference;
  }
  return 0;
});
if (candidates.length === 0) throw new Error("No published upstream beta release found");
const tag = candidates[0].release.tag_name;
console.log(JSON.stringify({ tag, version: tag.slice(1) }));
