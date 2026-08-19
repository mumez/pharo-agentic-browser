Class {
	#name : 'AbMcpServersLoaderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadFromFileReturnsParsedConfigDict [

	| loader jsonString tmpFile result |
	loader := AbMcpServersLoader new.
	tmpFile := FileReference newTempFilePrefix: 'mcp' suffix: '.json'.
	jsonString := '{"mcpServers":{"my-server":{"command":"uvx","args":["pkg"]}}}'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: jsonString ].
	loader mcpJsonFile: tmpFile.
	[ result := loader loadFromFile.
	  self assert: (result includesKey: 'my-server').
	  self assert: ((result at: 'my-server') at: 'command') equals: 'uvx' ]
		ensure: [ tmpFile ensureDelete ]
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadFromMissingFileReturnsEmpty [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	result := loader loadFromFile.
	self assert: result isEmpty
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadResultIsJsonEncodableViaSessionParams [

	| loader servers params json serverDicts interop validator |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	servers := loader load.
	params := ACPSessionParams new.
	params mcpServers: servers.
	self shouldnt: [ json := STONJSON toString: params asDictionary ] raise: Error.
	serverDicts := (STONJSON fromString: json) at: 'mcpServers'.
	interop := serverDicts detect: [ :s | (s at: 'name') = 'smalltalk-interop' ].
	self assert: (interop at: 'command') equals: 'uvx'.
	self assert: (interop at: 'args') equals: #( '--from' 'git+https://github.com/mumez/smalltalk-interop-mcp-server.git' 'smalltalk-interop-mcp-server' ).
	self assert: ((interop at: 'env') anySatisfy: [ :e | (e at: 'name') = 'SIS_PORT' and: [ (e at: 'value') = '8086' ] ]).
	validator := serverDicts detect: [ :s | (s at: 'name') = 'smalltalk-validator' ].
	self assert: (validator at: 'command') equals: 'uvx'.
	self assert: (validator at: 'args') equals: #( '--from' 'git+https://github.com/mumez/smalltalk-validator-mcp-server.git@main' 'smalltalk-validator-mcp-server' ).
	self assert: (validator at: 'env') equals: #()
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadReturnsArray [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: false.
	result := loader load.
	self assert: result class equals: Array
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadSmalltalkInteropHasEnvVar [

	| loader result interopServer |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	interopServer := result detect: [ :s | s name = 'smalltalk-interop' ].
	self assert: (interopServer env anySatisfy: [ :e |
		e name = 'SIS_PORT' and: [ e value = '8086' ] ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadUserServersTakePrecedenceOverDefaults [

	| loader jsonString tmpFile result interopServer |
	loader := AbMcpServersLoader new.
	tmpFile := FileReference newTempFilePrefix: 'mcp' suffix: '.json'.
	jsonString := '{"mcpServers":{"smalltalk-interop":{"command":"myuvx","args":[]}}}'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: jsonString ].
	loader mcpJsonFile: tmpFile.
	loader useDefaultMcpServers: true.
	[ result := loader load.
	  interopServer := result detect: [ :s | s name = 'smalltalk-interop' ].
	  self assert: interopServer command equals: 'myuvx' ]
		ensure: [ tmpFile ensureDelete ]
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithDefaultsIncludesSmalltalkInterop [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result anySatisfy: [ :s | s name = 'smalltalk-interop' ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithDefaultsIncludesSmalltalkValidator [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result anySatisfy: [ :s | s name = 'smalltalk-validator' ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithDefaultsReturnsMcpServerObjects [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result allSatisfy: [ :each | each isKindOf: ACPMcpServer ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithoutDefaultsDoesNotIncludeSmalltalkInterop [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: false.
	result := loader load.
	self deny: (result anySatisfy: [ :s | s name = 'smalltalk-interop' ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithoutFileAndDefaultsReturnsEmpty [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: false.
	result := loader load.
	self assert: result isEmpty
]
