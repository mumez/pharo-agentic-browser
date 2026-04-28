Class {
	#name : 'AbSisServerStub',
	#superclass : 'Object',
	#instVars : [
		'lastRequest'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'handling' }
AbSisServerStub >> handleExportPackage: aDictionary [

	self lastRequest: aDictionary.
	^ 'stub-export'
]

{ #category : 'handling' }
AbSisServerStub >> handleImportPackage: aDictionary [

	self lastRequest: aDictionary.
	^ 'stub-import'
]

{ #category : 'handling' }
AbSisServerStub >> handleRunPackageTest: aDictionary [

	self lastRequest: aDictionary.
	^ 'stub-test'
]

{ #category : 'accessing' }
AbSisServerStub >> lastRequest [

	^ lastRequest
]

{ #category : 'accessing' }
AbSisServerStub >> lastRequest: aDictionary [

	lastRequest := aDictionary
]
