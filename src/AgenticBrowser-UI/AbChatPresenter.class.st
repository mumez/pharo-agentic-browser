Class {
	#name : 'AbChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messagesPresenter',
		'normalInputPresenter',
		'confirmPresenter',
		'currentTopic',
		'pendingApprovalMessage',
		'logger',
		'dotsAnimationProcess',
		'statusBarPresenter',
		'statusLabel',
		'commandsDropList'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbChatPresenter >> initializePresenters [

	super initializePresenters.
	messagesPresenter := self instantiate: AbMessagesPresenter.
	normalInputPresenter := self instantiate: AbNormalInputPresenter.
	confirmPresenter := self instantiate: AbConfirmPresenter.
	self initializeStatusBar
]

{ #category : 'initialization' }
AbChatPresenter >> initializeStatusBar [

	(statusBarPresenter := self instantiate: SpPresenter)
		layout: (SpBoxLayout newLeftToRight
				 borderWidth: 2;
				 vAlignCenter;
				 add: (commandsDropList := statusBarPresenter newDropList)
				 withConstraints: [ :c | c width: 120 ];
				 addLast: (statusLabel := statusBarPresenter newLabel) expand: false;
				 yourself)
]

{ #category : 'initialization' }
AbChatPresenter >> connectPresenters [

	normalInputPresenter onSendAction: [ self onSendButtonClicked ].
	normalInputPresenter onCancelAction: [ self onCancelButtonClicked ].
	confirmPresenter onConfirmAction: [ self onConfirmButtonClicked ].
	confirmPresenter onDenyAction: [ self onDenyButtonClicked ].
	normalInputPresenter cancelEnabled: false.
	commandsDropList whenSelectedItemChangedDo: [ :cmd |
		cmd ifNotNil: [ normalInputPresenter inputField text: cmd , ' ' ] ]
]

{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messagesPresenter;
		  add: normalInputPresenter withConstraints: [ :c | c height: 60 ];
		  add: statusBarPresenter withConstraints: [ :c | c height: 24 ];
		  yourself
]

{ #category : 'layout' }
AbChatPresenter >> confirmModeLayout [

	^ SpBoxLayout newTopToBottom
		  add: messagesPresenter;
		  add: confirmPresenter withConstraints: [ :c | c height: 90 ];
		  add: statusBarPresenter withConstraints: [ :c | c height: 24 ];
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

	messagesPresenter addOrUpdateMessage: anAbMessage.
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
AbChatPresenter >> onAvailableCommandsChanged: aTopic commands: aCollection [

	self commandNames: (aCollection collect: [ :cmd | cmd name ])
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicStatusChanged: aTopic status: aStatus [

	self logger debug: 'onTopicStatusChanged: topic='
		, aTopic title printString
		, ' status='
		, aStatus printString.
	normalInputPresenter cancelEnabled: aStatus = #working.
	aStatus = #working
		ifTrue: [ self startDotsAnimation ]
		ifFalse: [ self stopDotsAnimation ].
	messagesPresenter refreshMessages
]

{ #category : 'accessing' }
AbChatPresenter >> statusText [

	^ self statusLabel label
]

{ #category : 'accessing' }
AbChatPresenter >> statusText: aString [

	self statusLabel label: aString
]

{ #category : 'accessing' }
AbChatPresenter >> clearStatusText [

	self statusText: ''
]

{ #category : 'accessing' }
AbChatPresenter >> commandNames [

	^ self commandsDropList items
]

{ #category : 'accessing' }
AbChatPresenter >> commandNames: aCollection [

	self commandsDropList items: aCollection asArray
]

{ #category : 'accessing' }
AbChatPresenter >> statusBarPresenter [

	^ statusBarPresenter
]

{ #category : 'accessing' }
AbChatPresenter >> statusLabel [

	^ statusLabel
]

{ #category : 'accessing' }
AbChatPresenter >> commandsDropList [

	^ commandsDropList
]

{ #category : 'private' }
AbChatPresenter >> nextDotsTextAfter: aString [

	aString = '' ifTrue: [ ^ '.' ].
	aString = '.' ifTrue: [ ^ '..' ].
	aString = '..' ifTrue: [ ^ '...' ].
	^ ''
]

{ #category : 'accessing' }
AbChatPresenter >> dotsAnimationProcess [

	^ dotsAnimationProcess
]

{ #category : 'accessing' }
AbChatPresenter >> dotsAnimationProcess: aProcess [

	dotsAnimationProcess := aProcess
]

{ #category : 'private' }
AbChatPresenter >> startDotsAnimation [

	| process |
	self stopDotsAnimation.
	process := [
		| dots |
		dots := ''.
		[ true ] whileTrue: [
			dots := self nextDotsTextAfter: dots.
			self defer: [ self statusText: dots ].
			500 milliSeconds wait ] ] newProcess.
	process priority: Processor userBackgroundPriority.
	process resume.
	self dotsAnimationProcess: process
]

{ #category : 'private' }
AbChatPresenter >> stopDotsAnimation [

	self dotsAnimationProcess ifNotNil: [ :p |
		p terminate.
		self dotsAnimationProcess: nil ].
	self clearStatusText
]

{ #category : 'private' }
AbChatPresenter >> rerenderMessages [

	self currentTopic ifNil: [ ^ self ].
	messagesPresenter setMessages: self currentTopic messages
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
		for: self.
	aTopic announcer
		when: AbTopicAvailableCommandsChanged
		do: [ :ann | self defer: [ self onAvailableCommandsChanged: ann topic commands: ann commands ] ]
		for: self
]

{ #category : 'subscriptions' }
AbChatPresenter >> unsubscribeFromTopic: aTopic [

	aTopic ifNil: [ ^ self ].
	aTopic announcer unsubscribe: self
]

{ #category : 'initialization' }
AbChatPresenter >> destroy [

	self stopDotsAnimation.
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

{ #category : 'accessing' }
AbChatPresenter >> currentAnswerAreaPresenter [
	"Returns the currently active answer area presenter: confirmPresenter in approval mode,
	 normalInputPresenter otherwise."

	^ pendingApprovalMessage
		  ifNil: [ normalInputPresenter ]
		  ifNotNil: [ confirmPresenter ]
]
