Class {
	#name : 'AbConstants',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'approval-options' }
AbConstants class >> allowOnce [

	^ #allow_once
]

{ #category : 'approval-options' }
AbConstants class >> defaultApprovalOptions [

	^ {
		  'Confirm' -> self allowOnce.
		  'Deny' -> self rejectOnce }
]

{ #category : 'approval-options' }
AbConstants class >> disconnected [

	^ #disconnected
]

{ #category : 'approval-options' }
AbConstants class >> rejectOnce [

	^ #reject_once
]
