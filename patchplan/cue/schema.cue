package patchplan

#Diagnostic: {
	file?:     string
	line?:     int & >=0
	character?: int & >=0
	severity: "error" | "warning" | "info"
	code?:     string
	message:  string
}

#Primitive: {
	id:   string
	file: string

	kind: "call" | "binding"

	line: int & >=1
	text: string

	receiver?: string
	method?:   string
	name?:     string
}

#Counts: {
	consoleCalls:   int & >=0
	loggerCalls:    int & >=0
	loggerBindings: int & >=0
}

#RepoFacts: {
	root:   string
	head:   string
	branch: string
	dirty:  bool
}

#Facts: {
	phase: "live" | "candidate"
	repo:  #RepoFacts

	primitives: [...#Primitive]
	counts:     #Counts

	hasLoggerBinding: bool
}

#CompilerFacts: {
	phase:       "live" | "candidate"
	errorCount:  int & >=0
	diagnostics: [...#Diagnostic]

	_errorDiagnostics: [
		for d in diagnostics if d.severity == "error" {d},
	]
	errorCount: len(_errorDiagnostics)
}

#LSPFacts: {
	phase: "live" | "candidate"

	adapterOK:   bool
	errorCount:  int & >=0
	diagnostics: [...#Diagnostic]

	_errorDiagnostics: [
		for d in diagnostics if d.severity == "error" {d},
	]
	errorCount: len(_errorDiagnostics)

	symbols?: [...{
		name: string
		kind: string
		file: string
	}]

	references?: [...{
		from: string
		to:   string
	}]

	semanticNodes?: [...#SemanticNode]
	semanticEdges?: [...#SemanticEdge]
	semanticSummary?: #SemanticSummary

	if semanticNodes != _|_ {
		_semanticDiagnosticNodes: [
			for n in semanticNodes if n.kind == "diagnostic" {n},
		]
		_semanticDiagnosticCount: len(_semanticDiagnosticNodes)
		_semanticDiagnosticCount: len(diagnostics)
	}
}

#SemanticNode: {
	id:   string
	kind: "symbol" | "reference" | "diagnostic"

	name?:       string
	symbolKind?: string
	code?:       string
	message?:    string

	file:      string
	line:      int & >=0
	character: int & >=0
}

#SemanticEdge: {
	from: string
	to:   string
	kind: "resolves-to" | "diagnoses" | "references"
}

#SemanticSummary: {
	loggerReferenceCount:        int & >=0
	resolvedLoggerReferenceCount: int & >=0
	unresolvedLoggerReferences:  [...string]
	duplicateNodeIDs:            [...string]
	deterministicOrder:          bool
	allLoggerReferencesResolved: bool
	allResolveTargetsKnown:      bool
}

#VCSFacts: {
	phase:        "live" | "candidate"
	head:         string
	branch:       string
	diffStat:     string
	diffNonEmpty: bool
}

#Node: {
	id:    string
	kind:  string
	label: string
}

#Edge: {
	from:  string
	to:    string
	kind:  "contains" | "requires" | "produces" | "validates" | "conflicts" | "resolves-to" | "diagnoses" | "references" | "must-precede" | "implements"
	label?: string
}

#Graph: {
	nodes: [...#Node]
	edges: [...#Edge]
}

#Assertion: {
	id:      string
	subject: string
	op:      "==" | ">="
	value:   string | int | bool
}

#CandidateModel: {
	changeID:   string
	assertions: [...#Assertion]
}

#PatchLayer: {
	id:          string
	title:       string
	order:       int & >=1
	obligations: [string, ...string]
	produces?:   [...string]
	consumes?:   [...string]
	description: string
}

#PatchLayerEdge: {
	from: string
	to:   string
	kind: "must-precede"
}

#PatchPlan: {
	patchLayers: [...#PatchLayer]
	edges:       [...#PatchLayerEdge]
}

#Report: {
	changeID: string

	live: {
		consoleCallCount: int & >=0
	}

	candidate: {
		consoleCallCount:   int & >=0
		loggerCallCount:    int & >=0
		hasLoggerBinding:   bool
		compilerErrorCount: int & >=0
		lspAdapterOK:       bool
		lspErrorCount:      int & >=0
		diffNonEmpty:       bool
		allLoggerReferencesResolved: bool
		allResolveTargetsKnown:      bool
		noDuplicateSemanticNodeIDs:  bool
		semanticOrderDeterministic:  bool
	}

	accepted: bool

	accepted: candidate.consoleCallCount == 0 &&
		candidate.loggerCallCount >= 1 &&
		candidate.hasLoggerBinding &&
		candidate.compilerErrorCount == 0 &&
		candidate.lspAdapterOK &&
		candidate.lspErrorCount == 0 &&
		candidate.diffNonEmpty &&
		candidate.allLoggerReferencesResolved &&
		candidate.allResolveTargetsKnown &&
		candidate.noDuplicateSemanticNodeIDs &&
		candidate.semanticOrderDeterministic
}

#ReportInput: {
	live:      #Facts & {phase: "live"}
	candidate: #Facts & {phase: "candidate"}
	compiler:  #CompilerFacts & {phase: "candidate"}
	lsp:       #LSPFacts & {phase: "candidate"}
	vcs:       #VCSFacts & {phase: "candidate"}

	compiler: {
		errorCount: lsp.errorCount
	}
}

facts?:          #Facts
compiler?:       #CompilerFacts
lsp?:            #LSPFacts
vcs?:            #VCSFacts
graph?:          #Graph
candidateModel?: #CandidateModel
patchPlan?:      #PatchPlan
report?:         #Report
reportInput?:    #ReportInput
