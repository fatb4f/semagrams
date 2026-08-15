# Semagrams Codex Architecture

This note records the crate-level integration shape for a Rust `semagrams` implementation that exposes Codex-facing adapter surfaces while keeping CUE and datom semantics on explicit authority boundaries.

## Schematic

```text
codex
  │
  ▼
semagrams-codex adapter
  │
  ▼
semagrams-core Rust crate
  ├─ fact ingestion
  │   ├─ ast-grep / tree-sitter facts
  │   ├─ tsc / rustc / lsp facts
  │   └─ git facts
  │
  ├─ canonical datom store
  │   └─ Vec<Datom> / indexed relation DB
  │
  ├─ CUE bridge
  │   ├─ export facts.json
  │   ├─ cue vet / cue export, or CUE FFI later
  │   └─ acceptance report
  │
  └─ optional Steel runtime
      ├─ read-only datom query functions
      ├─ pure transform functions
      ├─ projection templates
      └─ Codex prompt/report helpers
```

## Boundary contract

- `semagrams-core` owns typed ingestion, canonical datom storage, projections, and adapter orchestration.
- The CUE bridge owns constraint validation, export surfaces, and acceptance reports.
- Steel, if embedded, is an optional extension runtime for read-only datom queries, pure transforms, projection templates, and Codex prompt/report helpers.
- Steel must not own CUE semantics, canonical datom mutation, or final acceptance authority.

## Control invariant

```text
CUE = constraint authority
Rust = typed host/orchestrator
Datoms = canonical intermediate representation
Steel = optional programmable adapter/plugin layer
Codex = consumer/operator interface
```
