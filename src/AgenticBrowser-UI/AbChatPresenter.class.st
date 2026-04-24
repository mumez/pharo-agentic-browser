Class {
	#name : 'AbChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageDisplay',
		'inputField',
		'sendButton',
		'currentTopic',
		'pendingApprovalMessage',
		'workDirLabel',
		'exportButton',
		'importButton',
		'runTestsButton'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbChatPresenter >> connectPresenters [

	sendButton action: [ self onSendButtonClicked ].
	exportButton action: [ self onExportClicked ].
	importButton action: [ self onImportClicked ].
	runTestsButton action: [ self onRunTestsClicked ]
]

{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: (SpBoxLayout newLeftToRight
				   add: workDirLabel;
				   add: exportButton withConstraints: [ :c | c width: 80 ];
				   add: importButton withConstraints: [ :c | c width: 80 ];
				   add: runTestsButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: messageDisplay;
		  add: (SpBoxLayout newLeftToRight
				   add: inputField;
				   add: sendButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 60 ];
		  yourself
]

{ #category : 'api' }
AbChatPresenter >> enterApprovalMode: anAbMessage [

	pendingApprovalMessage := anAbMessage.
	inputField placeholder: 'Respond to AI (yes / no / always)...'.
	inputField text: ''
]

{ #category : 'api' }
AbChatPresenter >> exitApprovalMode [

	pendingApprovalMessage := nil.
	inputField placeholder: 'Type your request...'
]

{ #category : 'initialization' }
AbChatPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable.

	inputField := self newText.
	inputField placeholder: 'Type your request...'.

	sendButton := self newButton.
	sendButton label: 'Send'.

	workDirLabel := self newLabel.
	workDirLabel label: ''.

	exportButton := self newButton label: '↑ Export'.
	importButton := self newButton label: '↓ Import'.
	runTestsButton := self newButton label: '▶ Tests'
]

{ #category : 'private' }
AbChatPresenter >> onExportClicked [

	| topic |
	topic := currentTopic.
	topic ifNil: [ ^ self ].
	[ [ topic exportWatchedPackages.
	    topic addSystemMessage: 'Exported packages to ' , topic workingDirectory path fullName ]
		  on: Error
		  do: [ :e | topic addSystemMessage: 'Export failed: ' , e messageText ] ] fork
]

{ #category : 'private' }
AbChatPresenter >> onImportClicked [

	| topic |
	topic := currentTopic.
	topic ifNil: [ ^ self ].
	[ [ topic importWatchedPackages.
	    topic addSystemMessage: 'Imported packages from ' , topic workingDirectory path fullName ]
		  on: Error
		  do: [ :e | topic addSystemMessage: 'Import failed: ' , e messageText ] ] fork
]

{ #category : 'private' }
AbChatPresenter >> onRunTestsClicked [

	| topic |
	topic := currentTopic.
	topic ifNil: [ ^ self ].
	topic watchedPackages isEmpty ifTrue: [ ^ self ].
	[ [ | results |
	    results := topic workingDirectory runAllTests.
	    topic addSystemMessage: 'Test results:' , String cr , results ]
		  on: Error
		  do: [ :e | topic addSystemMessage: 'Tests failed: ' , e messageText ] ] fork
]

{ #category : 'private' }
AbChatPresenter >> onMessageAdded: anAbMessage [

	self rerenderMessages.
	anAbMessage isApprovalRequest ifTrue: [
		self enterApprovalMode: anAbMessage ]
]

{ #category : 'private' }
AbChatPresenter >> onSendButtonClicked [

	| text |
	text := inputField text trimmed.
	text isEmpty ifTrue: [ ^ self ].
	inputField text: ''.
	currentTopic ifNil: [ ^ self ].
	pendingApprovalMessage
		ifNotNil: [ currentTopic resolveApproval: text ]
		ifNil: [ currentTopic sendPrompt: text ]
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
		do: [ :ann |
			self defer: [
				self onMessageAdded: ann message.
				self updateWorkDirLabel ] ]
		for: self.
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann | self defer: [ self onTopicStatusChanged: ann topic ] ]
		for: self
]

{ #category : 'api' }
AbChatPresenter >> topic: anAbTopic [

	currentTopic := anAbTopic.
	self unsubscribeCurrentTopic.
	self subscribeToTopic: anAbTopic.
	self updateWorkDirLabel.
	self rerenderMessages
]

{ #category : 'private' }
AbChatPresenter >> unsubscribeCurrentTopic [

	currentTopic ifNotNil: [ :t | t announcer unsubscribe: self ]
]

{ #category : 'private' }
AbChatPresenter >> updateWorkDirLabel [

	currentTopic ifNil: [
		workDirLabel label: ''.
		^ self ].
	currentTopic watchedPackages isEmpty
		ifTrue: [ workDirLabel label: '(no packages watched)' ]
		ifFalse: [ workDirLabel label: currentTopic workingDirectory path fullName ]
]
