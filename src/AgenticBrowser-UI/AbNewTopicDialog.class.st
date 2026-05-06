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

{ #category : 'layout' }
AbNewTopicDialog >> titleRowLayout [

	^ SpBoxLayout newLeftToRight
		  add: (self newLabel label: 'Title:') withConstraints: [ :c | c width: 80 ];
		  add: titleField;
		  yourself
]

{ #category : 'layout' }
AbNewTopicDialog >> agentRowLayout [

	^ SpBoxLayout newLeftToRight
		  add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 80 ];
		  add: agentDropList;
		  yourself
]

{ #category : 'layout' }
AbNewTopicDialog >> workingDirectoryRowLayout [

	^ SpBoxLayout newLeftToRight
		  add: (self newLabel label: 'Working dir:') withConstraints: [ :c | c width: 80 ];
		  add: workingDirField;
		  add: selectWorkingDirButton withConstraints: [ :c | c width: 90 ];
		  yourself
]

{ #category : 'layout' }
AbNewTopicDialog >> buttonsRowLayout [

	^ SpBoxLayout newLeftToRight
		  addLast: cancelButton withConstraints: [ :c | c width: 80 ];
		  addLast: okButton withConstraints: [ :c | c width: 80 ];
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
		initialExtent: 580 @ 200
]

{ #category : 'private' }
AbNewTopicDialog >> onSelectWorkingDirClicked [

	| selectedDir |
	selectedDir := UIManager default
		               chooseDirectory: 'Choose working directory'
		               path: FileLocator home asFileReference.
	selectedDir ifNil: [ ^ self ].
	workingDirField text: selectedDir fullName
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText dirPath detectedPrefixes |
	titleText := titleField text trimmed.
	titleText ifEmpty: [ ^ self ].
	self topic: (AbTopic new
				 title: titleText;
				 agentArguments: agentDropList selectedItem value;
				 yourself).
	dirPath := workingDirField text trimmed.
	dirPath ifNotEmpty: [
		self topic workingDirectoryPath: dirPath.
		detectedPrefixes := self detectPackagePrefixesFromDirectory: dirPath.
		self topic packagePrefixes: detectedPrefixes ].
	self withWindowDo: [ :w | w close ]
]

{ #category : 'accessing' }
AbNewTopicDialog >> topic [
	^ topic
]

{ #category : 'accessing' }
AbNewTopicDialog >> topic: anAbTopic [
	topic := anAbTopic
]
