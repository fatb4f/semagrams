## GitHub issue draft

````md
# Complete patchplan-probe validation lifecycle

## Objective

Complete the validation lifecycle for `patchplan-probe` now that the core theory has passed probe-level validation.

Current theory proven:

```text
tool facts
  -> normalized evidence
  -> CUE constraints
  -> graph/model/patch-plan derivation
  -> candidate re-observation
  -> CUE accept/reject
````

Remaining work should no longer ask “can this work?” It should test the operational envelope:

```text
Can this remain accurate under causal, environmental, architectural, scale,
materialization, and evidence-integrity stress?
```

## Non-goals

* No FUSE.
* No agent workflow.
* No multi-language support yet.
* No broad refactoring platform.
* No generalized UI.
* No hidden acceptance logic outside CUE.

## Hard invariant

Scripts may extract/generate facts, but green-light authority must remain CUE-owned.

```text
tools/scripts produce facts
CUE validates facts
CUE derives graph/model/patch-plan artifacts
CUE gates acceptance
```

---

# Validation slices

Each slice must preserve:

```bash
patchplan/scripts/demo good
patchplan/scripts/demo bad
```

Expected baseline:

```text
good -> accepted: true
bad  -> accepted: false
```

Where a slice validates failure-domain robustness, it must be repeatable across:

```text
failure-domain fixture: one targeted failure case
scale tier 1: tiny
scale tier 2: medium
scale tier 3: large/synthetic
```

Each tier must emit comparable artifacts:

```text
patchplan/out/reports/<slice>/<tier>.json
patchplan/out/reports/<slice>/<tier>.md
```

---

# Slice 1: final ordered symbol test

## Purpose

Close the current LSP-symbol generalization gap before moving to larger lifecycle probes.

Current limitation:

```text
semantic normalization is still fixture-specific
references are resolved only for selected logger usage
```

Target:

```text
all relevant logger references
  -> normalized semantic reference nodes
  -> deterministic symbol nodes
  -> resolves-to edges
  -> stable ordering
  -> CUE-validated symbol graph
```

## Failure domain

Primary:

```text
complexity
```

Secondary:

```text
tool-interface
architecture-quality
```

## Required behavior

For every logger usage in the candidate source:

```text
ref:<file>:<line>:<char>:logger
  resolves-to
symbol:src/logger.ts:<line>:<char>:logger
```

The output order must be deterministic.

## Required artifacts

```text
patchplan/out/candidate/lsp.json
patchplan/out/graph/graph.json
patchplan/out/graph/deps.dot
patchplan/out/reports/ordered-symbols/report.json
```

## Required CUE constraints

Add or verify constraints that express:

```text
candidate accepted requires:
  - every logger reference has a resolves-to edge
  - every resolves-to target is a known symbol node
  - no unresolved logger reference remains
  - no duplicate semantic node IDs exist
  - semantic node ordering is deterministic
