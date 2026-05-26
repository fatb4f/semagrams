package patchplan

derivedReport: #Report & {
	changeID: change.id

	live: {
		consoleCallCount: reportInput.live.counts.consoleCalls
	}

	candidate: {
		consoleCallCount:   reportInput.candidate.counts.consoleCalls
		loggerCallCount:    reportInput.candidate.counts.loggerCalls
		hasLoggerBinding:   reportInput.candidate.hasLoggerBinding
		compilerErrorCount: reportInput.compiler.errorCount
		lspAdapterOK:       reportInput.lsp.adapterOK
		lspErrorCount:      reportInput.lsp.errorCount
		diffNonEmpty:       reportInput.vcs.diffNonEmpty
		allLoggerReferencesResolved: reportInput.lsp.semanticSummary.allLoggerReferencesResolved
		allResolveTargetsKnown:      reportInput.lsp.semanticSummary.allResolveTargetsKnown
		noDuplicateSemanticNodeIDs:  len(reportInput.lsp.semanticSummary.duplicateNodeIDs) == 0
		semanticOrderDeterministic:  reportInput.lsp.semanticSummary.deterministicOrder
		noScopeViolations:           reportInput.scope.ok
	}
}

reportEnvelope: {
	report: derivedReport
}
