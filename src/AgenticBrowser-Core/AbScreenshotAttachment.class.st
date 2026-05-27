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

	| prefix existing maxSeq |
	prefix := 'sc-{1}{2}{3}-' format: {
			aDate year printString.
			aDate monthIndex printString padLeftTo: 2 with: $0.
			aDate dayOfMonth printString padLeftTo: 2 with: $0 }.
	existing := self screenshotDirectory exists
		ifTrue: [ self screenshotDirectory fileNames select: [ :n | (n beginsWith: prefix) and: [ n endsWith: '.png' ] ] ]
		ifFalse: [ #() ].
	maxSeq := existing inject: 0 into: [ :max :each |
		| parts seq |
		parts := each splitOn: '[-.]' asRegex.
		seq := (parts size >= 3 and: [ (parts at: 3) isAllDigits ])
			ifTrue: [ (parts at: 3) asInteger ]
			ifFalse: [ 0 ].
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

	^ fileReference binaryReadStreamDo: [ :stream | stream contents base64Encoded ]
]

{ #category : 'prompt' }
AbScreenshotAttachment >> applyToPromptParams: params [

	params imagePrompt: self base64PngString mimeType: 'image/png'
]
