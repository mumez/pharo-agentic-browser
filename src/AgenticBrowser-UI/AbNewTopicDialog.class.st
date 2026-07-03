"
I am a modal dialog for creating a new AbTopic.

Responsibility:
- I collect a topic title, an agent selection, and an optional working directory path from the user.
- When a working directory is provided I scan its src/ subdirectory to auto-detect package prefix patterns (e.g. 'Foo-*') and pre-populate the new topic's packagePrefixes.
- On OK I build and expose an AbTopic instance; the caller (AbTopicListPresenter) registers it with AbTopicManager.

Collaborators:
- AbTopic: I create and configure a new instance on confirmation.
- AbTopicListPresenter: It opens me modally and reads the resulting #topic.
- AbDialog: My superclass providing the modal window infrastructure.

Public API and Key Messages:
- #topic - The newly created AbTopic after the dialog closes; nil if the user cancelled.

Internal Representation:
- topic - Holds the created AbTopic instance; nil until the OK button is clicked with valid input.
- agentDropList - Drop-list populated from AgentOptions; the selected item supplies the agent argument array.
"
Class {
	#name : 'AbNewTopicDialog',
	#superclass : 'AbDialog',
	#instVars : [
		'titleField',
		'agentDropList',
		'workingDirField',
		'selectWorkingDirButton',
		'okButton',
		'cancelButton',
		'topic'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbNewTopicDialog >> addDetectedPrefixForDirectoryName: name into: prefixes [

	| hyphenPos base |
	(name beginsWith: 'BaselineOf') ifTrue: [
		prefixes add: name.
		^ self ].
	hyphenPos := name indexOf: $-.
	hyphenPos > 1 ifFalse: [ ^ self ].
	base := name copyFrom: 1 to: hyphenPos - 1.
	prefixes add: base , '-*'
]

{ #category : 'accessing' }
AbNewTopicDialog >> agentDropList [

	^ agentDropList
]

{ #category : 'layout' }
AbNewTopicDialog >> agentRowLayout [

	^ SpBoxLayout newLeftToRight
		  add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 80 ];
		  add: self agentDropList;
		  yourself
]

{ #category : 'layout' }
AbNewTopicDialog >> buttonsRowLayout [

	^ SpBoxLayout newLeftToRight
		  addLast: self cancelButton withConstraints: [ :c | c width: 80 ];
		  addLast: self okButton withConstraints: [ :c | c width: 80 ];
		  yourself
]

{ #category : 'accessing' }
AbNewTopicDialog >> cancelButton [

	^ cancelButton
]

{ #category : 'initialization' }
AbNewTopicDialog >> connectPresenters [

	okButton action: [ self onOkClicked ].
	selectWorkingDirButton action: [ self onSelectWorkingDirClicked ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbNewTopicDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: self titleRowLayout withConstraints: [ :c | c height: 32 ];
		  add: self agentRowLayout withConstraints: [ :c | c height: 32 ];
		  add: self workingDirectoryRowLayout withConstraints: [ :c | c height: 32 ];
		  add: self buttonsRowLayout withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'operations' }
AbNewTopicDialog >> detectPackagePrefixesFromDirectory: aPathString [

	| dir srcDir prefixes |
	dir := aPathString asFileReference.
	dir exists ifFalse: [ ^ #() ].
	prefixes := Set new.
	srcDir := dir / 'src'.
	srcDir exists ifFalse: [ ^ #() ].
	srcDir directories do: [ :sub |
		self addDetectedPrefixForDirectoryName: sub basename into: prefixes ].
	^ prefixes asArray
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializePresenters [

	super initializePresenters.
	titleField := self newTextInput.
	titleField placeholder: 'Topic title...'.

	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].

	workingDirField := self newTextInput.
	workingDirField placeholder: '(optional) Path to existing project directory...'.
	selectWorkingDirButton := self newButton.
	selectWorkingDirButton label: 'Select...'.

	okButton := self newButton label: 'Create'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'New Topic';
		initialExtent: 580 @ 200;
		withoutButtons
]

{ #category : 'accessing' }
AbNewTopicDialog >> okButton [

	^ okButton
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText dirPath detectedPrefixes |
	titleText := self titleField text trimmed.
	titleText ifEmpty: [ ^ self ].
	self topic: (AbTopic new
				 title: titleText;
				 agentArguments: self agentDropList selectedItem value;
				 yourself).
	dirPath := self workingDirField text trimmed.
	dirPath ifNotEmpty: [
		self topic workingDirectoryPath: dirPath.
		detectedPrefixes := self detectPackagePrefixesFromDirectory: dirPath.
		self topic packagePrefixes: detectedPrefixes ].
	self withWindowDo: [ :w | w close ]
]

{ #category : 'private' }
AbNewTopicDialog >> onSelectWorkingDirClicked [

	| selectedDir |
	selectedDir := UIManager default
		               chooseDirectory: 'Choose working directory'
		               path: FileLocator home asFileReference.
	selectedDir ifNil: [ ^ self ].
	self workingDirField text: selectedDir fullName
]

{ #category : 'accessing' }
AbNewTopicDialog >> selectWorkingDirButton [

	^ selectWorkingDirButton
]

{ #category : 'accessing' }
AbNewTopicDialog >> titleField [

	^ titleField
]

{ #category : 'layout' }
AbNewTopicDialog >> titleRowLayout [

	^ SpBoxLayout newLeftToRight
		  add: (self newLabel label: 'Title:') withConstraints: [ :c | c width: 80 ];
		  add: self titleField;
		  yourself
]

{ #category : 'accessing' }
AbNewTopicDialog >> topic [
	^ topic
]

{ #category : 'accessing' }
AbNewTopicDialog >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbNewTopicDialog >> workingDirField [

	^ workingDirField
]

{ #category : 'layout' }
AbNewTopicDialog >> workingDirectoryRowLayout [

	^ SpBoxLayout newLeftToRight
		  add: (self newLabel label: 'Working dir:') withConstraints: [ :c | c width: 80 ];
		  add: self workingDirField;
		  add: self selectWorkingDirButton withConstraints: [ :c | c width: 90 ];
		  yourself
]
