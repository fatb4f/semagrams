## Slice contract

Use the CUE app-abstraction repo only as a **shape reference**, not as a dependency. The useful pattern there is: user-facing abstraction data, platform/policy definitions in a separate package, and a render/export step that materializes lower-level output. The README describes a unified configuration context, platform definitions, and a render script that retrieves generated output. ([GitHub][1])

For this slice, translate that pattern to code planning:

```text
change abstraction       = patchplan/cue/change.cue
platform/policy schema   = patchplan/cue/schema.cue + derive.cue
render/export step       = cue export -> graph/model/report JSON
external facts           = ast-grep + tsc + LSP adapter + git
```

`ast-grep` has structured JSON output via `--json`, which makes it suitable as the first CST-derived fact source. ([Ast Grep][2]) Tree-sitter itself builds concrete syntax trees, but the first slice should avoid raw parser setup friction and import normalized CST-derived facts instead. ([Tree-sitter][3])

---

# Codex slice

```text
You are working in a new isolated probe repo.

Create the repo at:

  ~/src/patchplan-probe

Do not modify any existing production repo.
Do not install packages.
Do not use FUSE.
Do not use Bun.
Do not build an agent workflow.
Do not build a universal refactoring engine.

The user has manually installed system dependencies. Your job is to create a functional proof-of-concept workflow only.

Goal:
Materialize a CUE-backed relational patch-planning workflow for a tiny TypeScript repo.

The workflow must prove:

  1. A VCS repo can be observed with standard tools.
  2. ast-grep can extract CST-derived structural facts.
  3. tsc can extract compiler facts.
  4. a minimal LSP adapter boundary can emit LSP facts.
  5. CUE can import those facts.
  6. CUE can derive/export:
       - a relational dependency graph
       - a candidate model
       - acceptance constraints
  7. A candidate source projection can be generated.
  8. Candidate facts can be re-observed.
  9. CUE can green-light or reject the candidate by unification.

Language:
  TypeScript.

Migration:
  Replace direct console.$METHOD(...) calls with logger.$METHOD(...).

Required starting source:

  src/app.ts

    export function run(user: { id: string }) {
      console.log(user.id)
      console.error("failed", user.id)
    }

Candidate target shape:

  src/app.ts

    import { logger } from "./logger"

    export function run(user: { id: string }) {
      logger.log(user.id)
      logger.error("failed", user.id)
    }

  src/logger.ts

    export const logger = {
      log: (...args: unknown[]) => console.log(...args),
      error: (...args: unknown[]) => console.error(...args),
    }

Acceptance:
  Candidate is accepted only when:
    - candidate has zero console receiver calls in app.ts
    - candidate has at least one logger receiver call
    - candidate has logger binding available
    - compiler error count is zero
    - LSP adapter reports OK and zero errors
    - git candidate diff is non-empty
```

---

# Required repo layout

```text
patchplan-probe/
  .gitignore
  package.json
  tsconfig.json
  src/
    app.ts

  patchplan/
    README.md

    cue/
      schema.cue
      change.cue
      derive.cue
      accept.cue

    scripts/
      check-deps
      extract-cst-facts
      extract-compiler-facts
      extract-lsp-facts
      extract-vcs-facts
      make-candidate
      graph-dot
      validate
      demo

    out/
      live/
      candidate/
      graph/
      reports/
```

`patchplan/out/` must be generated and ignored by git.

---

# Dependency assumptions

The script must check, but not install:

```text
required:
  git
  node
  npm
  python3
  cue
  ast-grep or sg
  tsc or npx tsc
  typescript-language-server

recommended:
  jq
  dot
  tree-sitter
```

`tree-sitter-cli` is allowed as a **best-effort raw parse artifact only**. Do not block the slice on raw Tree-sitter parser configuration. The pass/fail structural fact path is ast-grep JSON normalized into `cst.json`.

---

# Exact CUE files

## `patchplan/cue/schema.cue`

Create this file exactly, then adjust only if CUE reports syntax errors.

