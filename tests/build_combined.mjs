// tests/build_combined.mjs — assemble one combined Luau chunk per test.
//
// The Luau CLI sandboxes every required module in its own environment, so
// globals set by a required stub are invisible to the modules under test.
// This script works around that by concatenating, for one test file:
//   1. tests/stub_env.luau (the Roblox stub + Test helper),
//   2. every game source embedded as a long-bracket string in SOURCES,
//      loaded in dependency order by the stub's loadModuleSource,
//   3. the test file itself (its require("./stub_env") line stripped).
// The output runs as a single main chunk, so the stub globals, the modules
// (loaded with loadstring) and the test all share one environment.
//
// Usage: node tests/build_combined.mjs <repo-root> <test-file> <out-file>

import { readFileSync, writeFileSync, renameSync } from "node:fs";
import { join } from "node:path";

const repo = process.argv[2];
const testFile = process.argv[3];
const outFile = process.argv[4];

if (!repo || !testFile || !outFile) {
	console.error("usage: node tests/build_combined.mjs <repo-root> <test-file> <out-file>");
	process.exit(2);
}

// Long-bracket level that does not appear in the source.
function bracket(src) {
	let level = 0;
	while (src.includes("]" + "=".repeat(level) + "]")) {
		level += 1;
	}
	const eq = "=".repeat(level);
	return `[${eq}[${src}]${eq}]`;
}

const MODULES = [
	["Config", "src/shared/Config.luau"],
	["State", "src/server/State.luau"],
	["CharacterFactory", "src/server/CharacterFactory.luau"],
	["Effects", "src/server/Effects.luau"],
	["RateLimit", "src/server/RateLimit.luau"],
	["Saves", "src/server/Saves.luau"],
	["Bases", "src/server/Bases.luau"],
	["Economy", "src/server/Economy.luau"],
	["Spawner", "src/server/Spawner.luau"],
	["Steal", "src/server/Steal.luau"],
	["Rebirth", "src/server/Rebirth.luau"],
	["Wave", "src/server/Wave.luau"],
	["Weather", "src/server/Weather.luau"],
	["Leaderboard", "src/server/Leaderboard.luau"],
	["init.server", "src/server/init.server.luau"],
	["Hud.client", "src/client/Hud.client.luau"],
];

// Dependency order for the server modules.
const LOAD_ORDER = [
	"Config",
	"State",
	"CharacterFactory",
	"Effects",
	"RateLimit",
	"Saves",
	"Bases",
	"Economy",
	"Spawner",
	"Steal",
	"Rebirth",
	"Wave",
	"Weather",
	"Leaderboard",
];

let stub;
try {
	stub = readFileSync(join(repo, "tests/stub_env.luau"), "utf8");
} catch (err) {
	console.error(`build_combined: cannot read tests/stub_env.luau: ${err.message}`);
	process.exit(2);
}

let sources = "SOURCES = {\n";
for (const [name, rel] of MODULES) {
	let src;
	try {
		src = readFileSync(join(repo, rel), "utf8");
	} catch (err) {
		console.error(`build_combined: MISSING source file ${rel} (needed as ${name}): ${err.message}`);
		process.exit(3);
	}
	if (src.trim().length === 0) {
		console.error(`build_combined: EMPTY source file ${rel} (needed as ${name})`);
		process.exit(3);
	}
	sources += `  [${JSON.stringify(name)}] = ${bracket(src)},\n`;
}
sources += "}\n";

const loads = LOAD_ORDER.map(
	(name) => `loadModuleSource(${JSON.stringify(name)}, SOURCES[${JSON.stringify(name)}])`,
).join("\n");

let test;
try {
	test = readFileSync(join(repo, testFile), "utf8");
} catch (err) {
	console.error(`build_combined: cannot read ${testFile}: ${err.message}`);
	process.exit(2);
}
// Drop the stub require line: the stub is already the first part of this chunk.
test = test
	.split("\n")
	.filter((line) => !/^\s*require\("\.\/stub_env"\)\s*$/.test(line))
	.join("\n");

// Write atomically: a crash mid-write must never leave a half-written
// chunk for the Luau CLI to run.
writeFileSync(outFile + ".tmp", `${stub}\n${sources}\n${loads}\n${test}\n`);
renameSync(outFile + ".tmp", outFile);
