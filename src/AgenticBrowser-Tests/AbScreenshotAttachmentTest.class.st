Class {
	#name : 'AbScreenshotAttachmentTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testNameFormat [

	| name |
	name := AbScreenshotAttachment nextNameForDate: (Date year: 1999 month: 1 day: 1).
	self assert: (name beginsWith: 'sc-19990101-').
	self assert: (name endsWith: '001')
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testNextNameIncrementsSequence [

	| date a1 nextName |
	date := Date year: 2026 month: 5 day: 27.
	AbScreenshotAttachment screenshotDirectory ensureCreateDirectory.
	a1 := AbScreenshotAttachment saveForm: (Form extent: 2@2 depth: 32) forDate: date.
	[ nextName := AbScreenshotAttachment nextNameForDate: date.
	  self assert: (nextName endsWith: '002') ]
		ensure: [ a1 fileReference delete ]
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testSaveFormCreatesFile [

	| form attachment |
	form := Form extent: 4@4 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	[ self assert: attachment fileReference exists ]
		ensure: [ attachment fileReference delete ]
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testBase64PngStringIsNonEmpty [

	| form attachment |
	form := Form extent: 4@4 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	[ self assert: attachment base64PngString isString.
	  self deny: attachment base64PngString isEmpty ]
		ensure: [ attachment fileReference delete ]
]