```cue
package patchplan

#Diagnostic: {
	file?:     string
	line?:     int & >=0
	severity: "error" | "warning" | "info"
	code?:     string
	message:  string
}

#Primitive: {
	id:   string
	file: string

	kind: "call" | "binding"

	line: int & >=1
	text: string

	receiver?: string
	method?:   string
	name?:     string
}

#Counts: {
	consoleCalls:  int & >=0
	loggerCalls:   int & >=0
	loggerBindings: int & >=0
}

#RepoFacts: {
	root: string
	head: string
	branch: string
	dirty: bool
}

#Facts: {
	phase: "live" | "candidate"
	repo: #RepoFacts

	primitives: [...#Primitive]
	counts: #Counts

	hasLoggerBinding: bool
}

#CompilerFacts: {
	phase: "live" | "candidate"
	errorCount: int & >=0
	diagnostics: [...#Diagnostic]
}

#LSPFacts: {
	phase: "live" | "candidate"

	adapterOK: bool
	errorCount: int & >=0
	diagnostics: [...#Diagnostic]

	symbols?: [...{
		name: string
		kind: string
		file: string
	}]

	references?: [...{
		from: string
		to: string
	}]
}

#VCSFacts: {
	phase: "live" | "candidate"
	head: string
	branch: string
	diffStat: string
	diffNonEmpty: bool
}

#Node: {
	id: string
	kind: string
	label: string
}

#Edge: {
	from: string
	to: string
	kind: "contains" | "requires" | "produces" | "validates" | "conflicts"
	label?: string
}

#Graph: {
	nodes: [...#Node]
	edges: [...#Edge]
}

#Assertion: {
	id: string
	subject: string
	op: "==" | ">="
	value: string | int | bool
}

#CandidateModel: {
	changeID: string
	assertions: [...#Assertion]
}

#Report: {
	changeID: string

	live: {
		consoleCallCount: int & >=0
	}

	candidate: {
		consoleCallCount: int & >=0
		loggerCallCount: int & >=0
		hasLoggerBinding: bool
		compilerErrorCount: int & >=0
		lspAdapterOK: bool
		lspErrorCount: int & >=0
		diffNonEmpty: bool
	}

	accepted: bool

	accepted: candidate.consoleCallCount == 0 &&
		candidate.loggerCallCount >= 1 &&
		candidate.hasLoggerBinding &&
		candidate.compilerErrorCount == 0 &&
		candidate.lspAdapterOK &&
		candidate.lspErrorCount == 0 &&
		candidate.diffNonEmpty
}

facts?: #Facts
compiler?: #CompilerFacts
lsp?: #LSPFacts
vcs?: #VCSFacts
graph?: #Graph
candidateModel?: #CandidateModel
report?: #Report
```

## `patchplan/cue/change.cue`

```cue
package patchplan

change: {
	id: "replace-console-with-logger"
	language: "typescript"

	forbiddenReceivers: ["console"]
	requiredReceivers: ["logger"]

	requiredBinding: "logger"

	scope: {
		include: ["src/**/*.ts"]
		exclude: []
	}
}
```

## `patchplan/cue/derive.cue`

```cue
package patchplan

primitiveNodes: [
	for p in facts.primitives {
		id: p.id
		kind: "primitive"
		label: "\(p.kind): \(p.text) @ \(p.file):\(p.line)"
	},
]

obligationNodes: [
	{
		id: "obligation:provide-logger-binding"
		kind: "obligation"
		label: "provide logger binding"
	},
	{
		id: "obligation:rewrite-console-calls"
		kind: "obligation"
		label: "rewrite console receiver calls to logger receiver calls"
	},
	{
		id: "gate:compiler-clean"
		kind: "gate"
		label: "compiler error count == 0"
	},
	{
		id: "gate:lsp-clean"
		kind: "gate"
		label: "LSP adapter OK and error count == 0"
	},
]

consoleRewriteEdges: [
	for p in facts.primitives if p.kind == "call" && p.receiver == "console" {
		from: p.id
		to: "obligation:rewrite-console-calls"
		kind: "requires"
		label: "console call must be rewritten"
	},
]

graph: #Graph & {
	nodes: primitiveNodes + obligationNodes

	edges: consoleRewriteEdges + [
		{
			from: "obligation:rewrite-console-calls"
			to: "obligation:provide-logger-binding"
			kind: "requires"
			label: "logger calls require logger binding"
		},
		{
			from: "obligation:provide-logger-binding"
			to: "gate:compiler-clean"
			kind: "validates"
			label: "compiler proves binding resolves"
		},
		{
			from: "obligation:rewrite-console-calls"
			to: "gate:lsp-clean"
			kind: "validates"
			label: "LSP confirms no semantic errors"
		},
	]
}

candidateModel: #CandidateModel & {
	changeID: change.id
	assertions: [
		{
			id: "no-console-calls"
			subject: "candidate.consoleCallCount"
			op: "=="
			value: 0
		},
		{
			id: "has-logger-calls"
			subject: "candidate.loggerCallCount"
			op: ">="
			value: 1
		},
		{
			id: "has-logger-binding"
			subject: "candidate.hasLoggerBinding"
			op: "=="
			value: true
		},
		{
			id: "compiler-clean"
			subject: "candidate.compilerErrorCount"
			op: "=="
			value: 0
		},
		{
			id: "lsp-clean"
			subject: "candidate.lspErrorCount"
			op: "=="
			value: 0
		},
	]
}
```

