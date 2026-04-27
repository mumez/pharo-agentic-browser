Class {
	#name : 'AbNewTopicDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleField',
		'agentDropList',
		'workingDirField',
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
				   add: (self newLabel label: 'Title:') withConstraints: [ :c | c width: 80 ];
				   add: titleField;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 80 ];
				   add: agentDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Working dir:') withConstraints: [ :c | c width: 80 ];
				   add: workingDirField;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
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
		| name |
		name := sub basename.
		(name beginsWith: 'BaselineOf')
			ifTrue: [ prefixes add: name ]
			ifFalse: [
				| hyphenPos base |
				hyphenPos := name indexOf: $-.
				hyphenPos > 1 ifTrue: [
					base := name copyFrom: 1 to: hyphenPos - 1.
					prefixes add: base , '-*' ] ] ].
	^ prefixes asArray
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializePresenters [

	titleField := self newTextInput.
	titleField placeholder: 'Topic title...'.

	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].

	workingDirField := self newTextInput.
	workingDirField placeholder: '(optional) Path to existing project directory...'.

	okButton := self newButton label: 'Create'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'New Topic';
		initialExtent: 480 @ 200
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText dirPath detectedPrefixes |
	titleText := titleField text trimmed.
	titleText isEmpty ifTrue: [ ^ self ].
	topic := AbTopic new
				 title: titleText;
				 agentArguments: agentDropList selectedItem value;
				 yourself.
	dirPath := workingDirField text trimmed.
	dirPath ifNotEmpty: [
		topic workingDirectoryPath: dirPath.
		detectedPrefixes := self detectPackagePrefixesFromDirectory: dirPath.
		topic packagePrefixes: detectedPrefixes ].
	self withWindowDo: [ :w | w close ]
]

{ #category : 'accessing' }
AbNewTopicDialog >> topic [
	^ topic
]
