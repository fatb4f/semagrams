# Eval-first CUE control for semagrams

## Purpose

This document records the control doctrine for `semagrams` CUE implementation slices.

The project shape is:

```text
CUE source/value
  -> ObservedDPI datoms
  -> CUE acceptance over DPI
  -> CertifiedDPI tx
  -> backend patch projection
```

The useful implementation rule is not to ask for vocabulary first. The useful rule is:

```text
Eval-first prompts produce structural CUE.
Vocabulary-first prompts produce decorative schema.
Review-first prompts produce metadata.
```

For `semagrams`, every slice should start from the eval surface that must pass or bottom.

---

## Target invariants

The first DPI lowering slice must make valid observed DPI export:

```cue
validObservedDPI & #AcceptedObservedDPI
```

Invalid observed DPI must fail by real CUE intersection:

```cue
negativeFixtures.<fixture>.input & #AcceptedObservedDPI
```

Backend projection must reject uncertified DPI structurally:

```cue
negativeFixtures.backendWithoutCertificate.input & #BackendProjection
```

The refusal must happen because the input shape contradicts the accepted/certified type, not because an operator-supplied flag declares the input invalid.

---

## Control model

```text
#ObservedDPI
  -> broad lowering substrate
  -> can represent valid and invalid adapter output
  -> tx.kind == "cue-lowering"
  -> no transition / operation / evidence / certificate

#RegisteredDPI
  -> registry-typed datom validation
  -> every datom attribute resolves through attributes
  -> every datom value matches attribute.valueType
  -> every primitive and datom is authority:false

#AcceptedObservedDPI
  -> #ObservedDPI & #RegisteredDPI
  -> valid CUE-lowering observation surface

#CertifiedDPI
  -> transition/certificate-bound tx
  -> has transition, operation, evidence, certificate
  -> eligible for backend projection

#BackendProjection
  -> consumes #CertifiedDPI only
  -> emits backend artifacts as authority:false projections

_negativeBottomChecks
  -> real CUE intersections
  -> expected to bottom
```

Critical split:

```text
observed bad lowering output is representable
  ∧
accepted DPI is narrow
  =
bottom
```

---

## DPI-specific forbidden attractors

Do not implement invalidity as review metadata:

```cue
bottomCheckSurface: {
  expression: "negativeFixtures.bad.input & #AcceptedObservedDPI"
  expectedBottom: true
}
```

Do not implement invalidity as operator-controlled booleans:

```cue
datomChecks: {
  unknownAttribute: true
  missingOrigin: true
  rawBottomValue: true
}
```

Do not make backend success authoritative:

```text
wrong:
  backend patch emitted successfully
  -> DPI is valid

right:
  DPI validates under CUE
  -> CertifiedDPI exists
  -> backend patch may be projected
```

Do not allow raw bottom to leak as ordinary data:

```cue
value: "_|_" // must reject as #SafeString
```

Correct bottom witness shape:

```cue
value: {
  kind: "cue-bottom"
  path: "cue:path:#Example.bad"
  error: "conflicting values"
}
```

---

## Required eval-first prompt shape

Use this pattern for Codex slices:

```text
Implement a bounded CUE slice.

Start from evals, not vocabulary.

Required positive evals:
- cue vet ./patchplan/cue
- cue export ./patchplan/cue -e validObservedDPI
- cue export ./patchplan/cue -e acceptedObservedDPIReport

Required negative evals:
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badAuthority'
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badMissingOrigin'
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badUnknownAttribute'
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badValueTypeMismatch'
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badRawBottomString'
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badPartialWithoutLoss'
- ! cue export ./patchplan/cue -e '_negativeBottomChecks.badBackendWithoutCertificate'

Required model split:
- #ObservedDPI is broad enough to represent invalid lowering output.
- #RegisteredDPI is narrow enough to reject invalid datoms structurally.
- #AcceptedObservedDPI is #ObservedDPI & #RegisteredDPI.
- #CertifiedDPI requires transition, operation, evidence, and certificate.
- #BackendProjection consumes #CertifiedDPI, never #ObservedDPI.
- #NegativeFixture.input is typed as the observed or backend-projection input type.
- _negativeBottomChecks contains real intersections.

Forbidden attractors:
- diagnostic boolean fields used as authority
- expectedBottom without real intersections
- stringified CUE expressions
- bottomCheckSurface.expression
- review-only metadata as proof
- fake/default provenance
- placeholder evidence accepted as admissible evidence
- manually supplied derived values accepted as valid
- side-package schema sprawl
- backend patch success treated as validation
```

---

## Required fixtures

The first DPI slice should include negative fixtures for these classes:

| Fixture | Required contradiction |
|---|---|
| `badAuthority` | `authority: true` contradicts DPI `authority: false` |
| `badMissingOrigin` | datom/origin lacks required `digest` |
| `badUnknownAttribute` | datom attribute has no registry entry |
| `badValueTypeMismatch` | attribute registry says `entity-ref`, value is raw string |
| `badRawBottomString` | value is ordinary string `"_|_"` instead of `#CueBottomWitness` |
| `badPartialWithoutLoss` | `lowering.completeness: "partial"` without `loss` |
| `badBackendWithoutCertificate` | backend projection receives observed/uncertified DPI |

Each fixture should be a real input object. The bottom check should be an evaluated intersection.

Example:

```cue
_negativeBottomChecks: {
  badValueTypeMismatch:
    negativeFixtures.badValueTypeMismatch.input & #AcceptedObservedDPI
}
```

Not:

```cue
negativeFixtures: {
  badValueTypeMismatch: {
    expectedBottom: true
  }
}
```

---

## Post-slice repo shape checks

The issue template should double as a post-slice validation checklist.

Minimum repo shape for the first DPI slice:

```text
.github/ISSUE_TEMPLATE/cue-implementation-slice.md

docs/eval-first-cue-control.md

patchplan/cue/dpi.schema.cue
patchplan/cue/dpi.attributes.cue
patchplan/cue/cueexpr.schema.cue
patchplan/cue/cueexpr.accept.cue
patchplan/cue/cueexpr.report.cue

patchplan/cue/fixtures/valid_observed_dpi.cue
patchplan/cue/fixtures/bad_authority.cue
patchplan/cue/fixtures/bad_missing_origin.cue
patchplan/cue/fixtures/bad_unknown_attribute.cue
patchplan/cue/fixtures/bad_value_type_mismatch.cue
patchplan/cue/fixtures/bad_raw_bottom_string.cue
patchplan/cue/fixtures/bad_partial_without_loss.cue
patchplan/cue/fixtures/bad_backend_without_certificate.cue

patchplan/scripts/extract-cue-ast-facts
patchplan/scripts/extract-cue-value-facts
patchplan/scripts/lower-cue-dpi
patchplan/scripts/validate-dpi
```

Forbidden first-slice roots:

```text
backend/
graphstore/
sparql/
cypher/
gremlin/
rdf-patch/
```

Backend emitters can be named as future projection targets, but should not be implemented before `#CertifiedDPI` and backend rejection fixtures exist.

---

## Design conclusion

`semagrams` should use the same control lesson as the accepted factory issue-28 run:

```text
Do not ask the agent to understand the architecture first.
Ask it to satisfy the eval surface first.
```

For DPI work, the primitive unit of implementation is:

```text
valid observed export
+
invalid observed fixture intersection that bottoms
+
backend projection rejection for uncertified DPI
+
forbidden attractor search
```

Only after those surfaces exist should the slice expand into richer adapters, graph stores, backend emitters, projection formats, or promotion workflows.
