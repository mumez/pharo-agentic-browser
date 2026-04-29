Class {
	#name : 'AbChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageDisplay',
		'inputField',
		'sendButton',
		'cancelButton',
		'currentTopic',
		'pendingApprovalMessage'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbChatPresenter >> connectPresenters [

	sendButton action: [ self onSendButtonClicked ].
	cancelButton action: [ self onCancelButtonClicked ]
]

{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messageDisplay;
		  add: (SpBoxLayout newLeftToRight
				   add: inputField;
				   add: sendButton withConstraints: [ :c | c width: 80 ];
				   add: cancelButton withConstraints: [ :c | c width: 60 ];
				   yourself)
		  withConstraints: [ :c | c height: 60 ];
		  yourself
]

{ #category : 'api' }
AbChatPresenter >> enterApprovalMode: anAbMessage [

	pendingApprovalMessage := anAbMessage.
	inputField placeholder: ''.
	inputField text: ''.
	sendButton label: 'Confirm'.
	cancelButton label: 'Deny'
]

{ #category : 'api' }
AbChatPresenter >> exitApprovalMode [

	pendingApprovalMessage := nil.
	inputField placeholder: 'Type your request...'.
	sendButton label: 'Send'.
	cancelButton label: 'Cancel'
]

{ #category : 'initialization' }
AbChatPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable.

	inputField := self newText.
	inputField placeholder: 'Type your request...'.

	sendButton := self newButton.
	sendButton label: 'Send'.

	cancelButton := self newButton.
	cancelButton label: 'Cancel'
]

{ #category : 'private' }
AbChatPresenter >> isFirstMessageInTopic [

	^ currentTopic messages noneSatisfy: [ :m | m sender = #human ]
]

{ #category : 'private' }
AbChatPresenter >> onMessageAdded: anAbMessage [

	self rerenderMessages.
	anAbMessage isApprovalRequest ifTrue: [
		self enterApprovalMode: anAbMessage ]
]

{ #category : 'private' }
AbChatPresenter >> onCancelButtonClicked [

	currentTopic ifNil: [ ^ self ].
	pendingApprovalMessage
		ifNotNil: [ currentTopic resolveApproval: 'no' ]
		ifNil: [ currentTopic cancelPrompt ]
]

{ #category : 'private' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText |
	currentTopic ifNil: [ ^ self ].
	pendingApprovalMessage ifNotNil: [
		currentTopic resolveApproval: 'yes'.
		self exitApprovalMode.
		^ self ].
	text := inputField text trimmed.
	text isEmpty ifTrue: [ ^ self ].
	inputField text: ''.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	currentTopic sendPrompt: promptText
]

{ #category : 'private' }
AbChatPresenter >> onTopicStatusChanged: aTopic status: aStatus [

	Transcript crShow:
		'[AbLog] onTopicStatusChanged: topic='
		, aTopic title printString
		, ' status='
		, aStatus printString.
	aStatus = #working ifTrue: [ self exitApprovalMode ].
	self rerenderMessages
]

{ #category : 'private' }
AbChatPresenter >> rerenderMessages [

	currentTopic ifNil: [ ^ self ].
	messageDisplay text: (String streamContents: [ :s |
			 currentTopic messages do: [ :m |
				 s
					 nextPutAll: m displayText;
					 cr ] ])
]

{ #category : 'private' }
AbChatPresenter >> subscribeToTopic: aTopic [

	aTopic announcer
		when: AbMessageAdded
		do: [ :ann | self defer: [ self onMessageAdded: ann message ] ]
		for: self.
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann | self defer: [ self onTopicStatusChanged: ann topic status: ann status ] ]
		for: self
]

{ #category : 'api' }
AbChatPresenter >> topic: anAbTopic [

	| previousTopic |
	previousTopic := currentTopic.
	currentTopic := anAbTopic.
	previousTopic ifNotNil: [ :t | t announcer unsubscribe: self ].
	self subscribeToTopic: anAbTopic.
	self rerenderMessages
]

{ #category : 'testing' }
AbChatPresenter >> inputPlaceholder [

	^ inputField placeholder
]

{ #category : 'testing' }
AbChatPresenter >> sendButtonLabel [

	^ sendButton label
]

{ #category : 'testing' }
AbChatPresenter >> cancelButtonLabel [

	^ cancelButton label
]
