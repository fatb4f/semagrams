package patchplan

patchStack: #PatchStackPlan
patchStackValidation: #PatchStackValidation

patchStack: {
	accepted: patchStackValidation.accepted
}

patchStackValidation: {
	validScopeRanks:           true
	dependencyReferencesExist: true
	noForwardDependencies:     true
	bottomUpOrder:             true
	deterministicOrder:        true
	duplicateStepIDs:          []
	rejectionReasons:          []
	accepted:                  true
}
