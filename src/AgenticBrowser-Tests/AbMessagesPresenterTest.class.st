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
AbMessagesPresenterTest >> testAddOrUpdateMessageAddsNewPresenter [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	self assert: presenter messageCount equals: 1
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddOrUpdateMessageSetsContent [

	| msg mp |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	mp := presenter messagePresenters first.
	self assert: mp contentTextString equals: 'Hello'
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddOrUpdateMessageUpdatesExistingPresenter [
	"When the same AbMessage object is announced again (AI chunk), update content not add new presenter."

	| msg |
	msg := AbMessage sender: #ai text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	msg appendText: ' world'.
	presenter addOrUpdateMessage: msg.
	self assert: presenter messageCount equals: 1.
	self assert: presenter messagePresenters first contentTextString equals: 'Hello world'
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddMultipleDistinctMessages [

	| msg1 msg2 |
	msg1 := AbMessage sender: #human text: 'Hi'.
	msg2 := AbMessage sender: #ai text: 'Hello'.
	presenter addOrUpdateMessage: msg1.
	presenter addOrUpdateMessage: msg2.
	self assert: presenter messageCount equals: 2
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testSetMessagesReplacesAll [

	| msgs |
	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Old').
	msgs := OrderedCollection with: (AbMessage sender: #human text: 'New1')
		with: (AbMessage sender: #ai text: 'New2').
	presenter setMessages: msgs.
	self assert: presenter messageCount equals: 2.
	self assert: presenter messagePresenters first contentTextString equals: 'New1'
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testSetMessagesWithEmptyCollectionClearsAll [

	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Hi').
	presenter setMessages: #().
	self assert: presenter messageCount equals: 0
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRefreshMessagesUpdatesContent [

	| msg mp |
	msg := AbMessage sender: #ai text: 'First'.
	presenter addOrUpdateMessage: msg.
	mp := presenter messagePresenters first.
	msg appendText: ' update'.
	presenter refreshMessages.
	self assert: mp contentTextString equals: 'First update'
]
