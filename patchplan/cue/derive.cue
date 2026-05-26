package patchplan

import "list"

primitiveNodes: [
	for p in facts.primitives {
		id:    p.id
		kind:  "primitive"
		label: "\(p.kind): \(p.text) @ \(p.file):\(p.line)"
	},
]

obligationNodes: [
	{
		id:    "obligation:provide-logger-binding"
		kind:  "obligation"
		label: "provide logger binding"
	},
	{
		id:    "obligation:rewrite-console-calls"
		kind:  "obligation"
		label: "rewrite console receiver calls to logger receiver calls"
	},
	{
		id:    "gate:compiler-clean"
		kind:  "gate"
		label: "compiler error count == 0"
	},
	{
		id:    "gate:lsp-clean"
		kind:  "gate"
		label: "LSP adapter OK and error count == 0"
	},
]

consoleRewriteEdges: [
	for p in facts.primitives if p.kind == "call" && p.receiver == "console" {
		from:  p.id
		to:    "obligation:rewrite-console-calls"
		kind:  "requires"
		label: "console call must be rewritten"
	},
]

lspSemanticNodes: [
	if lsp.semanticNodes != _|_ for n in lsp.semanticNodes {
		id:    n.id
		kind:  n.kind
		label: "\(n.kind): \(n.name) @ \(n.file):\(n.line):\(n.character)"
	},
]

lspSemanticEdges: [
	if lsp.semanticEdges != _|_ for e in lsp.semanticEdges {
		from:  e.from
		to:    e.to
		kind:  e.kind
		label: e.kind
	},
]

diagnosticRequiresEdges: [
	if lsp.semanticEdges != _|_ for e in lsp.semanticEdges if e.kind == "diagnoses" {
		from:  e.to
		to:    "obligation:provide-logger-binding"
		kind:  "requires"
		label: "unresolved logger requires logger binding"
	},
]

diagnosticFallbackRequiresEdges: [
	if lsp.semanticNodes != _|_ for n in lsp.semanticNodes if n.kind == "diagnostic" && n.name == "TS2304" {
		from:  n.id
		to:    "obligation:provide-logger-binding"
		kind:  "requires"
		label: "TS2304 requires logger binding"
	},
]

unresolvedLoggerNodes: [
	if lsp.semanticSummary != _|_ for refID in lsp.semanticSummary.unresolvedLoggerReferences {
		id:    "unresolved:\(refID)"
		kind:  "unresolved-reference"
		label: "unresolved logger reference: \(refID)"
	},
]

unresolvedLoggerEdges: [
	if lsp.semanticSummary != _|_ for refID in lsp.semanticSummary.unresolvedLoggerReferences {
		from:  refID
		to:    "unresolved:\(refID)"
		kind:  "conflicts"
		label: "logger reference has no resolves-to edge"
	},
]

patchPlan: #PatchPlan & {
	patchLayers: [
		{
			id:          "001-provide-logger-binding"
			title:       "Provide logger binding"
			order:       1
			obligations: ["obligation:provide-logger-binding"]
			produces:   ["symbol:logger"]
			description: "Create src/logger.ts and/or import logger where needed."
		},
		{
			id:          "002-rewrite-console-calls"
			title:       "Rewrite console calls"
			order:       2
			obligations: ["obligation:rewrite-console-calls"]
			consumes:   ["symbol:logger"]
			description: "Rewrite console.$METHOD(...) calls to logger.$METHOD(...)."
		},
		{
			id:          "003-validate-candidate"
			title:       "Validate candidate"
			order:       3
			obligations: ["gate:compiler-clean", "gate:lsp-clean"]
			description: "Run compiler and LSP validation gates."
		},
	]
	edges: [
		{
			from: "001-provide-logger-binding"
			to:   "002-rewrite-console-calls"
			kind: "must-precede"
		},
		{
			from: "002-rewrite-console-calls"
			to:   "003-validate-candidate"
			kind: "must-precede"
		},
	]
}

patchLayerNodes: [
	for layer in patchPlan.patchLayers {
		id:    "patchLayer:\(layer.id)"
		kind:  "patch-layer"
		label: "\(layer.order). \(layer.title)"
	},
]

patchLayerOrderEdges: [
	for e in patchPlan.edges {
		from:  "patchLayer:\(e.from)"
		to:    "patchLayer:\(e.to)"
		kind:  "must-precede"
		label: "must-precede"
	},
]

patchLayerImplementsEdges: [
	for layer in patchPlan.patchLayers
	for obligation in layer.obligations {
		from:  "patchLayer:\(layer.id)"
		to:    obligation
		kind:  "implements"
		label: "implements"
	},
]

graph: #Graph & {
	nodes: list.Concat([primitiveNodes, obligationNodes, lspSemanticNodes, unresolvedLoggerNodes, patchLayerNodes])

	edges: list.Concat([consoleRewriteEdges, lspSemanticEdges, diagnosticRequiresEdges, diagnosticFallbackRequiresEdges, unresolvedLoggerEdges, patchLayerOrderEdges, patchLayerImplementsEdges, [
		{
			from:  "obligation:rewrite-console-calls"
			to:    "obligation:provide-logger-binding"
			kind:  "requires"
			label: "logger calls require logger binding"
		},
		{
			from:  "obligation:provide-logger-binding"
			to:    "gate:compiler-clean"
			kind:  "validates"
			label: "compiler proves binding resolves"
		},
		{
			from:  "obligation:rewrite-console-calls"
			to:    "gate:lsp-clean"
			kind:  "validates"
			label: "LSP confirms no semantic errors"
		},
	]])
}

candidateModel: #CandidateModel & {
	changeID: change.id
	assertions: [
		{
			id:      "no-console-calls"
			subject: "candidate.consoleCallCount"
			op:      "=="
			value:   0
		},
		{
			id:      "has-logger-calls"
			subject: "candidate.loggerCallCount"
			op:      ">="
			value:   1
		},
		{
			id:      "has-logger-binding"
			subject: "candidate.hasLoggerBinding"
			op:      "=="
			value:   true
		},
		{
			id:      "compiler-clean"
			subject: "candidate.compilerErrorCount"
			op:      "=="
			value:   0
		},
		{
			id:      "lsp-clean"
			subject: "candidate.lspErrorCount"
			op:      "=="
			value:   0
		},
	]
}