## `patchplan/cue/accept.cue`

```cue
package patchplan

report: #Report & {
	accepted: true
}
```

---

# Required script behavior

## `patchplan/scripts/check-deps`

Must:

```text
- fail if required tools are missing
- accept either sg or ast-grep
- print chosen ast-grep command
- warn but do not fail if jq, dot, or tree-sitter are missing
```

## `patchplan/scripts/extract-cst-facts`

Input:

```text
phase: live | candidate
source root path
output file path
```

Must:

```text
- run ast-grep JSON searches for:
    console.$METHOD($$$ARGS)
    logger.$METHOD($$$ARGS)
- normalize results into:
    { "facts": #Facts-compatible object }
- detect logger binding by:
    import { logger } from "./logger"
    OR
    export const logger =
    OR
    const logger =
- include git repo head/branch/dirty facts inside facts.repo
```

Use ast-grep JSON as the authoritative structural source:

```bash
sg run -p 'console.$METHOD($$$ARGS)' --lang ts --json=compact <source>
sg run -p 'logger.$METHOD($$$ARGS)' --lang ts --json=compact <source>
```

If the binary is named `ast-grep`, use that instead.

The normalized JSON shape must be:

```json
{
  "facts": {
    "phase": "live",
    "repo": {
      "root": "...",
      "head": "...",
      "branch": "...",
      "dirty": false
    },
    "primitives": [],
    "counts": {
      "consoleCalls": 0,
      "loggerCalls": 0,
      "loggerBindings": 0
    },
    "hasLoggerBinding": false
  }
}
```

## `patchplan/scripts/extract-compiler-facts`

Must run:

```bash
npx tsc --noEmit --pretty false
```

If `npx` is unavailable but `tsc` exists, use:

```bash
tsc --noEmit --pretty false
```

Output:

```json
{
  "compiler": {
    "phase": "candidate",
    "errorCount": 0,
    "diagnostics": []
  }
}
```

A simple parser is sufficient:

* exit code `0` means `errorCount: 0`
* nonzero means count diagnostic-looking lines and store messages

## `patchplan/scripts/extract-lsp-facts`

First slice requirement:

```text
Implement a minimal LSP adapter boundary.
```

Minimum acceptable behavior:

```text
- verify typescript-language-server exists
- run a smoke command such as:
    typescript-language-server --help
  or initialize a short-lived stdio adapter if straightforward
- emit lsp.adapterOK true if the server can be invoked
- emit lsp.errorCount 0 in smoke mode
- include "mode": "smoke" in an extra field only if you also update schema
```

Do not spend the slice building full reference/definition extraction. That is the next slice.

Output:

```json
{
  "lsp": {
    "phase": "candidate",
    "adapterOK": true,
    "errorCount": 0,
    "diagnostics": [],
    "symbols": [],
    "references": []
  }
}
```

## `patchplan/scripts/extract-vcs-facts`

Must output:

```json
{
  "vcs": {
    "phase": "candidate",
    "head": "...",
    "branch": "...",
    "diffStat": "...",
    "diffNonEmpty": true
  }
}
```

For candidate source in `patchplan/out/candidate/source`, initialize it as a git repo or compute diff against copied live source. Simpler acceptable approach:

```text
- keep candidate source inside the main repo under ignored patchplan/out/
- use diff -ru live/source candidate/source
- set diffNonEmpty based on whether diff output is non-empty
```

## `patchplan/scripts/make-candidate`

Must support:

```bash
patchplan/scripts/make-candidate good
patchplan/scripts/make-candidate bad
```

Good mode:

```text
- copy live source to candidate source
- create src/logger.ts
- insert import { logger } from "./logger" at top of src/app.ts
- rewrite console.log -> logger.log
- rewrite console.error -> logger.error
```

Bad mode must intentionally fail one acceptance condition. Prefer:

```text
- rewrite console.log only
- leave console.error unchanged
- do not create logger.ts
- do not insert logger import
```

## `patchplan/scripts/validate`

Must:

```text
- run cue vet on each facts file against schema.cue
- export graph JSON from CUE
- export candidate model JSON from CUE
- generate DOT from graph JSON
- assemble report.json
- run cue vet schema.cue accept.cue report.json
- good mode must pass
- bad mode must fail acceptance but still produce report.json
```

