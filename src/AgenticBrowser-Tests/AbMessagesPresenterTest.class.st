Class {
	#name : 'AbMessagesPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbMessagesPresenterTest >> setUp [

	presenter := AbMessagesPresenter new.
	presenter initializePresenters
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testInitialMessageCountIsZero [

	self assert: presenter messageCount equals: 0
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddOrUpdateMessageAddsNewMessage [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	self assert: presenter messageCount equals: 1
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddOrUpdateMessageStoresMessage [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	self assert: (presenter messages includes: msg)
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddOrUpdateMessageDoesNotDuplicateExistingMessage [
	"When the same AbMessage object is updated (e.g. AI chunk appended),
	 it should not be added as a new entry."

	| msg |
	msg := AbMessage sender: #ai text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	msg appendText: ' world'.
	presenter addOrUpdateMessage: msg.
	self assert: presenter messageCount equals: 1
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddMultipleDistinctMessages [

	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Hi').
	presenter addOrUpdateMessage: (AbMessage sender: #ai text: 'Hello').
	self assert: presenter messageCount equals: 2
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testSetMessagesReplacesAll [

	| newMsgs |
	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Old').
	newMsgs := OrderedCollection
		with: (AbMessage sender: #human text: 'New1')
		with: (AbMessage sender: #ai text: 'New2').
	presenter setMessages: newMsgs.
	self assert: presenter messageCount equals: 2.
	self assert: (presenter messages first text) equals: 'New1'
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testSetMessagesWithEmptyCollectionClearsAll [

	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Hi').
	presenter setMessages: #().
	self assert: presenter messageCount equals: 0
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRichTextForHumanMessageContainsSenderLabel [

	| msg richText |
	msg := AbMessage sender: #human text: 'Hello'.
	richText := presenter richTextFor: msg.
	self assert: (richText string includesSubstring: 'You')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRichTextForAiMessageContainsSenderLabel [

	| msg richText |
	msg := AbMessage sender: #ai text: 'Hi'.
	richText := presenter richTextFor: msg.
	self assert: (richText string includesSubstring: 'AI')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRichTextContainsMessageText [

	| msg richText |
	msg := AbMessage sender: #human text: 'Hello world'.
	richText := presenter richTextFor: msg.
	self assert: (richText string includesSubstring: 'Hello world')
]
