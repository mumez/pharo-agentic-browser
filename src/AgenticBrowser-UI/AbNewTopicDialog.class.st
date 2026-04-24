Class {
	#name : 'AbNewTopicDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleField',
		'agentDropList',
		'packageList',
		'okButton',
		'cancelButton',
		'topic'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbNewTopicDialog >> agentOptions [

	^ OrderedCollection new
		  add: 'claude-agent-acp' -> #( 'claude-agent-acp' );
		  add: 'Gemini CLI' -> #( 'gemini' '--acp' );
		  add: 'OpenCode' -> #( 'opencode' 'acp' );
		  add: 'Copilot CLI' -> #( 'copilot' '--acp' '--stdio' );
		  add: 'codex-acp' -> #( 'codex-acp' );
		  yourself
]

{ #category : 'initialization' }
AbNewTopicDialog >> connectPresenters [

	okButton action: [ self onOkClicked ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbNewTopicDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Title:') withConstraints: [ :c | c width: 60 ];
				   add: titleField;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 60 ];
				   add: agentDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (self newLabel label: 'Packages to watch (optional, multi-select):')
		  withConstraints: [ :c | c height: 24 ];
		  add: packageList;
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializePresenters [

	titleField := self newTextInput.
	titleField placeholder: 'Topic title...'.

	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].

	packageList := self newList.
	packageList beMultipleSelection.
	packageList items: self installedPackageNames.
	packageList display: [ :name | name ].

	okButton := self newButton label: 'Create'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'New Topic';
		initialExtent: 420 @ 420
]

{ #category : 'private' }
AbNewTopicDialog >> installedPackageNames [

	^ (PackageOrganizer default packages
		   collect: [ :p | p name ]
		   thenSelect: [ :name | name notEmpty ])
		  asSortedCollection asArray
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText |
	titleText := titleField text trimmed.
	titleText isEmpty ifTrue: [ ^ self ].
	topic := AbTopic new
		         title: titleText;
		         agentArguments: agentDropList selectedItem value;
		         yourself.
	packageList selectedItems do: [ :name | topic addWatchedPackage: name ].
	self withWindowDo: [ :w | w close ]
]

{ #category : 'api' }
AbNewTopicDialog >> topic [
	^ topic
]