Required CUE commands:

```bash
cue vet patchplan/cue/schema.cue patchplan/out/live/cst.json
cue vet patchplan/cue/schema.cue patchplan/out/candidate/cst.json
cue vet patchplan/cue/schema.cue patchplan/out/candidate/compiler.json
cue vet patchplan/cue/schema.cue patchplan/out/candidate/lsp.json
cue vet patchplan/cue/schema.cue patchplan/out/candidate/vcs.json
```

Export graph:

```bash
cue export \
  patchplan/cue/schema.cue \
  patchplan/cue/change.cue \
  patchplan/cue/derive.cue \
  patchplan/out/live/cst.json \
  -e graph \
  --out json \
  > patchplan/out/graph/graph.json
```

Export candidate model:

```bash
cue export \
  patchplan/cue/schema.cue \
  patchplan/cue/change.cue \
  patchplan/cue/derive.cue \
  patchplan/out/live/cst.json \
  -e candidateModel \
  --out json \
  > patchplan/out/candidate/model.json
```

Acceptance check:

```bash
cue vet \
  patchplan/cue/schema.cue \
  patchplan/cue/accept.cue \
  patchplan/out/reports/report.json
```

## `patchplan/scripts/demo`

Must run:

```bash
patchplan/scripts/demo good
patchplan/scripts/demo bad
```

Default mode should be `good`.

Full flow:

```text
1. check deps
2. remove patchplan/out
3. create live/source from repo src
4. extract live cst facts
5. cue-vet live cst facts
6. export graph from CUE
7. export candidate model from CUE
8. make candidate source
9. extract candidate cst facts
10. extract compiler facts
11. extract LSP facts
12. extract VCS/diff facts
13. assemble report
14. validate report with CUE
15. print summary
```

---

# Root project files

## `package.json`

```json
{
  "name": "patchplan-probe",
  "private": true,
  "type": "module",
  "scripts": {
    "typecheck": "tsc --noEmit --pretty false"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

## `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"]
}
```

## `.gitignore`

```gitignore
node_modules/
patchplan/out/
```

---

# README requirements

`patchplan/README.md` must explain:

```text
What this proves:
  - CUE can import normalized CST-derived facts
  - CUE can derive a graph and candidate model
  - compiler/LSP/VCS facts can be normalized and validated
  - candidate acceptance can be enforced via CUE unification

What this does not prove:
  - raw Tree-sitter CST JSON import
  - full LSP references/definitions
  - FUSE projection
  - generic source generation
  - multi-language support

Why ast-grep is used first:
  - it is Tree-sitter-backed
  - it emits structured JSON
  - it avoids raw parser setup friction

Where next slices fit:
  1. real LSP documentSymbol/references adapter
  2. raw tree-sitter parse artifact import
  3. patch-stack commit generation
  4. richer dependency graph
```

---

# Success criteria

After implementation, these must work:

```bash
cd ~/src/patchplan-probe

patchplan/scripts/demo good
patchplan/scripts/demo bad
```

Expected:

```text
good:
  accepted: true
  cue acceptance check passes
  graph.json exists
  deps.dot exists
  candidate/model.json exists
  reports/report.json exists

bad:
  accepted: false
  base schema validation passes
  cue acceptance check fails intentionally
  report still exists
```

Generated artifacts to inspect:

```text
patchplan/out/live/cst.json
patchplan/out/graph/graph.json
patchplan/out/graph/deps.dot
patchplan/out/candidate/model.json
patchplan/out/candidate/cst.json
patchplan/out/candidate/compiler.json
patchplan/out/candidate/lsp.json
patchplan/out/candidate/vcs.json
patchplan/out/reports/report.json
```

---

# Final reporting back

When finished, report only:

```text
- commands run
- whether good passed
- whether bad rejected
- generated files
- any CUE syntax adjustments made
- any dependency/tool limitations
- next smallest slice
```

Do not expand scope. Do not implement FUSE. Do not implement a full LSP client unless the smoke adapter is already complete and the rest of the slice is passing.

[1]: https://github.com/cue-lang/cue-deployment-patterns/tree/app-abstraction/app-abstraction "cue-deployment-patterns/app-abstraction at app-abstraction · cue-lang/cue-deployment-patterns · GitHub"
[2]: https://ast-grep.github.io/reference/cli/scan.html?utm_source=chatgpt.com "ast-grep scan"
[3]: https://tree-sitter.github.io/?utm_source=chatgpt.com "Tree-sitter: Introduction"
