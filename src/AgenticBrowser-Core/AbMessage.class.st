Class {
	#name : 'AbMessage',
	#superclass : 'Object',
	#instVars : [
		'sender',
		'text',
		'lastUpdated',
		'isAiPermission',
		'isExportApproval',
		'approvalResponse',
		'isThink',
		'approvalOptions'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbMessage class >> aiPermissionRequestText: aString [
	^ self aiPermissionRequestText: aString options: #()
]

{ #category : 'instance creation' }
AbMessage class >> aiPermissionRequestText: aString options: aCollection [
	^ self new
		  sender: #ai;
		  text: aString;
		  isAiPermission: true;
		  approvalOptions: aCollection;
		  yourself
]

{ #category : 'instance creation' }
AbMessage class >> exportApprovalRequestText: aString [
	^ self exportApprovalRequestText: aString options: #()
]

{ #category : 'instance creation' }
AbMessage class >> exportApprovalRequestText: aString options: aCollection [
	^ self new
		  sender: #ai;
		  text: aString;
		  isExportApproval: true;
		  approvalOptions: aCollection;
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
AbMessage >> approvalOptions [
	^ approvalOptions
]

{ #category : 'accessing' }
AbMessage >> approvalOptions: aCollection [
	approvalOptions := (aCollection ifNil: [ #() ]) asArray
]

{ #category : 'accessing' }
AbMessage >> approvalResponse [
	^ approvalResponse
]

{ #category : 'accessing' }
AbMessage >> approvalResponse: aSymbol [
	approvalResponse := aSymbol
]

{ #category : 'initialization' }
AbMessage >> initialize [

	sender := #system.
	text := ''.
	lastUpdated := DateAndTime now.
	isAiPermission := false.
	isExportApproval := false.
	isThink := false.
	approvalOptions := #()
]

{ #category : 'accessing' }
AbMessage >> isAiPermission [
	^ isAiPermission
]

{ #category : 'accessing' }
AbMessage >> isAiPermission: aBoolean [
	isAiPermission := aBoolean
]

{ #category : 'accessing' }
AbMessage >> isApprovalRequest [
	^ isAiPermission or: [ isExportApproval ]
]

{ #category : 'accessing' }
AbMessage >> isExportApproval [
	^ isExportApproval
]

{ #category : 'accessing' }
AbMessage >> isExportApproval: aBoolean [
	isExportApproval := aBoolean
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
AbMessage >> lastUpdated [
	^ lastUpdated
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
	text := aString.
	lastUpdated := DateAndTime now
]
