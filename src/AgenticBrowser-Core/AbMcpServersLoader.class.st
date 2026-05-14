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

{ #category : 'instance creation' }
AbMcpServersLoader class >> default [

	^ self new
]

{ #category : 'defaults' }
AbMcpServersLoader class >> defaultMcpJsonFileReference [

	^ AbSettings defaultAgenticBrowserRootDirectory / 'mcp.json'
]

{ #category : 'private' }
AbMcpServersLoader >> configureServer: aServer fromDict: aConfigDict [

	#( #command #args #type #url ) do: [ :key |
		(aConfigDict at: key ifAbsent: [ nil ]) ifNotNil: [ :v |
			aServer perform: (key , ':') asSymbol with: v ] ].
	(aConfigDict at: 'env' ifAbsent: [ nil ]) ifNotNil: [ :envSource |
		envSource isDictionary
			ifTrue: [ envSource keysAndValuesDo: [ :k :v | aServer addEnvNamed: k value: v ] ]
			ifFalse: [ aServer env: envSource ] ]
]

{ #category : 'private' }
AbMcpServersLoader >> defaultConfigDicts [

	^ Dictionary new
		  at: 'smalltalk-interop'
		  put: (Dictionary new
				   at: 'command' put: 'uvx';
				   at: 'args'
				   put: #( '--from'
					   'git+https://github.com/mumez/pharo-smalltalk-interop-mcp-server.git'
					   'pharo-smalltalk-interop-mcp-server' );
				   at: 'env' put: (Dictionary new
						    at: 'PHARO_SIS_PORT' put: '8086';
						    yourself);
				   yourself);
		  at: 'smalltalk-validator'
		  put: (Dictionary new
				   at: 'command' put: 'uvx';
				   at: 'args'
				   put: #( '--from'
					   'git+https://github.com/mumez/smalltalk-validator-mcp-server.git@main'
					   'smalltalk-validator-mcp-server' );
				   yourself);
		  yourself
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
		  as: OrderedCollection
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
