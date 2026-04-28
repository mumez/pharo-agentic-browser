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
	inputField placeholder: 'Respond to AI (yes / no / always)...'.
	sendButton label: 'Confirm'.
	inputField text: ''
]

{ #category : 'api' }
AbChatPresenter >> exitApprovalMode [

	pendingApprovalMessage := nil.
	inputField placeholder: 'Type your request...'.
	sendButton label: 'Send'
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
	currentTopic cancelPrompt
]

{ #category : 'private' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText |
	text := inputField text trimmed.
	text isEmpty ifTrue: [ ^ self ].
	inputField text: ''.
	currentTopic ifNil: [ ^ self ].
	pendingApprovalMessage
		ifNotNil: [ currentTopic resolveApproval: text ]
		ifNil: [
			promptText := self isFirstMessageInTopic
			              ifTrue: [ '/st-buddy ' , text ]
			              ifFalse: [ text ].
			currentTopic sendPrompt: promptText ]
]

{ #category : 'private' }
AbChatPresenter >> onTopicStatusChanged: aTopic [

	aTopic status = #working ifTrue: [ self exitApprovalMode ].
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
		do: [ :ann | self defer: [ self onTopicStatusChanged: ann topic ] ]
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
