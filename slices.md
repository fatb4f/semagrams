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

# Slice 12: lifecycle report

## Purpose

Make validation status self-reporting and reviewable.

## Failure domain

Primary:

```text
UX-cognitive-load
```

Secondary:

```text
evidence-integrity
```

## Target artifacts

```text
patchplan/out/reports/lifecycle.json
patchplan/out/reports/lifecycle.md
```

## Report must include

```text
completed probes
pass/fail status
failure domain
scale tier
artifacts generated
green-light authority
known limitations
next recommended probe
```

## Tiers

### Failure-domain fixture

Lifecycle report includes a known failed probe and explains the domain.

### Tier 1: tiny

Current probe lifecycle.

### Tier 2: medium

Multi-file lifecycle.

### Tier 3: large/synthetic

Generated lifecycle.

## Pass criteria

* Lifecycle report is generated.
* Failed probes are classified by failure domain.
* Passing probes identify the authority source.
* Report is usable for reassessment.

---

# Completion criteria

This issue is complete when the probe can answer:

```text
1. Is the candidate accepted?
2. Why or why not?
3. Which facts support that decision?
4. Which graph edges explain the decision?
5. Which patch layer addresses the missing obligation?
6. Can the patch layers be replayed from clean base?
7. Does this remain stable across size tiers?
8. Which failure domain applies when it fails?
```

## Final reassessment checkpoint

After Slice 12, reassess:

```text
Is patchplan-probe still a fixture-specific proof,
or has it become a reusable patch-planning substrate?
```

```
```
