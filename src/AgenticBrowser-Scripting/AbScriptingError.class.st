"
I represent errors that occur during scripting execution.

I carry a kind symbol identifying the error category and optional data for details.

Kinds:
- #modeNotSupported: the agent does not support mode configuration
- #noMatchingMode: mode name did not match any option offered by the agent
- #modelNotSupported: the agent does not support model configuration
- #noMatchingModel: model value did not match any option offered by the agent
"
Class {
	#name : 'AbScriptingError',
	#superclass : 'Error',
	#instVars : [
		'kind',
		'data'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbScriptingError class >> kind: aKindSymbol [
	^ self new kind: aKindSymbol; yourself
]

{ #category : 'instance creation' }
AbScriptingError class >> kind: aKindSymbol data: aDictionary [
	^ self new kind: aKindSymbol; data: aDictionary; yourself
]

{ #category : 'instance creation' }
AbScriptingError class >> modeNotSupported: aMessage [
	^ (self kind: #modeNotSupported) messageText: aMessage; yourself
]

{ #category : 'instance creation' }
AbScriptingError class >> modelNotSupported: aMessage [
	^ (self kind: #modelNotSupported) messageText: aMessage; yourself
]

{ #category : 'instance creation' }
AbScriptingError class >> noMatchingModel: aMessage requestedModel: aModel availableOptions: optionObjects [
	^ (self kind: #noMatchingModel)
		messageText: aMessage;
		dataAt: #requestedModel put: aModel;
		dataAt: #availableOptions put: optionObjects;
		yourself
]

{ #category : 'instance creation' }
AbScriptingError class >> noMatchingMode: aMessage requestedMode: aMode availableOptions: optionNames [
	^ (self kind: #noMatchingMode)
		messageText: aMessage;
		dataAt: #requestedMode put: aMode;
		dataAt: #availableOptions put: optionNames;
		yourself
]

{ #category : 'accessing' }
AbScriptingError >> kind [
	^ kind
]

{ #category : 'accessing' }
AbScriptingError >> kind: aSymbol [
	kind := aSymbol
]

{ #category : 'accessing' }
AbScriptingError >> data [
	data ifNil: [ data := Dictionary new ].
	^ data
]

{ #category : 'accessing' }
AbScriptingError >> data: aDictionary [
	data := aDictionary
]

{ #category : 'accessing' }
AbScriptingError >> dataAt: key [
	^ self data at: key
]

{ #category : 'accessing' }
AbScriptingError >> dataAt: key put: value [
	self data at: key put: value
]
