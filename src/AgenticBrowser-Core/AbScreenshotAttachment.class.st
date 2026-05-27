Class {
	#name : 'AbScreenshotAttachment',
	#superclass : 'Object',
	#instVars : [
		'name',
		'fileReference'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbScreenshotAttachment class >> screenshotDirectory [

	^ AbSettings defaultAgenticBrowserRootDirectory / 'screenshots'
]

{ #category : 'accessing' }
AbScreenshotAttachment class >> nextNameForDate: aDate [

	| dateString prefix existing maxSeq |
	dateString := aDate year printString
		, (aDate monthIndex printString padLeftTo: 2 with: $0)
		, (aDate dayOfMonth printString padLeftTo: 2 with: $0).
	prefix := 'sc-' , dateString , '-'.
	existing := self screenshotDirectory exists
		ifTrue: [ self screenshotDirectory fileNames select: [ :n | (n beginsWith: prefix) and: [ n endsWith: '.png' ] ] ]
		ifFalse: [ #() ].
	maxSeq := existing inject: 0 into: [ :max :each |
		| seqStr seq |
		seqStr := each copyFrom: prefix size + 1 to: each size - 4.
		seq := seqStr asInteger ifNil: [ 0 ].
		max max: seq ].
	^ prefix , ((maxSeq + 1) printString padLeftTo: 3 with: $0)
]

{ #category : 'factory' }
AbScreenshotAttachment class >> saveForm: aForm forDate: aDate [

	| attachmentName fileRef |
	self screenshotDirectory ensureCreateDirectory.
	attachmentName := self nextNameForDate: aDate.
	fileRef := self screenshotDirectory / (attachmentName , '.png').
	PNGReadWriter putForm: aForm onFileNamed: fileRef fullName.
	^ self new
		name: attachmentName;
		fileReference: fileRef;
		yourself
]

{ #category : 'factory' }
AbScreenshotAttachment class >> named: aString [

	| fileRef |
	fileRef := self screenshotDirectory / (aString , '.png').
	^ self new
		name: aString;
		fileReference: fileRef;
		yourself
]

{ #category : 'factory' }
AbScreenshotAttachment class >> captureAndSave [

	| form |
	form := Screenshot new formScreenshotFromUserSelection.
	form ifNil: [ ^ nil ].
	^ self saveForm: form forDate: Date today
]

{ #category : 'accessing' }
AbScreenshotAttachment >> name [

	^ name
]

{ #category : 'accessing' }
AbScreenshotAttachment >> name: aString [

	name := aString
]

{ #category : 'accessing' }
AbScreenshotAttachment >> fileReference [

	^ fileReference
]

{ #category : 'accessing' }
AbScreenshotAttachment >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : 'accessing' }
AbScreenshotAttachment >> mentionString [

	^ '@' , name , '.png'
]

{ #category : 'accessing' }
AbScreenshotAttachment >> base64PngString [

	^ fileReference binaryReadStream contents base64Encoded
]

{ #category : 'prompt' }
AbScreenshotAttachment >> applyToPromptParams: params [

	params imagePrompt: self base64PngString mimeType: 'image/png'
]