```

## Tiers

### Failure-domain fixture

Create a bad case where at least one logger reference does not resolve.

Expected:

```text
schema validation passes
acceptance fails
graph explains unresolved reference
```

### Tier 1: tiny

Current fixture:

```text
src/app.ts
src/logger.ts
```

Expected:

```text
all logger refs resolve
accepted true
```

### Tier 2: medium

Add multiple files:

```text
src/app.ts
src/worker.ts
src/service.ts
src/logger.ts
```

Expected:

```text
all logger refs across files resolve to same logger symbol
accepted true
```

### Tier 3: large/synthetic

Generate N files, for example:

```text
src/generated/case-001.ts ... src/generated/case-050.ts
```

Each imports/uses logger.

Expected:

```text
all generated logger refs resolve
graph remains deterministic
runtime remains acceptable for probe
```

## Pass criteria

* `demo good` still passes.
* `demo bad` still rejects.
* Ordered symbol report exists for all tiers.
* Every accepted candidate has full logger reference closure.
* Bad unresolved-symbol fixture produces a graph-visible failure path.

---

# Slice 2: CUE-native report generation

## Purpose

Make CUE the sole report generator, not only the report validator.

Current weakness:

```text
Python assembles report.json and writes accepted
CUE validates afterward
```

Target:

```text
facts/*.json
  -> cue export -e report
  -> report.json
  -> cue vet accept.cue report.json
```

## Failure domain

Primary:

```text
evidence-integrity
```

Secondary:

```text
model-design
```

## Tiers

### Failure-domain fixture

Force script-generated facts that would previously allow a misleading `accepted` field.

Expected:

```text
CUE-generated report overrides script-side acceptance
```

### Tier 1: tiny

Current good/bad fixture.

### Tier 2: medium

Multi-file logger migration.

### Tier 3: large/synthetic

Generated multi-file migration.

## Pass criteria

* Python no longer computes final `accepted`.
* CUE exports `report.accepted`.
* Good report exports `accepted: true`.
* Bad report exports `accepted: false`.
* `accept.cue` remains the final green-light overlay.

---

# Slice 3: tamper-resistance matrix

## Purpose

Prove acceptance cannot be faked by editing JSON artifacts.

## Failure domain

Primary:

```text
evidence-integrity
```

Secondary:

```text
trust-boundary
```

## Required tamper cases

```text
1. bad facts + accepted: true
2. good facts + accepted: false
3. diagnostics present + lspErrorCount: 0
4. compiler diagnostics present + compilerErrorCount: 0
5. graph contains diagnostic node + accepted: true
6. diffNonEmpty: false + accepted: true
7. logger refs unresolved + accepted: true
```

## Tiers

### Failure-domain fixture

Run the full tamper matrix on the current bad candidate.

### Tier 1: tiny

Current fixture.

### Tier 2: medium

Multi-file fixture.

### Tier 3: large/synthetic

Generated fixture.

## Pass criteria

* All tampered accepted states fail CUE validation.
* Shape-valid facts remain distinguishable from accepted facts.
* Each failed tamper case reports the violated constraint.

---

# Slice 4: compiler/LSP contradiction validation

## Purpose

Ensure CUE rejects inconsistent semantic/build facts.

## Failure domain

Primary:

```text
evidence-integrity
```

Secondary:

```text
tool-interface
```

## Contradiction cases

```text
compiler.errorCount == 0, compiler.diagnostics non-empty
lsp.errorCount == 0, lsp.diagnostics non-empty
compiler clean, LSP dirty
LSP clean, compiler dirty
diagnostic semantic node exists, lsp.errorCount == 0
```

## Tiers

### Failure-domain fixture

Construct contradictory fact files directly.

### Tier 1: tiny

Current fixture.

### Tier 2: medium

Multi-file fixture.

### Tier 3: large/synthetic

Generated fixture.

## Pass criteria

* CUE rejects all contradictions.
* Good candidate remains accepted.
* Bad candidate remains rejected with explanatory graph.

---

# Slice 5: graph/report consistency

## Purpose

Make the graph constrained evidence, not decorative output.

## Failure domain

Primary:

```text
model-design
```

Secondary:

```text
evidence-integrity
```

## Required checks

Accepted candidate must not have:

```text
diagnostic nodes
unresolved reference nodes
diagnoses edges
missing-binding requires edges
scope-violation nodes
```

Accepted candidate must have:

```text
required resolves-to edges
required compiler-clean gate
required LSP-clean gate
required patch layers
```

## Tiers

### Failure-domain fixture

Accepted report with graph-visible diagnostic.

### Tier 1: tiny

Current fixture.

### Tier 2: medium

Multi-file fixture.

### Tier 3: large/synthetic

Generated fixture.

## Pass criteria

* Accepted true cannot coexist with graph-visible failures.
* Rejected candidates have at least one explanatory failure path.
* Graph/report consistency is validated by CUE.

---

# Slice 6: patch-layer graph consistency

## Purpose

Ensure patch layers implement obligations rather than merely describe them.

## Failure domain

Primary:

```text
model-design
```

Secondary:

```text
patch-materialization
```

## Required checks

```text
every obligation has an implementing patch layer
every patch layer implements at least one obligation or gate
must-precede edges are present
consumes symbols have earlier producer layers
validation layer follows mutation layers
```

## Tiers

### Failure-domain fixture

Create a patch plan missing one obligation implementation.

### Tier 1: tiny

Current logger migration.

### Tier 2: medium

Multi-file logger migration.

### Tier 3: large/synthetic

Generated files with repeated obligations.

## Pass criteria

* CUE rejects orphan obligations.
* CUE rejects orphan patch layers.
* CUE rejects missing must-precede relationships.
* Good patch plan remains accepted.

---

# Slice 7: topological ordering and cycle detection

## Purpose

Move from fixture-static ordering to dependency-validated ordering.

## Failure domain

Primary:

```text
complexity
```

Secondary:

```text
model-design
```

## Boundary

Helper script may compute topological order.

CUE must validate:

```text
declared order respects all must-precede edges
cycles are rejected
layer IDs are deterministic
```

## Tiers

### Failure-domain fixture

Create a cycle:

```text
A -> B -> C -> A
```

Expected:

```text
cycle detected
CUE rejects or helper emits failed graph fact
```

### Tier 1: tiny

Three-layer logger plan.

### Tier 2: medium

Five-to-seven layer synthetic obligation graph.

### Tier 3: large/synthetic

Fifty-plus obligation graph.

## Pass criteria

* Valid graphs produce deterministic layer order.
* Cycles reject.
* CUE validates helper-produced order.

---

# Slice 8: patch emission

## Purpose

Convert planned layers into reviewable patch files.

## Failure domain

Primary:

```text
patch-materialization
```

Secondary:

```text
tool-interface
```

## Target artifacts

```text
patchplan/out/patches/
  001-provide-logger-binding.patch
  002-rewrite-console-calls.patch
```

## Tiers

### Failure-domain fixture

Generate a patch that claims to implement an obligation but does not.

### Tier 1: tiny

Current fixture.

### Tier 2: medium

Multi-file fixture.

### Tier 3: large/synthetic

Generated fixture.

## Pass criteria

* Patch files exist.
* Patch metadata maps patch files to layers.
* `git apply --check` passes in order.
* CUE validates patch metadata against patch plan.

---

# Slice 9: patch replay

## Purpose

Prove ordered patches reproduce the accepted candidate from clean base.

## Failure domain

Primary:

```text
patch-materialization
```

Secondary:

```text
evidence-integrity
```

## Tiers

### Failure-domain fixture

Apply patches out of order.

Expected:

```text
apply fails or replayed candidate rejects
```

### Tier 1: tiny

Current fixture.

### Tier 2: medium

Multi-file fixture.

### Tier 3: large/synthetic

Generated fixture.

## Pass criteria

* Fresh base + ordered patches = accepted candidate.
* Fresh base + missing patch = rejected candidate.
* Fresh base + out-of-order patches = failure or rejected candidate.
* Replay facts match candidate facts or explain differences.

---

# Slice 10: scope policy enforcement

## Purpose

Ensure declared change scope is enforced.

## Failure domain

Primary:

```text
model-design
```

Secondary:

```text
architecture-quality
```

## Tiers

### Failure-domain fixture

Candidate touches out-of-scope file:

```text
README.md
package.json
src/vendor/*
```

### Tier 1: tiny

One out-of-scope file.

### Tier 2: medium

Several out-of-scope files.

### Tier 3: large/synthetic

Many in-scope files plus one out-of-scope file.

## Pass criteria

* Out-of-scope touch rejects.
* Graph includes scope violation node/edge.
* Accepted true requires no scope violations.

---

# Slice 11: idempotence and determinism

## Purpose

Ensure repeated runs produce stable artifacts.

## Failure domain

Primary:

```text
evidence-integrity
```

Secondary:

```text
engineering-quality
```

## Tiers

### Failure-domain fixture

Introduce unstable ordering or timestamped output.

### Tier 1: tiny

Run current fixture three times.

### Tier 2: medium

Run multi-file fixture three times.

### Tier 3: large/synthetic

Run generated fixture three times.

## Pass criteria

* Same inputs produce same graph/model/report/patch-layer outputs.
* No timestamps in validated artifacts.
* Semantic node IDs and edge order are stable.

---

Below are the two bounded slices as separate implementation prompts.

---

# Slice 12 — Lifecycle proof harness

## Current state

This is now:

```text
patchplan can run individual slice proofs:
  topological-order
  patch-emission
  patch-replay
  scope-policy
  idempotence
```

But the system needs a stable harness proving that outputs are:

```text
preserved
replayable
CUE-accepted or CUE-rejected correctly
idempotent across reruns
summarized as lifecycle evidence
```

Slice 12 is **not** the initial thesis proof. It is the proof harness that makes Slice 13 trustworthy.

## Target state

Slice 12 should establish:

```text
lifecycle acceptance =
  all required reports preserved
  + good path CUE-accepted
  + bad path CUE-rejected
  + replay artifacts present
  + idempotence stable
  + lifecycle report emitted
```

Expected final verification:

```text
expected preserved reports: 20
missing reports: 0
lifecycle accepted: true
idempotence: 3 full passes across tiny/medium/large
stable hashes: true
stable semantic ordering: true
```

## Path of least resistance

Keep this as a lifecycle/reporting slice.

Do not introduce new semantics. Use existing slice outputs and make the lifecycle layer validate them.

Required scripts:

```sh
patchplan/scripts/demo good
patchplan/scripts/demo bad
patchplan/scripts/topological-order-slice
patchplan/scripts/patch-emission-slice
patchplan/scripts/patch-replay-slice
patchplan/scripts/scope-policy-slice
patchplan/scripts/idempotence-slice
patchplan/scripts/lifecycle-slice
```

Required generated files:

```text
patchplan/out/reports/lifecycle.json
patchplan/out/reports/lifecycle.md

patchplan/out/reports/
patchplan/out/patches/
patchplan/out/graph/
patchplan/out/candidate/
```

CUE schemas/validators should cover:

```text
topology
patch-emission
patch-replay
scope-policy
patch-order
patch-manifest
scope facts
idempotence
lifecycle
```

## Heads-up

Do **not** make Slice 12 carry the theory proof.

Keep out of scope:

```text
SCIP
tree-sitter
compiler adapters
symbol refactoring
graph mutation semantics
nearest common dominator
general patch synthesis
```

Known limitations are acceptable:

```text
LSP remains editor-scoped / focused adapter boundary.
Patch emission remains migration-shape specific.
```

## Codex-ready prompt

```text
Implement Slice 12: lifecycle proof harness for patchplan.

Current state:
- Existing slice scripts cover:
  - topological-order
  - patch-emission
  - patch-replay
  - scope-policy
  - idempotence
- Good and bad demo paths exist.
- Patch artifacts, graph artifacts, candidate artifacts, and reports are emitted under patchplan/out/.
- Slice 12 should be the lifecycle proof harness, not the initial thesis proof.

Target state:
- Add or complete a lifecycle slice that proves preserved reports, replay, idempotence, and CUE acceptance.
- The lifecycle slice must emit:
  - patchplan/out/reports/lifecycle.json
  - patchplan/out/reports/lifecycle.md
- The lifecycle report must preserve and summarize reports from:
  - topological-order
  - patch-emission
  - patch-replay
  - scope-policy
  - idempotence
- Expected preserved reports: 20.
- Missing reports must be counted explicitly.
- Good candidate must be accepted by CUE.
- Bad candidate must be rejected by CUE intentionally.
- Idempotence must run 3 full passes across tiny/medium/large and report stable hashes plus stable semantic ordering.

Commands to run:
- patchplan/scripts/demo good
- patchplan/scripts/demo bad
- patchplan/scripts/topological-order-slice
- patchplan/scripts/patch-emission-slice
- patchplan/scripts/patch-replay-slice
- patchplan/scripts/scope-policy-slice
- patchplan/scripts/idempotence-slice
- patchplan/scripts/lifecycle-slice

CUE work:
- Add or verify schemas/validators for:
  - topology
  - patch-emission
  - patch-replay
  - scope-policy
  - patch-order
  - patch-manifest
  - scope facts
  - lifecycle
  - idempotence
- Avoid broad semantic expansion.
- Do not introduce SCIP, tree-sitter, compiler adapter, LSP, or graph mutation work in this slice.

Acceptance:
- patchplan/scripts/demo good reports accepted: true.
- patchplan/scripts/demo bad reports accepted: false and fails CUE intentionally.
- patchplan/scripts/lifecycle-slice reports:
  - expected preserved reports: 20
  - missing reports: 0
  - lifecycle accepted: true
- patchplan/scripts/idempotence-slice reports:
  - 3 full passes
  - tiny/medium/large covered
  - stable hashes
  - stable semantic ordering
- Generated files include:
  - patchplan/out/reports/lifecycle.json
  - patchplan/out/reports/lifecycle.md
  - preserved slice/tier reports under patchplan/out/reports/
  - patch artifacts under patchplan/out/patches/
  - graph/model/report artifacts under patchplan/out/graph/, patchplan/out/candidate/, and patchplan/out/reports/

Report back with:
- commands run
- whether good passed
- whether bad rejected
- generated files
- CUE schema/validator changes
- dependency/tool limitations
- final lifecycle verification
- idempotence verification
```

## Slice 12 acceptance sentence

```text
Slice 12 is complete when lifecycle acceptance proves that all required slice reports are preserved, replay/idempotence are stable, good is CUE-accepted, and bad is CUE-rejected.
```

---

# Slice 13 — Initial thesis proof: CUE bottom-up patch stack

## Current state

The thesis is now:

```text
CUE provides an ordered patch stack plan,
respecting bottom-up scope.
```

Slice 12 proves the lifecycle harness. Slice 13 should prove the thesis directly.

The system already has some ordering, patch-emission, patch-replay, scope-policy, and lifecycle machinery. But it now needs a focused proof that CUE can accept or reject a patch stack based on bottom-up scope constraints.

## Target state

Slice 13 should prove:

```text
Given scoped patch steps,
CUE validates a deterministic ordered patch stack,
accepts valid bottom-up order,
and rejects invalid top-down or dependency-inverted order.
```

Core invariant:

```text
lower-scope patches must precede higher-scope patches
when the higher-scope patch depends on them.
```

Example accepted order:

```text
symbol/private leaf
  → file/local adapter
  → package boundary
  → module/workspace integration
```

Example rejected order:

```text
workspace integration
  → package boundary
  → file/local adapter
  → symbol/private leaf
```

## Path of least resistance

Start with synthetic patch steps. Do not require SCIP/tree-sitter/compiler yet.

Define a small scope lattice:

```text
symbol    = 10
file      = 20
package   = 30
module    = 40
workspace = 50
```

Define a patch stack IR:

```cue
#PatchStep: {
	id: string

	scope: "symbol" | "file" | "package" | "module" | "workspace"

	operation: "rename" | "move" | "delete" | "extract" | "inline" | "adapt"

	touches: [...string]

	dependsOn: [...string]

	order: int

	evidence?: {
		compiler?: string
		scip?:     string
		syntax?:   string
	}
}
```

Define a stack plan:

```cue
#PatchStackPlan: {
	steps: [...#PatchStep]
	accepted: bool
}
```

The first proof can be purely structural:

```text
valid scope rank order
valid dependsOn references
no dependency points forward
no parent/higher-scope patch precedes required child/lower-scope patch
deterministic semantic order
```

## Heads-up

Do not overbuild this into semantic code understanding.

Keep out of scope:

```text
SCIP integration
tree-sitter integration
compiler adapter integration
LSP integration
actual rename execution
graph mutation algebra
nearest common dominator
cross-repo impact
large graph traversal
```

The purpose is to prove that **CUE owns the ordered patch stack plan**, not that CUE understands source code.

Adapters can come later as fact producers.

## Codex-ready prompt

```text
Implement Slice 13: initial thesis proof — CUE bottom-up patch stack.

Theory:
- CUE provides an ordered patch stack plan, respecting bottom-up scope.

Current state:
- Slice 12 provides the lifecycle proof harness.
- Existing slices cover topological ordering, patch emission, patch replay, scope policy, idempotence, and lifecycle reporting.
- The next proof should directly validate the thesis:
  - CUE accepts valid bottom-up scoped patch stacks.
  - CUE rejects invalid top-down or dependency-inverted patch stacks.

Target state:
- Add a CUE-backed patch stack plan contract.
- Define a minimal scope lattice:
  - symbol: 10
  - file: 20
  - package: 30
  - module: 40
  - workspace: 50
- Define a patch stack IR with:
  - id
  - scope
  - operation
  - touches
  - dependsOn
  - order
  - optional evidence refs
- Add good and bad fixtures:
  - good: symbol -> file -> package -> workspace
  - bad: workspace -> package -> file -> symbol
  - bad dependency: a step depends on a later step
  - bad scope: a higher-scope dependent patch appears before required lower-scope patch
- CUE must validate the good stack and reject the bad stacks.

Required outputs:
- patchplan/out/reports/patch-stack-plan-good.json
- patchplan/out/reports/patch-stack-plan-good.md
- patchplan/out/reports/patch-stack-plan-bad.json
- patchplan/out/reports/patch-stack-plan-bad.md
- optional:
  - patchplan/out/reports/patch-stack-plan-summary.json
  - patchplan/out/reports/patch-stack-plan-summary.md

Required CUE contracts:
- #ScopeRank
- #PatchStep
- #PatchStackPlan
- #PatchStackValidation
- bottom-up ordering constraint
- dependency existence constraint
- dependency-before-dependent constraint
- deterministic order constraint

Constraints:
- Keep this as a pure thesis proof.
- Do not add SCIP, tree-sitter, compiler adapter, or LSP integration.
- Do not implement real patch application.
- Do not implement graph mutation semantics.
- Do not implement nearest common dominator logic.
- Do not expand patch emission beyond existing migration-shape-specific behavior.
- Adapters may later provide facts, but this slice should use synthetic patch-stack fixtures.

Expected command shape:
- Add a script such as:
  - patchplan/scripts/patch-stack-plan-slice
- The script should:
  - generate or validate the good patch stack fixture
  - generate or validate bad patch stack fixtures
  - run CUE validation
  - emit JSON and Markdown reports
  - return non-zero only for unexpected failures, not for intentional negative fixtures

Acceptance:
- Good bottom-up stack is accepted.
- Top-down stack is rejected.
- Forward dependency stack is rejected.
- Higher-scope-before-required-lower-scope stack is rejected.
- Reports clearly state:
  - accepted true/false
  - scope order
  - dependency order
  - rejection reason for bad fixtures
- Lifecycle can preserve the patch-stack-plan report after Slice 13 is connected to the lifecycle harness.
- Existing Slice 12 behavior remains green.

Report back with:
- files changed
- commands run
- good stack result
- bad stack result
- CUE schemas added
- reports generated
- whether Slice 12 lifecycle remains green
- known limitations
```

## Slice 13 acceptance sentence

```text
Slice 13 is complete when CUE accepts a valid bottom-up patch stack, rejects invalid scope/dependency orderings, emits patch-stack-plan reports, and preserves Slice 12 lifecycle stability.
```

---

# Combined sequence

Run Slice 12 first:

```text
prove lifecycle harness
```

Then run Slice 13:

```text
prove initial thesis under that harness
```

The dependency is:

```text
Slice 12:
  Can we trust the evidence lifecycle?

Slice 13:
  Can CUE validate the bottom-up ordered patch stack?
```

Compact stack:

```text
Slice 12 = proof harness
Slice 13 = initial thesis proof
```
