Class {
	#name : 'AbMcpServersLoader',
	#superclass : 'Object',
	#instVars : [
		'mcpJsonFile',
		'settings'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'defaults' }
AbMcpServersLoader class >> defaultMcpJsonFileReference [

	^ AbSettings defaultAgenticBrowserRootDirectory / 'mcp.json'
]

{ #category : 'private' }
AbMcpServersLoader >> addSmalltalkInteropMcpTo: aDict [

	| server |
	server := ACPMcpServer new
		name: 'smalltalk-interop';
		command: 'uvx';
		args: #( '--from' 'git+https://github.com/mumez/pharo-smalltalk-interop-mcp-server.git'
			'pharo-smalltalk-interop-mcp-server' );
		yourself.
	server addEnvNamed: 'PHARO_SIS_PORT' value: '8086'.
	aDict at: server name put: server asDictionary
]

{ #category : 'private' }
AbMcpServersLoader >> addSmalltalkValidatorMcpTo: aDict [

	| server |
	server := ACPMcpServer new
		name: 'smalltalk-validator';
		command: 'uvx';
		args: #( '--from' 'git+https://github.com/mumez/smalltalk-validator-mcp-server.git@main'
			'smalltalk-validator-mcp-server' );
		yourself.
	aDict at: server name put: server asDictionary
]

{ #category : 'private' }
AbMcpServersLoader >> configureServer: aServer fromDict: aConfigDict [

	#( #command #args #type #url ) do: [ :key |
		aConfigDict at: key ifPresent: [ :v |
			aServer perform: key asMutator with: v ] ].
	aConfigDict at: 'env' ifPresent: [ :envSource |
		envSource isDictionary
			ifTrue: [ envSource keysAndValuesDo: [ :k :v | aServer addEnvNamed: k value: v ] ]
			ifFalse: [ aServer env: envSource ] ]
]

{ #category : 'private' }
AbMcpServersLoader >> defaultConfigDicts [

	| dict |
	dict := Dictionary new.
	self addSmalltalkInteropMcpTo: dict.
	self addSmalltalkValidatorMcpTo: dict.
	^ dict
]

{ #category : 'loading' }
AbMcpServersLoader >> load [

	| merged |
	merged := Dictionary new.
	self useDefaultMcpServers ifTrue: [
		merged addAll: self defaultConfigDicts ].
	merged addAll: self loadFromFile.
	^ merged keys
		  collect: [ :name | self mcpServerNamed: name fromConfig: (merged at: name) ]
		  as: Array
]

{ #category : 'loading' }
AbMcpServersLoader >> loadFromFile [

	| json |
	(self mcpJsonFile isNil or: [ self mcpJsonFile exists not ]) ifTrue: [ ^ Dictionary new ].
	json := STONJSON fromString: self mcpJsonFile contents.
	^ (json at: 'mcpServers' ifAbsent: [ ^ Dictionary new ]) asDictionary
]

{ #category : 'accessing' }
AbMcpServersLoader >> mcpJsonFile [
	^ mcpJsonFile ifNil: [ mcpJsonFile := self class defaultMcpJsonFileReference ]
]

{ #category : 'accessing' }
AbMcpServersLoader >> mcpJsonFile: aFileReference [
	mcpJsonFile := aFileReference
]

{ #category : 'private' }
AbMcpServersLoader >> mcpServerNamed: aName fromConfig: aConfigDict [

	| server |
	server := ACPMcpServer new.
	server name: aName.
	self configureServer: server fromDict: aConfigDict.
	^ server
]

{ #category : 'accessing' }
AbMcpServersLoader >> settings [
	^ settings ifNil: [ settings := AbSettings defaultCopied ]
]

{ #category : 'accessing' }
AbMcpServersLoader >> useDefaultMcpServers [
	^ self settings useDefaultMcpServers
]

{ #category : 'accessing' }
AbMcpServersLoader >> useDefaultMcpServers: aBoolean [
	self settings useDefaultMcpServers: aBoolean
]
