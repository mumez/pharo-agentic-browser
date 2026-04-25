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
				  name: 'Set Target Packages...';
				  action: [ self onSetTargetPackagesRequest ] ];
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
AbTopicListPresenter >> onNewTopicRequest [

	| dialog |
	dialog := AbNewTopicDialog new.
	dialog openModal.
	dialog topic ifNotNil: [ :topic |
		AbTopicManager uniqueInstance addTopic: topic.
		self defer: [ self refresh. topicList selectItem: topic ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onPackagePrefixSet: aTopic [

	| workDir matchingNames |
	workDir := aTopic workingDirectory.
	matchingNames := aTopic matchingPackageNames.
	matchingNames isEmpty
		ifTrue: [
			aTopic addSystemMessage:
				'No packages match "' , aTopic packagePrefix printString
				, '". Starting new project development.' ]
		ifFalse: [
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
	dialog := AbPackagePrefixDialog new.
	dialog openModal.
	dialog prefix ifNil: [ ^ self ].
	topic packagePrefix: dialog prefix.
	self onPackagePrefixSet: topic
]

{ #category : 'api' }
AbTopicListPresenter >> onTopicSelected: aBlock [

	onTopicSelectedBlock := aBlock
]

{ #category : 'api' }
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

	^ (self statusIconFor: aTopic) , ' ' , aTopic title
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
