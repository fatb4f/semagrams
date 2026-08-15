---
name: CUE implementation slice
about: Implement a bounded CUE contract slice with explicit authority, eval surfaces, fixtures, and validation.
title: "cue: implement "
labels: cue, contract, implementation
---

# CUE implementation slice

This issue defines a bounded CUE implementation slice.

The goal is not to add vocabulary only. The patch must introduce a usable contract surface:

```text
authority primitives
  -> admissible shapes
  -> concrete instances / fixtures
  -> exported eval surfaces
  -> validation commands
```

Keep the slice small. Do not expand into unrelated adapters, generators, materializers, or architecture redesign.

# Canonical CUE implementation model

```cue
package issue

#CUEImplementationSlice: {
  contract: {
    path: string
    package: string
    slice: string

    authority: {
      owns: [...string]
      doesNotOwn: [...string]
    }

    boundaries: {
      adapters: {
        authority: false
        role: "observe/project/execute declared behavior only"
      }
      generated: {
        authority: false
        role: "downstream projection or materialized evidence only"
      }
      runtime: {
        authority: false
        role: "external substrate, not contract truth"
      }
    }
  }

  rootQuestion: {
    id: "N0.contract-question"
    text: "What CUE authority must exist so this state, transition, or projection is representable and checkable?"
  }

  primitives: [...{
    name: string
    role: string
    requiredFields: [...string]
    constraints: [...string]
  }]

  surfaces: {
    admissible: [...string]
    observed: [...string]
    candidates: [...string]
    fixtures: [...string]
    checks: [...string]
    publicExports: [...string]
  }

  constraints: {
    noVocabularyOnlyPatch: true
    noDiagnosticBooleanAuthority: true
    noReviewMetadataAsProof: true
    noStringifiedEvalExpressions: true
    noGeneratedArtifactAsAuthority: true
    noAdapterLocalPolicyAuthority: true
    noShellOnlySemanticValidation: true
    noSidePackageSprawl: true
  }

  dag: {
    nodes: {
      N0: {
        id: "N0.contract-question"
        question: rootQuestion.text
      }
      N1: {
        id: "N1.authority-boundary"
        question: "What does CUE own, and what remains outside this slice?"
      }
      N2: {
        id: "N2.primitive-model"
        question: "Which first-class CUE primitives are introduced or extended?"
      }
      N3: {
        id: "N3.admissible-surface"
        question: "Which candidate/admissible surfaces constrain valid state?"
      }
      N4: {
        id: "N4.fixtures"
        question: "Which valid and invalid concrete examples exercise the contract?"
      }
      N5: {
        id: "N5.eval-surfaces"
        question: "Which public exports and check surfaces prove the slice works?"
      }
      N6: {
        id: "N6.validation"
        question: "Which commands validate the CUE package and its expected bottoms?"
      }
      N7: {
        id: "N7.next-state"
        question: "What bounded admitted state exists after this slice?"
      }
    }

    allowedEdges: [
      "N0 -> N1",
      "N1 -> N2",
      "N2 -> N3",
      "N3 -> N4",
      "N3 -> N5",
      "N4 -> N5",
      "N5 -> N6",
      "N6 -> N7",
    ]

    forbiddenEdges: [
      "vocabulary -> accepted slice without eval surface",
      "diagnostic boolean -> authority",
      "review metadata -> proof",
      "stringified expression -> check",
      "generated artifact -> authority",
      "adapter output -> policy authority",
      "shell command -> semantic authority",
    ]
  }

  acceptanceCriteria: {
    rootQuestionAnsweredBeforeImplementation: true
    authorityBoundaryDeclared: true
    primitiveModelDeclared: true
    admissibleSurfaceDeclared: true
    validFixtureExports: true
    publicEvalSurfaceExports: true
    negativeFixturesBottomIfPresent: true
    forbiddenAttractorSearchPasses: true
    validationCommandsReported: true
  }
}
```

# Issue-specific DAG instantiation

```cue
package issue

issue: #CUEImplementationSlice & {
  contract: {
    path: ""
    package: ""
    slice: ""

    authority: {
      owns: [
        "",
      ]
      doesNotOwn: [
        "",
      ]
    }
  }

  dag: nodes: {
    N1: answer: ""
    N2: answer: ""
    N3: answer: ""
    N4: answer: ""
    N5: answer: ""
    N6: answer: ""
    N7: answer: ""
  }
}
```

# Problem / missing contract

```text
Current state:
  - 

Missing contract surface:
  - 

This slice should implement:
  - 

This slice must not implement:
  - 
```

# Authority boundary

```text
CUE authority:
  - schemas / admissible states / invariants:
  - fixtures / eval surfaces:
  - generated contract views, if any:

Not CUE authority in this slice:
  - runtime execution:
  - VCS mutation:
  - shell materialization:
  - external adapter behavior:

Adapter or projection boundary:
  - adapter may observe/project/execute declared behavior only
  - adapter must not become topology or policy authority
```

# Primitive model

```text
Required primitives:
  - #<PrimitiveA>
      role:
      required fields:
      constraints:

  - #<PrimitiveB>
      role:
      required fields:
      constraints:

  - #<CandidateOrInstance>
      role: admissible instance shape
      closed: yes/no
      derived values:
      rejected values:
```

Primitive rules:

```text
- prefer structural constraints over boolean review flags
- derive values algebraically when the value is determined by policy
- keep observed/fact types broader than admissible/candidate types when invalid observations must be represented
- use close(...) on candidate/admissible surfaces when extra fields must be rejected
```

# File plan

