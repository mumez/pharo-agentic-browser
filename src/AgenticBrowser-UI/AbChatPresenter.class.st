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
		'isRefreshingDropdownItems',
		'modelDropList',
		'modelConfigId',
		'modelOptions',
		'modeDropList',
		'modeOptions',
		'modeConfigId',
		'screenshotButton'
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

	self refreshDropdownItems: [
		self commandsDropList items: aCollection asSortedCollection asArray ]
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
		  add: self statusBarPresenter withConstraints: [ :c | c height: 28 ];
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
		(cmd notNil and: [ self isRefreshingDropdownItems not ]) ifTrue: [
			normalInputPresenter inputField text: (self inputTextForCommand: cmd) ] ].
	modelDropList startWithoutSelection.
	modelDropList whenSelectedItemChangedDo: [ :modelName |
		(modelName notNil and: [ self isRefreshingDropdownItems not ]) ifTrue: [
			self onModelSelectedName: modelName ] ].
	modeDropList startWithoutSelection.
	modeDropList whenSelectedItemChangedDo: [ :modeName |
		(modeName notNil and: [ self isRefreshingDropdownItems not ]) ifTrue: [
			self onModeSelectedName: modeName ] ].
	self updateDropListsEnabled: false
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
		  add: (SpPanedLayout newTopToBottom
				   positionOfSlider: 0.82;
				   add: self messagesPresenter;
				   add: self normalInputPresenter;
				   yourself);
		  add: self statusBarPresenter withConstraints: [ :c | c height: 28 ];
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
	self layout: self defaultLayout.
	self syncModelDropListFromTopic: self currentTopic.
	self syncModeDropListFromTopic: self currentTopic
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
				 add: (modelDropList := statusBarPresenter newDropList)
				 withConstraints: [ :c | c width: 220 ];
				 add: (modeDropList := statusBarPresenter newDropList)
				 withConstraints: [ :c | c width: 120 ];
				 add: (screenshotButton := statusBarPresenter newButton)
				 withConstraints: [ :c | c width: 28 ];
				 add: statusBarPresenter newNullPresenter;
				 addLast: (statusLabel := statusBarPresenter newLabel) expand: false;
				 yourself).
	screenshotButton
		icon: AbUiConstants boxSelection;
		action: [ self onScreenshotButtonClicked ]
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
AbChatPresenter >> isRefreshingDropdownItems [

	^ isRefreshingDropdownItems ifNil: [ false ]
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
AbChatPresenter >> modelConfigId [

	^ modelConfigId ifNil: [ 'model' ]
]

{ #category : 'accessing' }
AbChatPresenter >> modelConfigId: aString [

	modelConfigId := aString
]

{ #category : 'accessing' }
AbChatPresenter >> modelDropList [

	^ modelDropList
]

{ #category : 'accessing' }
AbChatPresenter >> modelNames [

	^ self modelDropList items
]

{ #category : 'accessing' }
AbChatPresenter >> modelOptions [

	^ modelOptions ifNil: [ #() ]
]

{ #category : 'accessing' }
AbChatPresenter >> modelOptions: aCollection [

	modelOptions := (aCollection ifNil: [ #() ]) asArray
]

{ #category : 'accessing' }
AbChatPresenter >> selectedModelName [

	^ self modelDropList selectedItem
]

{ #category : 'private' }
AbChatPresenter >> refreshDropdownItems: aBlock [

	[ isRefreshingDropdownItems := true.
	aBlock value ] ensure: [ isRefreshingDropdownItems := false ]
]

{ #category : 'accessing' }
AbChatPresenter >> modeConfigId [

	^ modeConfigId ifNil: [ 'mode' ]
]

{ #category : 'accessing' }
AbChatPresenter >> modeConfigId: aString [

	modeConfigId := aString
]

{ #category : 'accessing' }
AbChatPresenter >> modeDropList [

	^ modeDropList
]

{ #category : 'accessing' }
AbChatPresenter >> screenshotButton [

	^ screenshotButton
]

{ #category : 'accessing' }
AbChatPresenter >> modeNames [

	^ self modeDropList items
]

{ #category : 'accessing' }
AbChatPresenter >> modeOptions [

	^ modeOptions ifNil: [ #() ]
]

{ #category : 'accessing' }
AbChatPresenter >> modeOptions: aCollection [

	modeOptions := (aCollection ifNil: [ #() ]) asArray
]

{ #category : 'accessing' }
AbChatPresenter >> selectedModeName [

	^ self modeDropList selectedItem
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
AbChatPresenter >> onModelSelectedName: aModelName [

	| topic selectedOption |
	topic := self currentTopic ifNil: [ ^ self ].
	self modelOptions ifEmpty: [
		^ topic setConfigOptionId: self modelConfigId value: aModelName ].
	selectedOption := self modelOptions
		                  detect: [ :option | option name = aModelName ]
		                  ifNone: [ ^ self ].
	topic
		setConfigOptionId: self modelConfigId
		value: selectedOption value
]

{ #category : 'event handling' }
AbChatPresenter >> onModeSelectedName: aModeName [

	| selectedOption |
	selectedOption := self modeOptions
				          detect: [ :option | option name = aModeName ]
				          ifNone: [ ^ self ].
	self currentTopic ifNil: [ ^ self ].
	self currentTopic
		setConfigOptionId: self modeConfigId
		value: selectedOption value
]

{ #category : 'event handling' }
AbChatPresenter >> onScreenshotButtonClicked [

	| attachment |
	attachment := AbScreenshotAttachment captureAndSave.
	attachment ifNil: [ ^ self ].
	self normalInputPresenter insertMention: attachment mentionString
]

{ #category : 'event handling' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText mentions resources screenshots |
	self currentTopic ifNil: [ ^ self ].
	text := self normalInputPresenter inputText trimmed.
	text ifEmpty: [ ^ self ].
	self normalInputPresenter clearInput.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	mentions := AbCodeMentionParser parseFrom: text.
	resources := AbCodeMentionEmbedder resourcesFor: mentions.
	screenshots := AbScreenshotParser parseFrom: text.
	screenshots do: [ :att | att fileReference exists ifTrue: [ resources add: att ] ].
	self currentTopic sendPrompt: promptText withResources: resources
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicCurrentModelChanged: aTopic [

	self syncModelDropListFromTopic: aTopic
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicCurrentModeChanged: aTopic mode: aModeString [

	self syncModeDropListFromTopic: aTopic
]

{ #category : 'event handling' }
AbChatPresenter >> onTopicStatusChanged: aTopic status: aStatus [

	self logger debug: 'onTopicStatusChanged: topic='
		, aTopic title printString
		, ' status='
		, aStatus printString.
	self normalInputPresenter cancelEnabled: aStatus = #working.
	self updateDropListsEnabled: aStatus = #endTurn.
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

{ #category : 'private' }
AbChatPresenter >> applyModelCurrentValue: aString [

	aString ifNil: [ ^ self syncModelDropListEmpty ].
	self modelDropList items: { aString }.
	self modelDropList selectIndex: 1
]

{ #category : 'private' }
AbChatPresenter >> applyModelOption: aModelOption [

	| flatOptions |
	flatOptions := self flattenedOptionsFrom: aModelOption options.
	flatOptions
		ifEmpty: [ self applyModelCurrentValue: aModelOption currentValue ]
		ifNotEmpty: [
		self applyModelOptions: flatOptions currentValue: aModelOption currentValue ]
]

{ #category : 'private' }
AbChatPresenter >> applyModelOptions: flatOptions currentValue: aString [

	| selectedModel |
	self modelOptions: flatOptions.
	self modelDropList items: (self modelOptions collect: [ :option | option name ]).
	selectedModel := self modelOptions
		                 detect: [ :option | option value = aString ]
		                 ifNone: [ nil ].
	selectedModel
		ifNil: [ self modelDropList startWithoutSelection ]
		ifNotNil: [ self modelDropList selectItem: selectedModel name ]
]

{ #category : 'private' }
AbChatPresenter >> flattenedOptionsFrom: aCollection [

	| result |
	result := OrderedCollection new.
	aCollection do: [ :item |
		(item isKindOf: ACPConfigSelectGroup)
			ifTrue: [ result addAllLast: item options ]
			ifFalse: [ result add: item ] ].
	^ result asArray
]

{ #category : 'private' }
AbChatPresenter >> syncModelDropListEmpty [

	self refreshDropdownItems: [
		self modelDropList items: #('- model -').
		self modelDropList selectIndex: 1 ]
]

{ #category : 'private' }
AbChatPresenter >> syncModelDropListFromTopic: aTopic [

	| modelOption |
	modelOption := aTopic ifNotNil: [ :t | t modelConfigOption ].
	modelOption ifNil: [ ^ self syncModelDropListEmpty ].
	self refreshDropdownItems: [
		self modelConfigId: modelOption id.
		self applyModelOption: modelOption ]
]

{ #category : 'private' }
AbChatPresenter >> updateDropListsEnabled: aBoolean [

	self commandsDropList enabled: aBoolean.
	self modelDropList enabled: aBoolean.
	self modeDropList enabled: aBoolean
]

{ #category : 'private' }
AbChatPresenter >> syncModeDropListEmpty [

	self refreshDropdownItems: [
		self modeDropList items: #('- mode -').
		self modeDropList selectIndex: 1 ]
]

{ #category : 'private' }
AbChatPresenter >> syncModeDropListFromTopic: aTopic [

	| modeOption selectedMode |
	modeOption := aTopic ifNotNil: [ :t | t modeConfigOption ].
	modeOption ifNil: [ ^ self syncModeDropListEmpty ].
	self refreshDropdownItems: [
		self modeConfigId: modeOption id.
		self modeOptions: modeOption options.
		self modeDropList items: (self modeOptions collect: [ :option | option name ]).
		selectedMode := self modeOptions
			                detect: [ :option | option value = modeOption currentValue ]
			                ifNone: [ nil ].
		selectedMode
			ifNil: [ self modeDropList startWithoutSelection ]
			ifNotNil: [ self modeDropList selectItem: selectedMode name ] ]
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
		do: [ :ann | self defer: [ self onTopicCurrentModelChanged: ann topic ] ]
		for: self.
	aTopic announcer
		when: AbTopicCurrentModeChanged
		do: [ :ann | self defer: [ self onTopicCurrentModeChanged: ann topic mode: ann mode ] ]
		for: self
]

{ #category : 'accessing' }
AbChatPresenter >> topic: anAbTopic [

	self unsubscribeFromTopic: self currentTopic.
	self currentTopic: anAbTopic.
	anAbTopic ifNil: [
		self commandNames: #().
		self onTopicCurrentModelChanged: nil.
		self onTopicCurrentModeChanged: nil mode: nil.
		normalInputPresenter cancelEnabled: false.
		self updateDropListsEnabled: false.
		self stopDotsAnimation.
		^ self ].
	self subscribeToTopic: anAbTopic.
	self rerenderMessages.
	self onAvailableCommandsChanged: anAbTopic commands: anAbTopic availableCommands.
	self onTopicCurrentModelChanged: anAbTopic.
	self onTopicCurrentModeChanged: anAbTopic mode: anAbTopic currentMode.
	self onTopicStatusChanged: anAbTopic status: anAbTopic status
]

{ #category : 'subscriptions' }
AbChatPresenter >> unsubscribeFromTopic: aTopic [

	aTopic ifNil: [ ^ self ].
	aTopic announcer unsubscribe: self
]
