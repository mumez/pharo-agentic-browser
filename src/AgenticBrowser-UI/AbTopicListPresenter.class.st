Class {
	#name : 'AbTopicListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'topicList',
		'newTopicButton',
		'onTopicSelectedBlock'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbTopicListPresenter >> buildTopicContextMenu [

	^ SpMenuPresenter new
		  addItem: [ :item | item name: 'Inspect...'; action: [ self onInspectTopicRequest ] ];
		  addItem: [ :item | item name: 'Set Target Packages...'; action: [ self onSetTargetPackagesRequest ] ];
		  addItem: [ :item | item name: 'Apply Updated External Packages'; action: [ self onApplyUpdatedExternalPackagesRequest ] ];
		  addItem: [ :item | item name: 'Set Working Directory...'; action: [ self onSetWorkingDirectoryRequest ] ];
		  addItem: [ :item | item name: 'Set Agent...'; action: [ self onSetAgentRequest ] ];
		  addItem: [ :item | item name: 'Rename...'; action: [ self onRenameTopicRequest ] ];
		  addItem: [ :item | item name: 'Delete'; action: [ self onDeleteTopicRequest ] ];
		  yourself
]

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

{ #category : 'initialization' }
AbTopicListPresenter >> connectPresenters [

	topicList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :topic |
			onTopicSelectedBlock ifNotNil: [ onTopicSelectedBlock value: topic ] ] ].
	topicList contextMenu: [ topicList selectedItem ifNotNil: [ self buildTopicContextMenu ] ].
	newTopicButton action: [ self onNewTopicRequest ].
	self subscribeToTopicManager.
	self refresh
]

{ #category : 'layout' }
AbTopicListPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: topicList;
		  add: newTopicButton
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> initializePresenters [

	topicList := self newList.
	topicList display: [ :topic | self topicListLabelFor: topic ].
	topicList displayIcon: [ :item |
		Smalltalk ui icons iconNamed: (self iconFor: item) ].
	newTopicButton := self newButton.
	newTopicButton label: '+ New Topic'
]

{ #category : 'private' }
AbTopicListPresenter >> onDeleteTopicRequest [

	| selectedTopic |
	selectedTopic := topicList selectedItem.
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
	selectedTopic := topicList selectedItem.
	selectedTopic ifNil: [ ^ self ].
	selectedTopic inspect
]

{ #category : 'private' }
AbTopicListPresenter >> onApplyUpdatedExternalPackagesRequest [

	| topic |
	topic := topicList selectedItem.
	topic ifNil: [ ^ self ].
	self applyUpdatedExternalPackagesFor: topic
]

{ #category : 'private' }
AbTopicListPresenter >> onNewTopicRequest [

	| dialog |
	dialog := AbNewTopicDialog new.
	dialog openModal.
	dialog topic ifNotNil: [ :topic |
		AbTopicManager uniqueInstance addTopic: topic.
		self defer: [ self refresh. topicList selectItem: topic ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onRenameTopicRequest [

	| selectedTopic newTitle |
	selectedTopic := topicList selectedItem.
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
AbTopicListPresenter >> onSetTargetPackagesRequest [

	| topic dialog |
	topic := topicList selectedItem.
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
AbTopicListPresenter >> onSetAgentRequest [

	| topic dialog |
	topic := topicList selectedItem.
	topic ifNil: [ ^ self ].
	dialog := AbSetAgentDialog new.
	dialog selectCurrentArguments: topic agentArguments.
	dialog openModal.
	dialog selectedArguments ifNil: [ ^ self ].
	topic sessionId ifNotNil: [
		(UIManager default
			 confirm: 'The active agent session will be disconnected. Continue?'
			 label: 'Change Agent') ifFalse: [ ^ self ].
		topic disconnect ].
	topic agentArguments: dialog selectedArguments.
	self defer: [ self refresh ]
]

{ #category : 'private' }
AbTopicListPresenter >> onSetWorkingDirectoryRequest [

	| topic directoryPath |
	topic := topicList selectedItem.
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
	topicList items: items
]

{ #category : 'private' }
AbTopicListPresenter >> topicListLabelFor: aTopic [

	| label |
	label := aTopic title.
	aTopic agentArguments ifNotEmpty: [ :args |
		label := label , ' (' , args first , ')' ].
	^ label
]

{ #category : 'private' }
AbTopicListPresenter >> iconFor: aTopic [

	aTopic status = #initial ifTrue: [ ^ #radioButtonOff ].
	aTopic status = #working ifTrue: [ ^ #pointersTo ].
	aTopic status = #waitingForHuman ifTrue: [ ^ #flag ].
	aTopic status = #endTurn ifTrue: [ ^ #accept ].
	^ #radioButtonOff
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

{ #category : 'subscriptions' }
AbTopicListPresenter >> unsubscribeFromTopicManager [

	AbTopicManager uniqueInstance topicsDo: [ :t |
		t announcer unsubscribe: self ].
	AbTopicManager uniqueInstance announcer unsubscribe: self
]

{ #category : 'initialization' }
AbTopicListPresenter >> destroy [

	self unsubscribeFromTopicManager.
	super destroy
]
