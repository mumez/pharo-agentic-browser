Class {
	#name : 'AbChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messagesPresenter',
		'normalInputPresenter',
		'confirmPresenter',
		'currentTopic',
		'pendingApprovalMessage',
		'logger'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbChatPresenter >> initializePresenters [

	messagesPresenter := self instantiate: AbMessagesPresenter.
	normalInputPresenter := self instantiate: AbNormalInputPresenter.
	confirmPresenter := self instantiate: AbConfirmPresenter
]

{ #category : 'initialization' }
AbChatPresenter >> connectPresenters [

	normalInputPresenter onSendAction: [ self onSendButtonClicked ].
	normalInputPresenter onCancelAction: [ self onCancelButtonClicked ].
	confirmPresenter onConfirmAction: [ self onConfirmButtonClicked ].
	confirmPresenter onDenyAction: [ self onDenyButtonClicked ]
]

{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messagesPresenter;
		  add: normalInputPresenter withConstraints: [ :c | c height: 60 ];
		  yourself
]

{ #category : 'layout' }
AbChatPresenter >> confirmModeLayout [

	^ SpBoxLayout newTopToBottom
		  add: messagesPresenter;
		  add: confirmPresenter withConstraints: [ :c | c height: 90 ];
		  yourself
]

{ #category : 'private' }
AbChatPresenter >> enterApprovalMode: anAbMessage [

	self pendingApprovalMessage: anAbMessage.
	confirmPresenter confirmationText: anAbMessage text.
	self layout: self confirmModeLayout
]

{ #category : 'private' }
AbChatPresenter >> exitApprovalMode [

	self pendingApprovalMessage: nil.
	self layout: self defaultLayout
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
AbChatPresenter >> onSendButtonClicked [

	| text promptText |
	self currentTopic ifNil: [ ^ self ].
	text := normalInputPresenter inputText trimmed.
	text ifEmpty: [ ^ self ].
	normalInputPresenter clearInput.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	self currentTopic sendPrompt: promptText
]

{ #category : 'event handling' }
AbChatPresenter >> onCancelButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self currentTopic cancelPrompt
]

{ #category : 'event handling' }
AbChatPresenter >> onConfirmButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self currentTopic resolveApproval: 'yes'.
	self exitApprovalMode
]

{ #category : 'event handling' }
AbChatPresenter >> onDenyButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self currentTopic resolveApproval: 'no'.
	self exitApprovalMode
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicStatusChanged: aTopic status: aStatus [

	self logger debug: 'onTopicStatusChanged: topic='
		, aTopic title printString
		, ' status='
		, aStatus printString.
	self rerenderMessages
]

{ #category : 'private' }
AbChatPresenter >> rerenderMessages [

	self currentTopic ifNil: [ ^ self ].
	messagesPresenter renderMessages: self currentTopic messages
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
AbChatPresenter >> logger [

	^ logger ifNil: [ logger := AbLocalLogger new ]
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
AbChatPresenter >> messagesPresenter [

	^ messagesPresenter
]

{ #category : 'accessing' }
AbChatPresenter >> normalInputPresenter [

	^ normalInputPresenter
]

{ #category : 'accessing' }
AbChatPresenter >> confirmPresenter [

	^ confirmPresenter
]

{ #category : 'accessing' }
AbChatPresenter >> pendingApprovalMessage [

	^ pendingApprovalMessage
]

{ #category : 'accessing' }
AbChatPresenter >> pendingApprovalMessage: aMessage [

	pendingApprovalMessage := aMessage
]
