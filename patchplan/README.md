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

## Where Next Slices Fit

1. Real LSP documentSymbol/references adapter.
2. Raw tree-sitter parse artifact import.
3. Patch-stack commit generation.
4. Richer dependency graph.

## Demo

```bash
patchplan/scripts/demo good
patchplan/scripts/demo bad
```
