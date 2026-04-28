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
		  addItem: [ :item |
			  item
				  name: 'Inspect...';
				  action: [ self onInspectTopicRequest ] ];
		  addItem: [ :item |
			  item
				  name: 'Set Target Packages...';
				  action: [ self onSetTargetPackagesRequest ] ];
		  addItem: [ :item |
			  item
				  name: 'Rename...';
				  action: [ self onRenameTopicRequest ] ];
		  addItem: [ :item |
			  item
				  name: 'Delete';
				  action: [ self onDeleteTopicRequest ] ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> connectPresenters [

	topicList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :topic |
			onTopicSelectedBlock ifNotNil: [ onTopicSelectedBlock value: topic ] ] ].
	topicList contextMenu: [ self buildTopicContextMenu ].
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
			(workDir path exists and: [ workDir path hasChildren ])
				ifTrue: [
					(UIManager default
						 confirm:
						 'Existing topic directory found at ' , workDir path fullName
						 , '. Import packages into image?')
						ifTrue: [
							[ aTopic importWatchedPackages.
							  aTopic addSystemMessage:
								  'Imported packages from ' , workDir path fullName ] fork ] ]
				ifFalse: [
					[ aTopic exportWatchedPackages.
					  aTopic addSystemMessage:
						  'Exported ' , matchingNames size printString , ' package(s) to '
						  , workDir path fullName ] fork ] ]
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
AbTopicListPresenter >> statusIconFor: aTopic [

	aTopic status = #working ifTrue: [ ^ '●' ].
	aTopic status = #waitingForHuman ifTrue: [ ^ '⏸' ].
	aTopic status = #done ifTrue: [ ^ '✓' ].
	^ '○'
]

{ #category : 'private' }
AbTopicListPresenter >> topicListLabelFor: aTopic [

	| label |
	label := (self statusIconFor: aTopic) , ' ' , aTopic title.
	aTopic agentArguments ifNotEmpty: [ :args |
		label := label , ' (' , args first , ')' ].
	^ label
]

{ #category : 'private' }
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
