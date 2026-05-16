Class {
	#name : 'AbTopicListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'topicList',
		'sortDropList',
		'newTopicButton',
		'onTopicSelectedBlock',
		'sortMode'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbTopicListPresenter >> applyUpdatedExternalPackagesFor: aTopic [

	| packageNames |
	packageNames := aTopic updatedExternalPackageNames asSortedCollection.
	packageNames ifEmpty: [
		aTopic addSystemMessage: 'No externally updated packages to apply.'.
		^ self ].
	packageNames do: [ :packageName | aTopic addPackagePrefix: packageName ].
	aTopic clearUpdatedExternalPackageNames.
	self onPackagePrefixSet: aTopic.
	aTopic addSystemMessage:
		'Added ' , packageNames size printString
		, ' external package(s) to tracked prefixes.'
]

{ #category : 'private' }
AbTopicListPresenter >> buildTopicContextMenu [

	| topic notWorking |
	topic := topicList selectedItem.
	notWorking := topic isWorking not.
	^ SpMenuPresenter new
		  addGroup: [ :group |
			  group
				  addItem: [ :item | item name: 'Rename...'; action: [ self onRenameTopicRequest ] ];
				  addItem: [ :item | item name: 'Delete'; enabled: notWorking; action: [ self onDeleteTopicRequest ] ];
				  addItem: [ :item | item name: 'Inspect...'; action: [ self onInspectTopicRequest ] ] ];
		  addGroup: [ :group |
			  group
				  addItem: [ :item | item name: 'Change Agent...'; enabled: notWorking; action: [ self onSetAgentRequest ] ];
				  addItem: [ :item | item name: 'Set Goal...'; action: [ self onSetGoalRequest ] ];
				  addItem: [ :item | item name: 'Set Working Directory...'; enabled: notWorking; action: [ self onSetWorkingDirectoryRequest ] ];
				  addItem: [ :item | item name: 'Clear Session ID'; enabled: notWorking; action: [ self onClearSessionIdRequest ] ] ];
		  addGroup: [ :group |
			  group
				  addItem: [ :item | item name: 'Set Target Packages...'; enabled: notWorking; action: [ self onSetTargetPackagesRequest ] ];
				  addItem: [ :item | item name: 'Apply Updated External Packages'; enabled: notWorking; action: [ self onApplyUpdatedExternalPackagesRequest ] ] ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> connectPresenters [

	topicList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :topic |
			onTopicSelectedBlock ifNotNil: [ onTopicSelectedBlock value: topic ] ] ].
	topicList contextMenu: [ topicList selectedItem ifNotNil: [ self buildTopicContextMenu ] ].
	sortDropList whenSelectedItemChangedDo: [ :selected |
		selected ifNotNil: [
			self sortMode: selected value.
			self refresh ] ].
	newTopicButton action: [ self onNewTopicRequest ].
	self subscribeToTopicManager.
	self refresh
]

{ #category : 'layout' }
AbTopicListPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: (SpBoxLayout newLeftToRight
				   vAlignCenter;
				   add: (self newLabel label: 'Sort:') withConstraints: [ :c | c width: 40 ];
				   add: self sortDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: self topicList;
		  add: self newTopicButton
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> release [

	self unsubscribeFromTopicManager
]

{ #category : 'private' }
AbTopicListPresenter >> iconNameFor: aTopic [

	aTopic isInitial ifTrue: [ ^ #whiteCircle ].
	aTopic isWorking ifTrue: [ ^ #sparkle ].
	aTopic isWaitingForHuman ifTrue: [ ^ #question ].
	aTopic isGoalAchieved ifTrue: [ ^ #check ].
	aTopic isEndTurn ifTrue: [ ^ #greenCircle ].
	^ #redCircle
]

{ #category : 'initialization' }
AbTopicListPresenter >> initializePresenters [

	super initializePresenters.
	topicList := self newList.
	topicList display: [ :topic | self topicListLabelFor: topic ].
	topicList displayIcon: [ :item |
		AbUiConstants iconNamed: (self iconNameFor: item) ].
	sortDropList := self newDropList.
	sortDropList items: self sortOptions.
	sortDropList display: [ :option | option key ].
	sortMode := #lastUpdated.
	sortDropList selectItem: self sortOptions second.
	newTopicButton := self newButton.
	newTopicButton label: '+ New Topic'
]

{ #category : 'accessing' }
AbTopicListPresenter >> newTopicButton [

	^ newTopicButton
]

{ #category : 'private' }
AbTopicListPresenter >> onApplyUpdatedExternalPackagesRequest [

	| topic |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	self applyUpdatedExternalPackagesFor: topic
]

{ #category : 'private' }
AbTopicListPresenter >> onClearSessionIdRequest [

	| topic |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	topic clearSessionId
]

{ #category : 'private' }
AbTopicListPresenter >> onDeleteTopicRequest [

	| selectedTopic |
	selectedTopic := self topicList selectedItem.
	selectedTopic ifNil: [ ^ self ].
	(UIManager default
		 confirm: 'Delete topic "' , selectedTopic title , '"?'
		 label: 'Confirm Delete')
		ifTrue: [
			AbTopicManager uniqueInstance removeTopic: selectedTopic.
			self defer: [ self refresh ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onInspectTopicRequest [

	| selectedTopic |
	selectedTopic := self topicList selectedItem.
	selectedTopic ifNil: [ ^ self ].
	selectedTopic inspect
]

{ #category : 'private' }
AbTopicListPresenter >> onNewTopicRequest [

	| dialog |
	dialog := AbNewTopicDialog new.
	dialog openModal.
	dialog topic ifNotNil: [ :topic |
		AbTopicManager uniqueInstance addTopic: topic.
		self defer: [ self refresh. self topicList selectItem: topic ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onPackagePrefixSet: aTopic [

	| workDir matchingNames |
	workDir := aTopic workingDirectory.
	matchingNames := aTopic matchingPackageNames.
	matchingNames
		ifEmpty: [
			aTopic addSystemMessage:
				'No packages match ' , aTopic packagePrefixes asSortedCollection printString
				, '. Starting new project development.' ]
		ifNotEmpty: [
			aTopic addSystemMessage:
				'Tracking ' , matchingNames size printString , ' package(s). Working directory: '
				, workDir path fullName ]
]

{ #category : 'private' }
AbTopicListPresenter >> onRenameTopicRequest [

	| selectedTopic newTitle |
	selectedTopic := self topicList selectedItem.
	selectedTopic ifNil: [ ^ self ].
	newTitle := UIManager default
				    request: 'New title:'
				    initialAnswer: selectedTopic title
				    title: 'Rename Topic'.
	(newTitle isNil or: [ newTitle trimmed isEmpty ]) ifTrue: [ ^ self ].
	selectedTopic title: newTitle trimmed.
	self defer: [ self refresh ]
]

{ #category : 'private' }
AbTopicListPresenter >> onSetAgentRequest [

	| topic dialog |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	dialog := AbSetAgentDialog new.
	dialog selectCurrentArguments: topic agentArguments.
	dialog openModal.
	dialog selectedArguments ifNil: [ ^ self ].
	topic sessionId ifNotNil: [
		(UIManager default
			 confirm: 'The active agent session will be disconnected. Continue?'
			 label: 'Change Agent') ifFalse: [ ^ self ].
		topic clearSessionId ].
	topic agentArguments: dialog selectedArguments.
	self defer: [ self refresh ]
]

{ #category : 'private' }
AbTopicListPresenter >> onSetGoalRequest [

	| topic goalText |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	goalText := UIManager default
		request: 'Goal (completion condition):'
		initialAnswer: (topic topicGoal ifNotNil: [ :g | g description ] ifNil: [ '' ])
		title: 'Set Goal'.
	(goalText isNil or: [ goalText trimmed isEmpty ]) ifTrue: [ ^ self ].
	topic goalDescription: goalText trimmed
]

{ #category : 'private' }
AbTopicListPresenter >> onSetTargetPackagesRequest [

	| topic dialog |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	dialog := AbPackagePrefixesDialog new.
	dialog openModal.
	dialog prefixPatterns
		ifEmpty: [ topic packagePrefixes: Set new ]
		ifNotEmpty: [ dialog prefixPatterns do: [ :pattern |
			topic addPackagePrefix: pattern ] ].
	self onPackagePrefixSet: topic
]

{ #category : 'private' }
AbTopicListPresenter >> onSetWorkingDirectoryRequest [

	| topic directoryPath |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	directoryPath := UIManager default
		request: 'Working directory path:'
		initialAnswer: topic workingDirectoryPath
		title: 'Set Working Directory'.
	(directoryPath isNil or: [ directoryPath trimmed isEmpty ])
		ifTrue: [ ^ self ].
	topic workingDirectoryPath: directoryPath trimmed.
	self defer: [ self refresh ]
]

{ #category : 'accessing' }
AbTopicListPresenter >> onTopicSelected: aBlock [

	onTopicSelectedBlock := aBlock
]

{ #category : 'refreshing' }
AbTopicListPresenter >> refresh [

	| items |
	items := AbTopicManager uniqueInstance topics asArray.
	self topicList items: (self sortedTopics: items)
]

{ #category : 'accessing' }
AbTopicListPresenter >> sortDropList [

	^ sortDropList
]

{ #category : 'accessing' }
AbTopicListPresenter >> sortMode [

	^ sortMode ifNil: [ #lastUpdated ]
]

{ #category : 'accessing' }
AbTopicListPresenter >> sortMode: aSymbol [

	sortMode := aSymbol
]

{ #category : 'private' }
AbTopicListPresenter >> sortOptions [

	^ {
		  'Title (A-Z)' -> #title.
		  'Last Updated (Newest)' -> #lastUpdated }
]

{ #category : 'private' }
AbTopicListPresenter >> sortedTopics: aCollection [

	self sortMode = #title ifTrue: [
		^ aCollection asSortedCollection: [ :a :b |
			  self titleSorts: a before: b ] ].
	^ aCollection asSortedCollection: [ :a :b |
		  | aTime bTime |
		  aTime := a lastUpdated.
		  bTime := b lastUpdated.
		  aTime ifNil: [
			  bTime ifNil: [ self titleSorts: a before: b ] ifNotNil: [ false ] ]
		  ifNotNil: [
			  bTime ifNil: [ true ] ifNotNil: [
				  aTime = bTime
					  ifTrue: [ self titleSorts: a before: b ]
					  ifFalse: [ aTime > bTime ] ] ] ]
]

{ #category : 'subscriptions' }
AbTopicListPresenter >> subscribeToTopicManager [

	AbTopicManager uniqueInstance topicsDo: [ :t |
		t announcer
			when: AbTopicStatusChanged
			do: [ self defer: [ self refresh ] ]
			for: self ].
	AbTopicManager uniqueInstance announcer
		when: AbTopicAdded
		do: [ :ann |
			ann topic announcer
				when: AbTopicStatusChanged
				do: [ self defer: [ self refresh ] ]
				for: self ]
		for: self
]

{ #category : 'private' }
AbTopicListPresenter >> titleSorts: aTopic before: anotherTopic [

	(aTopic title asLowercase = anotherTopic title asLowercase)
		ifTrue: [ ^ aTopic topicId < anotherTopic topicId ].
	^ aTopic title asLowercase < anotherTopic title asLowercase
]

{ #category : 'accessing' }
AbTopicListPresenter >> topicList [

	^ topicList
]

{ #category : 'private' }
AbTopicListPresenter >> topicListLabelFor: aTopic [

	| label |
	label := aTopic title.
	aTopic agentArguments ifNotEmpty: [ :args |
		label := label , ' (' , args first , ')' ].
	^ label
]

{ #category : 'subscriptions' }
AbTopicListPresenter >> unsubscribeFromTopicManager [

	AbTopicManager uniqueInstance topicsDo: [ :t |
		t announcer unsubscribe: self ].
	AbTopicManager uniqueInstance announcer unsubscribe: self
]
