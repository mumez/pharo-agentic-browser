Class {
	#name : 'AbFileAttachment',
	#superclass : 'Object',
	#instVars : [
		'name',
		'fileReference'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbFileAttachment class >> fromFileReference: aFileReference [

	| ref |
	ref := aFileReference asFileReference.
	^ self new
		name: ref basename;
		fileReference: ref;
		yourself
]

{ #category : 'instance creation' }
AbFileAttachment class >> fromPath: aString [

	^ self fromFileReference: aString asFileReference
]

{ #category : 'accessing' }
AbFileAttachment >> fileReference [

	^ fileReference
]

{ #category : 'accessing' }
AbFileAttachment >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : 'accessing' }
AbFileAttachment >> mentionString [

	^ '[' , self name , ']'
]

{ #category : 'accessing' }
AbFileAttachment >> name [

	^ name
]

{ #category : 'accessing' }
AbFileAttachment >> name: aString [

	name := aString
]

{ #category : 'prompt' }
AbFileAttachment >> applyToPromptParams: params [

	params resourcePrompt: self uriString text: self textForPrompt
]

{ #category : 'prompt' }
AbFileAttachment >> textForPrompt [

	^ [ self fileReference contents ]
		  on: Error
		  do: [ 'Attached file: ' , self fileReference basename ]
]

{ #category : 'prompt' }
AbFileAttachment >> uriString [

	^ 'file://' , self fileReference fullName
]
