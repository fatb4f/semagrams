# Patchplan Probe

This is a tiny proof-of-concept workflow for CUE-backed relational patch planning over a TypeScript repo.

## What This Proves

- CUE can import normalized CST-derived facts.
- CUE can derive a graph and candidate model.
- Compiler, LSP, and VCS facts can be normalized and validated.
- Candidate acceptance can be enforced via CUE unification.

## What This Does Not Prove

- Raw Tree-sitter CST JSON import.
- Full LSP references/definitions.
- FUSE projection.
- Generic source generation.
- Multi-language support.

## Why ast-grep Is Used First

- It is Tree-sitter-backed.
- It emits structured JSON.
- It avoids raw parser setup friction.

## Control-Surface Model

Patchplan treats the source tree and generated artifacts as an observed plant, not as self-authorizing outputs.

```text
Sensors:
  ast-grep
  compiler
  LSP
  VCS
  patch replay
  idempotence

Normalizers:
  scripts/adapters emit facts only

Controller / authority:
  CUE

Observer:
  candidate re-observation after materialization

Gate:
  cue vet / cue export acceptance overlays

Failure mode:
  bottom / conflict / rejected report
```

The control boundary is:

```text
scripts/adapters produce evidence
CUE derives graphs, reports, and acceptance constraints
reports explain acceptance or rejection
```

Scripts may preserve, normalize, and summarize facts. They must not become the semantic authority for final acceptance.

## Lattice Interpretation

The useful lattice interpretation is theoretical scaffolding, not a runtime dependency.

```text
partial information from tools/adapters
  -> ordered evidence domains
  -> CUE unification / bottom / subsumption
  -> accepted or rejected transition witness
```

Relevant concepts:

| Concept | Patchplan mapping |
|---|---|
| Constraint languages as ordered structures / abstract domains | `ast-grep`, compiler, LSP, VCS, replay, scope, and DPI-lowering outputs as separate fact domains combined by CUE. |
| Closure over sequences of constraints | Lifecycle reports, repeated probes, idempotence, and replay as validation traces. |
| Configuration trace assertions | Graph/report consistency and transition evidence across generated artifacts. |
| Information / definedness lattices | Explicit distinction between absent, unknown, failed, rejected, accepted, and bottom. |

Theory anchors:

- Modular Constraint Solver Cooperation via Abstract Interpretation — https://arxiv.org/abs/2008.01415
- Abstract Interpretation of Temporal Concurrent Constraint Programs — https://arxiv.org/abs/1312.2552
- On the Specification of Constraints for Dynamic Architectures — https://arxiv.org/abs/1703.06823

## Pertinent Issues

The branch tracks two pertinent issue surfaces:

```text
Issue #1:
  CUE-to-DPI lowering authority
  -> observed facts/datoms
  -> accepted/certified DPI
  -> backend projection admission

Issue #2:
  Rust/Codex architecture
  -> typed evidence packets
  -> CUE evaluator boundary
  -> admitted Codex/operator reports
```

The shared obligations are:

```text
Lifecycle obligation:
  Scripts/adapters preserve and normalize evidence.
  CUE derives or gates lifecycle acceptance.
  Missing, tampered, unstable, or contradictory evidence rejects.

Patch-stack obligation:
  Adapter facts describe patch steps.
  CUE validates scope rank, dependency references, bottom-up order, determinism, and rejection reasons.
```

## Lifecycle Acceptance Target

Lifecycle acceptance should converge toward:

```text
facts/reports/*
  -> cue export -e lifecycle
  -> lifecycle.json
  -> cue vet lifecycle.cue lifecycle.json
```

The desired invariant is:

```text
Lifecycle acceptance is CUE-derived or CUE-gated from preserved evidence reports,
not trusted from script-local booleans.
```

A valid lifecycle proof should preserve reports, verify good-path acceptance, verify bad-path rejection, preserve replay artifacts, prove idempotence, and reject missing or contradictory evidence.

## Bottom-Up Patch-Stack Target

Patch-stack validation should converge toward:

```text
adapter patch-stack facts
  -> CUE normalization
  -> CUE validation
  -> accepted/rejected patch-stack report
```

Scope rank order:

```text
symbol < file < package < module < workspace
```

The desired invariant is:

```text
Adapter emits raw patch-stack facts.
CUE computes validation.
Scripts/Rust may summarize, but do not decide accepted/rejected except by carrying CUE output.
```

A valid patch stack requires:

- known scope ranks;
- dependency references that resolve to known steps;
- no forward dependencies;
- bottom-up dependency order;
- deterministic order;
- no duplicate step IDs;
- structured rejection reasons for invalid fixtures.

## Where Next Slices Fit

1. Real LSP documentSymbol/references adapter.
2. Raw tree-sitter parse artifact import.
3. Patch-stack commit generation.
4. Richer dependency graph.
5. CUE-derived lifecycle report generation.
6. CUE-native adapter patch-stack validation as the authority surface.

## Demo

```bash
patchplan/scripts/demo good
patchplan/scripts/demo bad
```
