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
		'commandsDropList',
		'isUpdatingCommands',
		'modelLabel'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

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

	self isUpdatingCommands: true.
	[ self commandsDropList items: aCollection asArray ] ensure: [
		self isUpdatingCommands: false ]
]

{ #category : 'accessing' }
AbChatPresenter >> commandsDropList [

	^ commandsDropList
]

{ #category : 'layout' }
AbChatPresenter >> confirmModeLayout [

	^ SpBoxLayout newTopToBottom
		  add: self messagesPresenter;
		  add: self confirmPresenter withConstraints: [ :c | c height: 90 ];
		  add: self statusBarPresenter withConstraints: [ :c | c height: 24 ];
		  yourself
]

{ #category : 'accessing' }
AbChatPresenter >> confirmPresenter [

	^ confirmPresenter
]

{ #category : 'initialization' }
AbChatPresenter >> connectPresenters [

	normalInputPresenter onSendAction: [ self onSendButtonClicked ].
	normalInputPresenter onCancelAction: [ self onCancelButtonClicked ].
	confirmPresenter onConfirmAction: [ self onConfirmButtonClicked ].
	confirmPresenter onDenyAction: [ self onDenyButtonClicked ].
	normalInputPresenter cancelEnabled: false.
	commandsDropList startWithoutSelection.
	commandsDropList whenSelectedItemChangedDo: [ :cmd |
		(cmd notNil and: [ self isUpdatingCommands not ]) ifTrue: [
			normalInputPresenter inputField text: (self inputTextForCommand: cmd) ] ]
]

{ #category : 'accessing' }
AbChatPresenter >> currentAnswerAreaPresenter [
	"Returns the currently active answer area presenter: confirmPresenter in approval mode,
	 normalInputPresenter otherwise."

	^ pendingApprovalMessage
		  ifNil: [ normalInputPresenter ]
		  ifNotNil: [ confirmPresenter ]
]

{ #category : 'accessing' }
AbChatPresenter >> currentTopic [

	^ currentTopic
]

{ #category : 'accessing' }
AbChatPresenter >> currentTopic: aTopic [

	currentTopic := aTopic
]

{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: self messagesPresenter;
		  add: self normalInputPresenter withConstraints: [ :c | c height: 60 ];
		  add: self statusBarPresenter withConstraints: [ :c | c height: 24 ];
		  yourself
]

{ #category : 'initialization' }
AbChatPresenter >> release [

	self stopDotsAnimation.
	self unsubscribeFromTopic: self currentTopic
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
AbChatPresenter >> enterApprovalMode: anAbMessage [

	self pendingApprovalMessage: anAbMessage.
	self confirmPresenter confirmationText: anAbMessage text.
	self confirmPresenter approvalOptions: anAbMessage approvalOptions.
	self layout: self confirmModeLayout
]

{ #category : 'private' }
AbChatPresenter >> exitApprovalMode [

	self pendingApprovalMessage: nil.
	self layout: self defaultLayout
]

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
				 add: (modelLabel := statusBarPresenter newLabel) expand: false;
				 add: statusBarPresenter newNullPresenter;
				 addLast: (statusLabel := statusBarPresenter newLabel) expand: false;
				 yourself)
]

{ #category : 'private' }
AbChatPresenter >> inputTextForCommand: aString [
	| insertString |
	insertString := '/{1} '.
	^ insertString format: {aString}
]

{ #category : 'private' }
AbChatPresenter >> isFirstMessageInTopic [

	^ self currentTopic messages noneSatisfy: [ :m | m sender = #human ]
]

{ #category : 'accessing' }
AbChatPresenter >> isUpdatingCommands [

	^ isUpdatingCommands ifNil: [ false ]
]

{ #category : 'accessing' }
AbChatPresenter >> isUpdatingCommands: aBoolean [

	isUpdatingCommands := aBoolean
]

{ #category : 'accessing' }
AbChatPresenter >> logger [

	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbChatPresenter >> messagesPresenter [

	^ messagesPresenter
]

{ #category : 'accessing' }
AbChatPresenter >> modelLabel [

	^ modelLabel
]

{ #category : 'accessing' }
AbChatPresenter >> modelText [

	^ self modelLabel label
]

{ #category : 'accessing' }
AbChatPresenter >> modelText: aString [

	self modelLabel label: aString
]

{ #category : 'private' }
AbChatPresenter >> nextDotsTextAfter: aString [

	aString = '' ifTrue: [ ^ '.' ].
	aString = '.' ifTrue: [ ^ '..' ].
	aString = '..' ifTrue: [ ^ '...' ].
	^ ''
]

{ #category : 'accessing' }
AbChatPresenter >> normalInputPresenter [

	^ normalInputPresenter
]

{ #category : 'event handling' }
AbChatPresenter >> onAvailableCommandsChanged: aTopic commands: aCollection [

	self commandNames: ((aCollection ifNil: [ #() ]) collect: [ :cmd | cmd name ])
]

{ #category : 'event handling' }
AbChatPresenter >> onCancelButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self currentTopic cancelPrompt
]

{ #category : 'event handling' }
AbChatPresenter >> onConfirmButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self currentTopic
		resolveApprovalWithOptionId: self confirmPresenter selectedOptionId.
	self exitApprovalMode
]

{ #category : 'event handling' }
AbChatPresenter >> onDenyButtonClicked [

	self currentTopic ifNil: [ ^ self ].
	self currentTopic
		resolveApprovalWithOptionId: self confirmPresenter selectedOptionIdForDenyAction.
	self exitApprovalMode
]

{ #category : 'event handling' }
AbChatPresenter >> onMessageAdded: anAbMessage [

	self messagesPresenter addOrUpdateMessage: anAbMessage.
	anAbMessage isApprovalRequest ifTrue: [
		self enterApprovalMode: anAbMessage ]
]

{ #category : 'event handling' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText mentions resources |
	self currentTopic ifNil: [ ^ self ].
	text := self normalInputPresenter inputText trimmed.
	text ifEmpty: [ ^ self ].
	self normalInputPresenter clearInput.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	mentions := AbCodeMentionParser parseFrom: text.
	resources := AbCodeMentionEmbedder resourcesFor: mentions.
	self currentTopic sendPrompt: promptText withResources: resources
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicCurrentModelChanged: aTopic model: aModelString [

	self modelText: (aModelString ifNil: [ '' ])
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicStatusChanged: aTopic status: aStatus [

	self logger debug: 'onTopicStatusChanged: topic='
		, aTopic title printString
		, ' status='
		, aStatus printString.
	self normalInputPresenter cancelEnabled: aStatus = #working.
	aStatus = #working
		ifTrue: [ self startDotsAnimation ]
		ifFalse: [ self stopDotsAnimation ].
	self messagesPresenter refreshMessages
]

{ #category : 'accessing' }
AbChatPresenter >> pendingApprovalMessage [

	^ pendingApprovalMessage
]

{ #category : 'accessing' }
AbChatPresenter >> pendingApprovalMessage: aMessage [

	pendingApprovalMessage := aMessage
]

{ #category : 'private' }
AbChatPresenter >> rerenderMessages [

	self currentTopic ifNil: [ ^ self ].
	self messagesPresenter setMessages: self currentTopic messages
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

{ #category : 'accessing' }
AbChatPresenter >> statusBarPresenter [

	^ statusBarPresenter
]

{ #category : 'accessing' }
AbChatPresenter >> statusLabel [

	^ statusLabel
]

{ #category : 'accessing' }
AbChatPresenter >> statusText [

	^ self statusLabel label
]

{ #category : 'accessing' }
AbChatPresenter >> statusText: aString [

	self statusLabel label: aString
]

{ #category : 'private' }
AbChatPresenter >> stopDotsAnimation [

	self dotsAnimationProcess ifNotNil: [ :p |
		p terminate.
		self dotsAnimationProcess: nil ].
	self clearStatusText
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
		for: self.
	aTopic announcer
		when: AbTopicCurrentModelChanged
		do: [ :ann | self defer: [ self onTopicCurrentModelChanged: ann topic model: ann model ] ]
		for: self
]

{ #category : 'accessing' }
AbChatPresenter >> topic: anAbTopic [

	self unsubscribeFromTopic: self currentTopic.
	self currentTopic: anAbTopic.
	anAbTopic ifNil: [
		self commandNames: #().
		normalInputPresenter cancelEnabled: false.
		self stopDotsAnimation.
		^ self ].
	self subscribeToTopic: anAbTopic.
	self rerenderMessages.
	self onAvailableCommandsChanged: anAbTopic commands: anAbTopic availableCommands.
	self onTopicCurrentModelChanged: anAbTopic model: anAbTopic currentModel.
	self onTopicStatusChanged: anAbTopic status: anAbTopic status
]

{ #category : 'subscriptions' }
AbChatPresenter >> unsubscribeFromTopic: aTopic [

	aTopic ifNil: [ ^ self ].
	aTopic announcer unsubscribe: self
]
