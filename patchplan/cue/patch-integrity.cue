package patchplan

patchLayers: [...#PatchLayer]
edges: [...#PatchLayerEdge]

_provideLoggerImplementers: [
	for layer in patchLayers
	for obligation in layer.obligations
	if obligation == "obligation:provide-logger-binding" {layer},
]

_rewriteConsoleImplementers: [
	for layer in patchLayers
	for obligation in layer.obligations
	if obligation == "obligation:rewrite-console-calls" {layer},
]

_compilerGateImplementers: [
	for layer in patchLayers
	for obligation in layer.obligations
	if obligation == "gate:compiler-clean" {layer},
]

_lspGateImplementers: [
	for layer in patchLayers
	for obligation in layer.obligations
	if obligation == "gate:lsp-clean" {layer},
]

_provideBeforeRewriteEdges: [
	for edge in edges
	if edge.from == "001-provide-logger-binding" && edge.to == "002-rewrite-console-calls" {edge},
]

_rewriteBeforeValidateEdges: [
	for edge in edges
	if edge.from == "002-rewrite-console-calls" && edge.to == "003-validate-candidate" {edge},
]

_loggerProducerLayers: [
	for layer in patchLayers
	if layer.produces != _|_
	for produced in layer.produces
	if produced == "symbol:logger" {layer},
]

_loggerConsumerLayers: [
	for layer in patchLayers
	if layer.consumes != _|_
	for consumed in layer.consumes
	if consumed == "symbol:logger" {layer},
]

_loggerProducerBeforeRewriteLayers: [
	for layer in _loggerProducerLayers
	if layer.order < 2 {layer},
]

_validationAfterRewriteLayers: [
	for layer in patchLayers
	if layer.id == "003-validate-candidate" && layer.order > 2 {layer},
]

_provideLoggerImplementerCount: int & >0
_provideLoggerImplementerCount: len(_provideLoggerImplementers)

_rewriteConsoleImplementerCount: int & >0
_rewriteConsoleImplementerCount: len(_rewriteConsoleImplementers)

_compilerGateImplementerCount: int & >0
_compilerGateImplementerCount: len(_compilerGateImplementers)

_lspGateImplementerCount: int & >0
_lspGateImplementerCount: len(_lspGateImplementers)

_provideBeforeRewriteEdgeCount: int & >0
_provideBeforeRewriteEdgeCount: len(_provideBeforeRewriteEdges)

_rewriteBeforeValidateEdgeCount: int & >0
_rewriteBeforeValidateEdgeCount: len(_rewriteBeforeValidateEdges)

_loggerProducerLayerCount: int & >0
_loggerProducerLayerCount: len(_loggerProducerLayers)

_loggerConsumerLayerCount: int & >0
_loggerConsumerLayerCount: len(_loggerConsumerLayers)

_loggerProducerBeforeRewriteCount: int & >0
_loggerProducerBeforeRewriteCount: len(_loggerProducerBeforeRewriteLayers)

_validationAfterRewriteCount: int & >0
_validationAfterRewriteCount: len(_validationAfterRewriteLayers)
