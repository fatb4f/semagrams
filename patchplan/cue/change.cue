package patchplan

change: {
	id:       "replace-console-with-logger"
	language: "typescript"

	forbiddenReceivers: ["console"]
	requiredReceivers:  ["logger"]

	requiredBinding: "logger"

	scope: {
		include: ["src/**/*.ts"]
		exclude: []
	}
}
