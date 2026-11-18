// Steal a Snack v3 — entrypoint the make.fun grader runs.
//
// It gathers the built place, the sources and the screenshots into the
// output directory and writes the dossier the judge reads, using the
// vendored make.fun place library (vendor/makefun-roblox.ts, copied
// byte-identical from the competition kit).
//
// Node 22, standard library only, no build step:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// The grader fails any output holding a name that starts with a dot, so
// every copy below drops dotted files and directories (.gitkeep,
// .DS_Store, .git) at any depth.

import {
	copyFileSync,
	existsSync,
	lstatSync,
	mkdirSync,
	readdirSync,
	writeFileSync,
} from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

// The repository root is the directory this file lives in.
const repoDir = dirname(fileURLToPath(import.meta.url));
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output.
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The caps the scorer itself uses: only text_max_bytes shapes the
// dossier's bytes; the rest refuse an entry the scorer would refuse
// (more than 4 screenshots or one over 256 KiB; a place of more than
// 500000 instances, scripts totalling over 8 MiB, or script paths
// totalling over 1048576 characters).
const DOSSIER_CAPS = {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
};

// A name the grader would reject: anything starting with a dot.
function isDotted(name: string): boolean {
	return name.startsWith('.');
}

// Copy one directory tree, dropping dotted entries at every depth.
// Files are copied as-is; directories are recreated as needed.
function copyTree(from: string, to: string): void {
	mkdirSync(to, { recursive: true });
	for (const entry of readdirSync(from)) {
		if (isDotted(entry)) {
			continue;
		}
		const source = join(from, entry);
		const target = join(to, entry);
		if (lstatSync(source).isDirectory()) {
			copyTree(source, target);
		} else {
			copyFileSync(source, target);
		}
	}
}

mkdirSync(outputDir, { recursive: true });

// The built place and its published-place pointer, straight across.
copyFileSync(join(repoDir, 'game.rbxl'), join(outputDir, 'game.rbxl'));
copyFileSync(join(repoDir, 'PLAY.json'), join(outputDir, 'PLAY.json'));

// Sources and screenshots, dotted entries dropped. Screenshots are
// optional: a run without any still produces a valid dossier, but the
// directory itself must exist — buildDossier reads it unconditionally.
copyTree(join(repoDir, 'src'), join(outputDir, 'src'));
mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
if (existsSync(join(repoDir, 'screenshots'))) {
	copyTree(join(repoDir, 'screenshots'), join(outputDir, 'screenshots'));
}

// The dossier is built from what is now in the output directory, so
// it describes exactly what the grader will receive.
writeFileSync(
	join(outputDir, 'dossier.json'),
	buildDossier(outputDir, DOSSIER_CAPS),
);

console.log(`Steal a Snack v3 entry written to ${outputDir}`);
