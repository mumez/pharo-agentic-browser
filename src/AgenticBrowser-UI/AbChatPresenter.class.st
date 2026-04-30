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

{ #category : 'private' }
AbChatPresenter >> enterApprovalMode: anAbMessage [

	self pendingApprovalMessage: anAbMessage.
	self inputField placeholder: ''.
	self inputField text: ''.
	self sendButton label: 'Confirm'.
	self cancelButton label: 'Deny'
]

{ #category : 'private' }
AbChatPresenter >> exitApprovalMode [

	self pendingApprovalMessage: nil.
	self inputField placeholder: 'Type your request...'.
	self sendButton label: 'Send'.
	self cancelButton label: 'Cancel'
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

	^ self currentTopic messages noneSatisfy: [ :m | m sender = #human ]
]

{ #category : 'event handling' }
AbChatPresenter >> onMessageAdded: anAbMessage [

	self rerenderMessages.
	anAbMessage isApprovalRequest ifTrue: [
		self enterApprovalMode: anAbMessage ]
]

{ #category : 'event handling' }
AbChatPresenter >> onCancelButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self pendingApprovalMessage
		ifNotNil: [ self currentTopic resolveApproval: 'no' ]
		ifNil: [ self currentTopic cancelPrompt ]
]

{ #category : 'event handling' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText |
	self currentTopic ifNil: [ ^ self ].
	self pendingApprovalMessage ifNotNil: [
		self currentTopic resolveApproval: 'yes'.
		self exitApprovalMode.
		^ self ].
	text := self inputField text trimmed.
	text ifEmpty: [ ^ self ].
	self inputField text: ''.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	self currentTopic sendPrompt: promptText
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicStatusChanged: aTopic status: aStatus [

	Transcript crShow:
		'[AbLog] onTopicStatusChanged: topic='
		, aTopic title printString
		, ' status='
		, aStatus printString.
	self rerenderMessages
]

{ #category : 'private' }
AbChatPresenter >> rerenderMessages [

	self currentTopic ifNil: [ ^ self ].
	messageDisplay text: (String streamContents: [ :s |
			 self currentTopic messages do: [ :m |
				 s
					 nextPutAll: m displayText;
					 cr ] ])
]

{ #category : 'subscriptions' }
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

{ #category : 'subscriptions' }
AbChatPresenter >> unsubscribeFromTopic: aTopic [

	aTopic ifNil: [ ^ self ].
	aTopic announcer unsubscribe: self
]

{ #category : 'initialization' }
AbChatPresenter >> destroy [

	self unsubscribeFromTopic: self currentTopic.
	super destroy
]

{ #category : 'accessing' }
AbChatPresenter >> topic: anAbTopic [

	self unsubscribeFromTopic: self currentTopic.
	self currentTopic: anAbTopic.
	self subscribeToTopic: anAbTopic.
	self rerenderMessages
]

{ #category : 'accessing' }
AbChatPresenter >> cancelButton [

	^ cancelButton
]

{ #category : 'accessing' }
AbChatPresenter >> currentTopic [

	^ currentTopic
]

{ #category : 'accessing' }
AbChatPresenter >> currentTopic: aTopic [

	currentTopic := aTopic
]

{ #category : 'accessing' }
AbChatPresenter >> inputField [

	^ inputField
]

{ #category : 'accessing' }
AbChatPresenter >> pendingApprovalMessage [

	^ pendingApprovalMessage
]

{ #category : 'accessing' }
AbChatPresenter >> pendingApprovalMessage: aMessage [

	pendingApprovalMessage := aMessage
]

{ #category : 'accessing' }
AbChatPresenter >> sendButton [

	^ sendButton
]

{ #category : 'testing' }
AbChatPresenter >> inputPlaceholder [

	^ self inputField placeholder
]

{ #category : 'testing' }
AbChatPresenter >> sendButtonLabel [

	^ self sendButton label
]

{ #category : 'testing' }
AbChatPresenter >> cancelButtonLabel [

	^ self cancelButton label
]
