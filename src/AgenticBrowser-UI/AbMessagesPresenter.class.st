Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageDisplay'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable
]

{ #category : 'layout' }
AbMessagesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messageDisplay;
		  yourself
]

{ #category : 'rendering' }
AbMessagesPresenter >> renderMessages: aCollection [

	messageDisplay text: (String streamContents: [ :s |
			 aCollection do: [ :m |
				 s
					 nextPutAll: m displayText;
					 cr ] ])
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageDisplay [

	^ messageDisplay
]
