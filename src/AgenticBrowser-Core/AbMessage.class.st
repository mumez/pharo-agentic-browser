Class {
	#name : 'AbMessage',
	#superclass : 'Object',
	#instVars : [
		'sender',
		'text',
		'timestamp',
		'isApprovalRequest',
		'approvalResponse',
		'isThink'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbMessage class >> approvalRequestText: aString [

	^ self new
		  sender: #ai;
		  text: aString;
		  isApprovalRequest: true;
		  yourself
]

{ #category : 'instance creation' }
AbMessage class >> sender: aSenderSymbol text: aString [

	^ self sender: aSenderSymbol text: aString isThink: false
]

{ #category : 'instance creation' }
AbMessage class >> sender: aSenderSymbol text: aString isThink: aBoolean [

	^ self new
		  sender: aSenderSymbol;
		  text: aString;
		  isThink: aBoolean;
		  yourself
]

{ #category : 'operations' }
AbMessage >> appendText: aString [
	self text: self text , aString
]

{ #category : 'accessing' }
AbMessage >> approvalResponse [
	^ approvalResponse
]

{ #category : 'accessing' }
AbMessage >> approvalResponse: aSymbol [
	approvalResponse := aSymbol
]

{ #category : 'printing' }
AbMessage >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: sender;
		nextPutAll: ': ';
		nextPutAll: (text ifNil: [ '' ]);
		nextPut: $)
]

{ #category : 'initialization' }
AbMessage >> initialize [

	sender := #system.
	text := ''.
	timestamp := DateAndTime now.
	isApprovalRequest := false.
	isThink := false
]

{ #category : 'accessing' }
AbMessage >> isThink [

	^ isThink
]

{ #category : 'accessing' }
AbMessage >> isThink: aBoolean [

	isThink := aBoolean
]

{ #category : 'accessing' }
AbMessage >> isApprovalRequest [
	^ isApprovalRequest
]

{ #category : 'accessing' }
AbMessage >> isApprovalRequest: aBoolean [
	isApprovalRequest := aBoolean
]

{ #category : 'accessing' }
AbMessage >> sender [
	^ sender
]

{ #category : 'accessing' }
AbMessage >> sender: aSymbol [
	sender := aSymbol
]

{ #category : 'accessing' }
AbMessage >> text [
	^ text
]

{ #category : 'accessing' }
AbMessage >> text: aString [
	text := aString
]

{ #category : 'accessing' }
AbMessage >> timestamp [
	^ timestamp
]
