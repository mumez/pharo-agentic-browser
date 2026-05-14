Class {
	#name : 'AbMcpServersLoader',
	#superclass : 'Object',
	#instVars : [
		'mcpJsonFile',
		'useDefaultMcpServers'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbMcpServersLoader class >> default [

	^ self new
		  mcpJsonFile: AbSettings defaultAgenticBrowserRootDirectory / 'mcp.json';
		  useDefaultMcpServers: AbSettings default useDefaultMcpServers;
		  yourself
]

{ #category : 'accessing' }
AbMcpServersLoader >> mcpJsonFile [
	^ mcpJsonFile
]

{ #category : 'accessing' }
AbMcpServersLoader >> mcpJsonFile: aFileReference [
	mcpJsonFile := aFileReference
]

{ #category : 'accessing' }
AbMcpServersLoader >> useDefaultMcpServers [
	^ useDefaultMcpServers ifNil: [ true ]
]

{ #category : 'accessing' }
AbMcpServersLoader >> useDefaultMcpServers: aBoolean [
	useDefaultMcpServers := aBoolean
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
	(mcpJsonFile isNil or: [ mcpJsonFile exists not ]) ifTrue: [ ^ Dictionary new ].
	json := STONJSON fromString: mcpJsonFile contents.
	^ (json at: 'mcpServers' ifAbsent: [ ^ Dictionary new ]) asDictionary
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
AbMcpServersLoader >> mcpServerNamed: aName fromConfig: aConfigDict [

	| server |
	server := ACPMcpServer new.
	server name: aName.
	self configureServer: server fromDict: aConfigDict.
	^ server
]
