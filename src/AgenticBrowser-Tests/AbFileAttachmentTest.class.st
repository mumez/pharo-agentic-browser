Class {
	#name : 'AbFileAttachmentTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbFileAttachmentTest >> testUriStringPercentEncodesSpecialCharacters [

	| dir fileRef attachment |
	dir := FileLocator temp / ('ab-attach-' , UUID new asString36).
	dir ensureCreateDirectory.
	fileRef := dir / 'report#1 [2024]?.txt'.
	fileRef writeStreamDo: [ :stream | stream nextPutAll: 'hello' ].
	attachment := AbFileAttachment fromFileReference: fileRef.
	[ self deny: (attachment uriString includes: $#).
	  self deny: (attachment uriString includes: $?).
	  self deny: (attachment uriString includes: $ ).
	  self assert: (attachment uriString beginsWith: 'file:///') ]
		ensure: [ dir exists ifTrue: [ dir deleteAll ] ]
]

{ #category : 'tests' }
AbFileAttachmentTest >> testTextForPromptReturnsFullContentsWithinLimit [

	| dir fileRef attachment |
	dir := FileLocator temp / ('ab-attach-' , UUID new asString36).
	dir ensureCreateDirectory.
	fileRef := dir / 'notes.txt'.
	fileRef writeStreamDo: [ :stream | stream nextPutAll: 'hello' ].
	attachment := AbFileAttachment fromFileReference: fileRef.
	[ self assert: attachment textForPrompt equals: 'hello' ]
		ensure: [ dir exists ifTrue: [ dir deleteAll ] ]
]

{ #category : 'tests' }
AbFileAttachmentTest >> testTextForPromptTruncatesContentsExceedingMaxAttachmentSize [

	| dir fileRef attachment originalDefault |
	dir := FileLocator temp / ('ab-attach-' , UUID new asString36).
	dir ensureCreateDirectory.
	fileRef := dir / 'notes.txt'.
	fileRef writeStreamDo: [ :stream | stream nextPutAll: (String new: 20 withAll: $x) ].
	attachment := AbFileAttachment fromFileReference: fileRef.
	originalDefault := AbSettings default maxAttachmentSize.
	AbSettings default maxAttachmentSize: 10.
	[ self assert: attachment textForPrompt equals: (String new: 10 withAll: $x) , '...' ]
		ensure: [
			AbSettings default maxAttachmentSize: originalDefault.
			dir exists ifTrue: [ dir deleteAll ] ]
]

{ #category : 'tests' }
AbFileAttachmentTest >> testUriStringForPlainPath [

	| dir fileRef attachment |
	dir := FileLocator temp / ('ab-attach-' , UUID new asString36).
	dir ensureCreateDirectory.
	fileRef := dir / 'notes.txt'.
	fileRef writeStreamDo: [ :stream | stream nextPutAll: 'hello' ].
	attachment := AbFileAttachment fromFileReference: fileRef.
	[ self assert: attachment uriString equals: 'file://' , fileRef fullName ]
		ensure: [ dir exists ifTrue: [ dir deleteAll ] ]
]
