package patchplan

import "list"

compilerEvidence: [...#CompilerSensorFacts]

_compilerEvidenceFailures: [
	for step in adapterPatchFacts.steps
	if step.evidenceRefs != _|_
	if step.evidenceRefs.compiler != _|_
	if len([for fact in compilerEvidence if fact.artifactPath == step.evidenceRefs.compiler && fact.accepted {fact}]) == 0 {"\(step.stepID) has no accepted compiler evidence at \(step.evidenceRefs.compiler)"},
]

patchStackValidation: {
	rejectionReasons: list.Concat([_rejectionReasons, _compilerEvidenceFailures])
}
