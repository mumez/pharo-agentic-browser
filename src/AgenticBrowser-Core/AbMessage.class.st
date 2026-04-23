Class {
	#name : 'AbMessage',
	#superclass : 'Object',
	#instVars : [
		'sender',
		'text',
		'timestamp',
		'isApprovalRequest',
		'approvalSemaphore',
		'approvalResponse'
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
		  approvalSemaphore: Semaphore new;
		  yourself
]

{ #category : 'instance creation' }
AbMessage class >> sender: aSenderSymbol text: aString [

	^ self new
		  sender: aSenderSymbol;
		  text: aString;
		  yourself
]

{ #category : 'operations' }
AbMessage >> appendText: aString [
	text := text , aString
]

{ #category : 'accessing' }
AbMessage >> approvalResponse [
	^ approvalResponse
]

{ #category : 'accessing' }
AbMessage >> approvalResponse: aSymbol [
	approvalResponse := aSymbol
]

{ #category : 'accessing' }
AbMessage >> approvalSemaphore [
	^ approvalSemaphore
]

{ #category : 'accessing' }
AbMessage >> approvalSemaphore: aSemaphore [
	approvalSemaphore := aSemaphore
]

{ #category : 'displaying' }
AbMessage >> displayText [
	| prefix |
	prefix := sender = #human
		ifTrue: [ '[Human] ' ]
		ifFalse: [ sender = #ai
			ifTrue: [ isApprovalRequest ifTrue: [ '[⏸ AI] ' ] ifFalse: [ '[AI] ' ] ]
			ifFalse: [ '[System] ' ] ].
	^ prefix , text
]

{ #category : 'initialization' }
AbMessage >> initialize [

	sender := #system.
	text := ''.
	timestamp := DateAndTime now.
	isApprovalRequest := false
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
