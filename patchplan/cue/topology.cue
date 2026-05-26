package patchplan

patchOrder: #PatchOrder

patchOrder: {
	hasCycle:              false
	cycle:                 []
	deterministicLayerIDs: true
	duplicateLayerIDs:     []
	orderMatchesDeclared:  true
}

_orderViolations: [
	for edge in patchOrder.edgeChecks if !edge.respects {edge},
]

_orderViolationCount: 0
_orderViolationCount: len(_orderViolations)
