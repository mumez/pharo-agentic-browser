Class {
	#name : 'AbWorkingDirectory',
	#superclass : 'Object',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbWorkingDirectory class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'operations' }
AbWorkingDirectory >> ensureExists [

	self path ensureCreateDirectory
]

{ #category : 'operations' }
AbWorkingDirectory >> exportAll [

	topic watchedPackages do: [ :pkg | self exportPackage: pkg ]
]

{ #category : 'operations' }
AbWorkingDirectory >> exportPackage: aPackageName [

	self ensureExists.
	^ SisServer current handleExportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self path fullName } asDictionary
]

{ #category : 'operations' }
AbWorkingDirectory >> importAll [

	topic watchedPackages do: [ :pkg | self importPackage: pkg ]
]

{ #category : 'operations' }
AbWorkingDirectory >> importPackage: aPackageName [

	self ensureExists.
	^ SisServer current handleImportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self path fullName } asDictionary
]

{ #category : 'accessing' }
AbWorkingDirectory >> path [

	^ FileLocator home / 'agentic-browser' / self safeTopicName
]

{ #category : 'operations' }
AbWorkingDirectory >> runAllTests [

	^ String streamContents: [ :s |
		  topic watchedPackages do: [ :pkg |
			  | result |
			  result := self runTests: pkg.
			  s nextPutAll: pkg; nextPutAll: ': '; nextPutAll: (result at: 'result' ifAbsent: [ 'error' ]); cr ] ]
]

{ #category : 'operations' }
AbWorkingDirectory >> runTests: aPackageName [

	^ SisServer current handleRunPackageTest: {
		  'package_name' -> aPackageName } asDictionary
]

{ #category : 'accessing' }
AbWorkingDirectory >> safeTopicName [

	| safe |
	safe := topic title collect: [ :c |
		    (c isAlphaNumeric or: [ c = $- or: [ c = $_ ] ])
			    ifTrue: [ c ]
			    ifFalse: [ $- ] ].
	safe isEmpty ifTrue: [ safe := 'topic' ].
	^ safe
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic [
	^ topic
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic: anAbTopic [
	topic := anAbTopic
]
