"
I represent a single message in a topic's conversation history.

Responsibility:
- I store the sender role (#human, #ai, or #system), message text, and last-updated timestamp.
- I distinguish regular AI text, AI thinking/reasoning text, AI permission requests, and package export approval requests.
- I track the chosen approval option once a human (or timeout) has resolved an approval request.

Collaborators:
- AbTopic: It adds me to its messages collection and reads me for pending approvals.
- AbTopicRelatedPackagesWatcher: It creates export approval request messages via class>>exportApprovalRequestText:.
- AbMessageRichTextBuilder (AgenticBrowser-UI): It renders me as rich text via #asPresenter.

Public API and Key Messages:
- AbMessage class>>sender:text: - Create a regular human or system message.
- AbMessage class>>aiPermissionRequestText:options: - Create an AI permission request message.
- AbMessage class>>exportApprovalRequestText:options: - Create a package export approval request.
- #isApprovalRequest - Returns true for either type of approval request.
- #approvalOption / #approvalOption: - The response chosen by the human (or set on timeout); nil until resolved.
- #appendText: - Extend AI message text incrementally as streaming chunks arrive.

Internal Representation:
- sender - Symbol: #human, #ai, or #system.
- isAiPermission / isExportApproval - Mutually exclusive booleans distinguishing the two request types.
- approvalOptions - Array of available option associations displayed in the UI.
- isThink - true for AI thinking/reasoning text (rendered differently in the UI).
- lastUpdated - Refreshed on every #text: to support last-updated sorting of topics.
"
Class {
	#name : 'AbMessage',
	#superclass : 'Object',
	#instVars : [
		'sender',
		'text',
		'lastUpdated',
		'isAiPermission',
		'isExportApproval',
		'approvalOption',
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
AbMessage >> approvalOption [
	^ approvalOption
]

{ #category : 'accessing' }
AbMessage >> approvalOption: aSymbol [
	approvalOption := aSymbol
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