```text
Expected files:
  - <contract-path>/root.cue
      purpose: core primitives and candidate/admissible surfaces

  - <contract-path>/fixtures.cue
      purpose: valid baseline instances and negative fixtures if needed

  - <contract-path>/checks_test.cue
      purpose: eval/check surfaces

  - <contract-path>/<public>.cue
      purpose: public issue/slice exports, if needed
```

Package rule:

```cue
package <package>
```

Do not create side packages unless this issue explicitly authorizes them.

# Public eval surfaces

```cue
<validBaselineExpr>
<publicSliceExpr>
<gateOrReportExpr>
```

Required positive validation:

```bash
cue vet ./<contract-path>
cue export ./<contract-path> -e <validBaselineExpr>
cue export ./<contract-path> -e <publicSliceExpr>
```

If the slice has no public issue/gate expression, define one small exported object that summarizes the implemented contract surface.

# Fixtures

Required valid fixture:

```cue
baseline<Thing>: #<CandidateOrInstance> & {
  // concrete valid minimal instance
}
```

If the slice introduces a refusal rule, add typed negative fixtures:

```cue
#NegativeFixture: close({
  id:              string
  violates:        string
  expectedRefusal: string
  input:           #<ObservedOrBroadType>
  expectedBottom:  true
})

negativeFixtures: {
  <fixtureName>: #NegativeFixture & {
    id:              "negative.<fixtureName>"
    violates:        "predicates.<predicateName>"
    expectedRefusal: "<why this shape must be refused>"
    expectedBottom:  true

    input: {
      // actual invalid object shape
    }
  }
}
```

Invalidity must be structural.

Do not encode invalidity only as:

```cue
isInvalid: true
<predicateName>: true
expectedBottom: true
```

# Predicates and checks

If this slice has derived refusal logic, use this shape:

```cue
#Predicates: close({
  input: #<ObservedOrBroadType>

  <predicateName>: <derived expression over input>
})

#<Candidate>: _candidate=close(#<ObservedOrBroadType> & {
  predicates: #Predicates & {
    input: _candidate
  }

  if predicates.<predicateName> {
    _<predicateName>: _|_
  }
})
```

Required negative check surface when negative fixtures exist:

```cue
_negativeBottomChecks: {
  <fixtureName>:
    negativeFixtures.<fixtureName>.input & #<Candidate>
}
```

This must be a real CUE intersection, not a string field.

Forbidden:

```cue
bottomCheckSurface: {
  expression: "negativeFixtures.<fixtureName>.input & #<Candidate>"
  expectedBottom: true
}
```

# Generated outputs / projections

```text
Generated or projected artifacts:
  - path:
    generated from:
    validation command:
```

Rules:

```text
- generated files must be downstream of CUE authority
- projections must not become mutation targets
- adapters may consume contract output but must not define policy authority
- do not add shell/materializer behavior unless explicitly in scope
```

# Forbidden attractors

Do not introduce:

```text
review-only metadata as proof
diagnostic boolean fields used as authority
expectedBottom without real intersections
stringified CUE expressions
bottomCheckSurface.expression
fake/default provenance
manually supplied derived values accepted as valid
placeholder evidence accepted as admissible evidence
side-package schema sprawl
broad state-machine expansion outside this slice
adapter/materializer behavior outside this slice
generated artifacts that are not downstream of CUE authority
inline duplicated predicate logic instead of a predicate control surface
```

Repo-specific forbidden names:

```text
<forbiddenNameA>
<forbiddenNameB>
<forbiddenNameC>
```

# Gates and acceptance criteria

```text
Required gates:
  - cue vet:
  - valid baseline export:
  - public slice export:
  - negative bottom checks, if any:
  - forbidden attractor search:
  - generated/projection checks, if any:

Control action:
  action: admit | reject | defer | block
  reason:
  evidence:
  next state:
```

- [ ] Acceptance criteria are satisfied by the canonical `#CUEImplementationSlice.acceptanceCriteria` CUE block.
- [ ] CUE authority boundary is explicit.
- [ ] Implementation is not vocabulary-only.
- [ ] Public eval surfaces export successfully.
- [ ] Negative bottom checks bottom as expected, if present.
- [ ] Forbidden attractor search passes.
- [ ] No adapter, generated artifact, or shell command is treated as semantic authority.

# Validation commands

```bash
cue vet ./<contract-path>
cue export ./<contract-path> -e <validBaselineExpr>
cue export ./<contract-path> -e <publicSliceExpr>

# If negative fixtures exist:
! cue export ./<contract-path> -e '_negativeBottomChecks.<fixtureName>'

# Forbidden attractor search:
! rg '<forbiddenNameA>|<forbiddenNameB>|bottomCheckSurface|expression:' ./<contract-path>

# Optional generated/projection checks:
<repo-specific command>
```

# Required completion report

```text
Summary:
  - added/updated primitives:
  - added/updated admissible/candidate surfaces:
  - added/updated fixtures:
  - added/updated predicates/checks:
  - added/updated public eval surfaces:
  - generated/projection updates, if any:
  - removed or avoided forbidden attractors:

Validation:
  - cue vet ./<contract-path>:
  - cue export ./<contract-path> -e <validBaselineExpr>:
  - cue export ./<contract-path> -e <publicSliceExpr>:
  - negative bottom checks, if any:
  - forbidden attractor search:
  - generated/projection checks, if any:

Compatibility exceptions:
  - <If a compatibility binding remains, explain why it is not authority, evidence, default data, or mutation behavior.>
```

# Non-goals

```text
This issue must not expand into:
  - architecture redesign
  - unrelated package reorganization
  - downstream runtime adapter implementation
  - VCS mutation/materialization
  - broad promotion state machine
  - command inventory generation unless explicitly listed
  - unrelated schema cleanup
  - documentation-only review artifact
```

Stop once the declared CUE contract slice exports and validates.
