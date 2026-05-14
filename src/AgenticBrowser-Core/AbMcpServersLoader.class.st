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
AbMcpServersLoader >> mcpServerNamed: aName fromConfig: aConfigDict [

	| server |
	server := ACPMcpServer new.
	server name: aName.
	(aConfigDict at: 'command' ifAbsent: [ nil ]) ifNotNil: [ :v | server command: v ].
	(aConfigDict at: 'args' ifAbsent: [ nil ]) ifNotNil: [ :v | server args: v ].
	(aConfigDict at: 'type' ifAbsent: [ nil ]) ifNotNil: [ :v | server type: v ].
	(aConfigDict at: 'url' ifAbsent: [ nil ]) ifNotNil: [ :v | server url: v ].
	(aConfigDict at: 'env' ifAbsent: [ nil ]) ifNotNil: [ :envSource |
		envSource isDictionary
			ifTrue: [ envSource keysAndValuesDo: [ :k :v | server addEnvNamed: k value: v ] ]
			ifFalse: [ server env: envSource ] ].
	^ server
]
