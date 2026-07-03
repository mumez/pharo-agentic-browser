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
