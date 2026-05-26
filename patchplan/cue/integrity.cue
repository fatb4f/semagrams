package patchplan

graph: #Graph
report: #Report

_diagnosticNodes: [
	for n in graph.nodes if n.kind == "diagnostic" {n},
]

_unresolvedReferenceNodes: [
	for n in graph.nodes if n.kind == "unresolved-reference" {n},
]

_diagnosesEdges: [
	for e in graph.edges if e.kind == "diagnoses" {e},
]

_missingBindingRequiresEdges: [
	for e in graph.edges if e.kind == "requires" && e.to == "obligation:provide-logger-binding" && (e.label == "unresolved logger requires logger binding" || e.label == "TS2304 requires logger binding") {e},
]

_conflictEdges: [
	for e in graph.edges if e.kind == "conflicts" {e},
]

_resolvesToEdges: [
	for e in graph.edges if e.kind == "resolves-to" {e},
]

_compilerGateNodes: [
	for n in graph.nodes if n.id == "gate:compiler-clean" {n},
]

_lspGateNodes: [
	for n in graph.nodes if n.id == "gate:lsp-clean" {n},
]

_patchLayerNodes: [
	for n in graph.nodes if n.kind == "patch-layer" {n},
]

_failurePathEdges: [
	for e in graph.edges if e.kind == "conflicts" || e.kind == "requires" {e},
]

if report.accepted {
	_diagnosticNodes: []
	_unresolvedReferenceNodes: []
	_diagnosesEdges: []
	_missingBindingRequiresEdges: []
	_resolvesToCount: int & >0
	_resolvesToCount: len(_resolvesToEdges)
	_compilerGateCount: int & >0
	_compilerGateCount: len(_compilerGateNodes)
	_lspGateCount: int & >0
	_lspGateCount: len(_lspGateNodes)
	_patchLayerCount: int & >0
	_patchLayerCount: len(_patchLayerNodes)
}

if !report.accepted {
	_failurePathCount: int & >0
	_failurePathCount: len(_failurePathEdges)
}
