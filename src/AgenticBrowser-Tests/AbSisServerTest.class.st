Class {
	#name : 'AbSisServerTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbSisServerTest >> setUp [

	AbTopicManager resetInstance
]

{ #category : 'tests' }
AbSisServerTest >> testClassImplementsStartUp [

	self assert: (AbSisServer class >> #startUp:) methodClass equals: AbSisServer class
]

{ #category : 'tests' }
AbSisServerTest >> testWithImportGuardClearsFlagOnError [

	| manager topic path server sawFlag |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Import Guard'.
	path := (FileLocator temp / ('ab-sis-server-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	manager addTopic: topic.
	server := AbSisServer new.
	sawFlag := false.
	[
	server
		withImportGuardForRequest: { #path -> path } asDictionary
		do: [
			sawFlag := topic isImportingFromSource.
			self error: 'boom' ] ]
		on: Error
		do: [ :ex | ].
	self assert: sawFlag.
	self deny: topic isImportingFromSource
]
