package patchplan

patchLayers: [...#PatchLayer]
edges: [...#PatchLayerEdge]
patchManifest: #PatchManifest

_provideLoggerPatches: [
	for patch in patchManifest.patches
	for obligation in patch.obligations
	if patch.layerID == "001-provide-logger-binding" &&
		obligation == "obligation:provide-logger-binding" &&
		patch.evidence.hasLoggerExport &&
		patch.addedLineCount > 0 {patch},
]

_rewriteConsolePatches: [
	for patch in patchManifest.patches
	for obligation in patch.obligations
	if patch.layerID == "002-rewrite-console-calls" &&
		obligation == "obligation:rewrite-console-calls" &&
		patch.evidence.hasLoggerRewrite &&
		patch.addedLineCount > 0 &&
		patch.removedLineCount > 0 {patch},
]

_declaredPatchLayers: [
	for patch in patchManifest.patches {patch.layerID},
]

_providePatchCount: int & >0
_providePatchCount: len(_provideLoggerPatches)

_rewritePatchCount: int & >0
_rewritePatchCount: len(_rewriteConsolePatches)

patchManifest: {
	applyCheck: {
		ordered: true
		ok:      true
	}
}
