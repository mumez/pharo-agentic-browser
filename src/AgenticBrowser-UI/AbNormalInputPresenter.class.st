"
I provide the standard text-input row used when no approval is pending.

Responsibility:
- I render a multi-line text field flanked by Send and Cancel buttons.
- I support drag-and-drop of compiled methods and classes from the system browser; dropped objects are converted to '@ClassName>>selector' or '@ClassName' mention strings and appended to the input field.
- I expose #insertMention: so AbChatPresenter can programmatically append screenshot mention strings after capture.
- Cancel is disabled by default; AbChatPresenter enables it while a topic is in the #working state.

Collaborators:
- AbChatPresenter: It wires #onSendAction:, #onCancelAction:, and #cancelEnabled:, and calls #insertMention: for screenshot mentions.
- AbNormalInputPresenter has no domain dependencies; it is purely a UI component.

Public API and Key Messages:
- #onSendAction: / #onCancelAction: - Register button callbacks.
- #cancelEnabled: - Enable or disable the Cancel button.
- #inputText / #clearInput - Read and clear the current text.
- #insertMention: - Append a mention string to the input field content.
"
Class {
	#name : 'AbNormalInputPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'inputField',
		'sendButton',
		'cancelButton'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'accessing' }
AbNormalInputPresenter >> cancelButton [

	^ cancelButton
]

{ #category : 'testing' }
AbNormalInputPresenter >> cancelButtonLabel [

	^ self cancelButton label
]

{ #category : 'actions' }
AbNormalInputPresenter >> cancelEnabled: aBoolean [

	self cancelButton enabled: aBoolean
]

{ #category : 'accessing' }
AbNormalInputPresenter >> clearInput [

	self inputField text: ''
]

{ #category : 'layout' }
AbNormalInputPresenter >> defaultLayout [

	^ SpBoxLayout newLeftToRight
		  add: self inputField;
		  add: self sendButton withConstraints: [ :c | c width: 80 ];
		  add: self cancelButton withConstraints: [ :c | c width: 60 ];
		  yourself
]

{ #category : 'initialization' }
AbNormalInputPresenter >> enableMentionDrop [

	inputField
		dropEnabled: true;
		wantsDrop: [ :transfer |
			(self firstActualObjectFrom: transfer) ifNil: [ false ] ifNotNil: [ :obj |
				obj isCompiledMethod or: [ obj isBehavior ] ] ];
		acceptDrop: [ :transfer |
			(self firstActualObjectFrom: transfer) ifNotNil: [ :obj |
				self insertMention: (self mentionStringFor: obj) ] ]
]

{ #category : 'private' }
AbNormalInputPresenter >> firstActualObjectFrom: transfer [

	| items |
	items := transfer passenger dragContext selectedItems.
	^ items ifEmpty: [ nil ] ifNotEmpty: [ :nonEmpty | nonEmpty first actualObject ]
]

{ #category : 'initialization' }
AbNormalInputPresenter >> initializePresenters [

	super initializePresenters.
	inputField := self newText.
	inputField placeholder: 'Type your request...'.
	self enableMentionDrop.

	sendButton := self newButton.
	sendButton label: 'Send'.

	cancelButton := self newButton.
	cancelButton label: 'Cancel'
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputField [

	^ inputField
]

{ #category : 'testing' }
AbNormalInputPresenter >> inputPlaceholder [

	^ self inputField placeholder
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputText [

	^ self inputField text
]

{ #category : 'testing' }
AbNormalInputPresenter >> isCancelEnabled [

	^ self cancelButton isEnabled
]

{ #category : 'actions' }
AbNormalInputPresenter >> insertMention: aString [

	| currentText |
	currentText := self inputField text.
	self inputField text: (currentText
		ifEmpty: [ aString , ' ' ]
		ifNotEmpty: [ currentText , ' ' , aString , ' ' ])
]

{ #category : 'private' }
AbNormalInputPresenter >> mentionStringFor: anObject [

	anObject ifNil: [ ^ '' ].
	anObject isCompiledMethod ifTrue: [
		^ '@' , anObject methodClass name , '>>' , anObject selector ].
	anObject isBehavior ifTrue: [ ^ '@' , anObject name ].
	^ ''
]

{ #category : 'actions' }
AbNormalInputPresenter >> onCancelAction: aBlock [

	self cancelButton action: aBlock
]

{ #category : 'actions' }
AbNormalInputPresenter >> onSendAction: aBlock [

	self sendButton action: aBlock
]

{ #category : 'accessing' }
AbNormalInputPresenter >> sendButton [

	^ sendButton
]

{ #category : 'testing' }
AbNormalInputPresenter >> sendButtonLabel [

	^ self sendButton label
]
