package patchplan

import "list"

adapterPatchFacts: #AdapterPatchStackFacts

_scopeRank: {
	symbol:    10
	file:      20
	package:   30
	module:    40
	workspace: 50
}

patchStack: #PatchStackPlan & {
	steps: [
		for step in adapterPatchFacts.steps {
			id:        step.stepID
			scope:     step.scopeKind
			operation: step.op
			touches:   step.paths
			dependsOn: step.deps
			order:     step.ordinal
			if step.evidenceRefs != _|_ {
				evidence: step.evidenceRefs
			}
		},
	]
	accepted: patchStackValidation.accepted
}

_unknownScopeSteps: [
	for step in adapterPatchFacts.steps
	if _scopeRank[step.scopeKind] == _|_ {step.stepID},
]

_duplicateStepIDs: [
	for step in adapterPatchFacts.steps
	if len([for other in adapterPatchFacts.steps if other.stepID == step.stepID {other}]) > 1 {step.stepID},
]

_missingDependencies: [
	for step in adapterPatchFacts.steps
	for dep in step.deps
	if len([for target in adapterPatchFacts.steps if target.stepID == dep {target}]) == 0 {"\(step.stepID) depends on unknown step \(dep)"},
]

_forwardDependencies: [
	for step in adapterPatchFacts.steps
	for dep in step.deps
	for target in adapterPatchFacts.steps
	if target.stepID == dep && target.ordinal >= step.ordinal {"\(step.stepID) depends on non-prior step \(dep)"},
]

_scopeOrderViolations: [
	for step in adapterPatchFacts.steps
	for dep in step.deps
	for target in adapterPatchFacts.steps
	if target.stepID == dep && (_scopeRank[target.scopeKind] > _scopeRank[step.scopeKind] || target.ordinal >= step.ordinal) {"\(step.stepID) violates bottom-up dependency on \(dep)"},
]

_orderViolations: [
	for index, step in adapterPatchFacts.steps
	if step.ordinal != index+1 {"\(step.stepID) ordinal does not match adapter order"},
]

_rejectionReasons: list.Concat([_unknownScopeSteps, _missingDependencies, _forwardDependencies, _scopeOrderViolations, _orderViolations])

patchStackValidation: #PatchStackValidation & {
	validScopeRanks:           len(_unknownScopeSteps) == 0
	dependencyReferencesExist: len(_missingDependencies) == 0
	noForwardDependencies:     len(_forwardDependencies) == 0
	bottomUpOrder:             len(_scopeOrderViolations) == 0
	deterministicOrder:        adapterPatchFacts.deterministicOrder && len(_orderViolations) == 0
	duplicateStepIDs:          _duplicateStepIDs
	rejectionReasons:          _rejectionReasons
}
