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
AbMessagesPresenterTest >> testAddMultipleDistinctMessages [

	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Hi').
	presenter addOrUpdateMessage: (AbMessage sender: #ai text: 'Hello').
	self assert: presenter messageCount equals: 2
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testAddOrUpdateMessageAddsNewMessage [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	self assert: presenter messageCount equals: 1
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
AbMessagesPresenterTest >> testAddOrUpdateMessageStoresMessage [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	self assert: (presenter messages includes: msg)
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testDoesNotImplementWindowResizedHandler [

	self deny: (AbMessagesPresenter includesSelector: #windowResized:)
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testInitialMessageCountIsZero [

	self assert: presenter messageCount equals: 0
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testIsHideThinkEnabledByDefaultIsFalse [

	self deny: presenter isHideThinkEnabled
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testInitializeUsesMicTextPresenter [

	self assert: presenter messageTextPresenter class equals: MicTextPresenter
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testMessageListHasItemAfterAdd [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter addOrUpdateMessage: msg.
	self assert: (presenter combinedRichText asString includesSubstring: 'Hello')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testMessageListItemCountMatchesAfterMultipleAdds [

	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Hi').
	presenter addOrUpdateMessage: (AbMessage sender: #ai text: 'Hello').
	self assert: (presenter combinedRichText asString includesSubstring: 'Hi').
	self assert: (presenter combinedRichText asString includesSubstring: 'Hello')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testMessageListKeepsThinkMessagesWhenHidden [

	| thinkMessage |
	thinkMessage := AbMessage sender: #ai text: 'Hidden idea' isThink: true.
	presenter hideThinkEnabled: true.
	presenter addOrUpdateMessage: thinkMessage.
	self assert: presenter messageCount equals: 1.
	self assert: (presenter messages includes: thinkMessage)
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testMessageListUpdatedAfterSetMessages [

	| msgs |
	msgs := OrderedCollection
		with: (AbMessage sender: #human text: 'A')
		with: (AbMessage sender: #ai text: 'B').
	presenter setMessages: msgs.
	self assert: (presenter combinedRichText asString includesSubstring: 'A').
	self assert: (presenter combinedRichText asString includesSubstring: 'B')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testPerformScrollToBottomDoesNotError [

	presenter addOrUpdateMessage: (AbMessage sender: #human text: 'Hi').
	self shouldnt: [ presenter performScrollToBottom ] raise: Error
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRefreshCombinedTextHidesThinkMessagesWhenEnabled [

	presenter setMessages: {
			(AbMessage sender: #human text: 'Visible human').
			(AbMessage sender: #ai text: 'Hidden think' isThink: true).
			(AbMessage sender: #ai text: 'Visible ai') }.
	presenter hideThinkEnabled: true.
	self assert: (presenter combinedRichText asString includesSubstring: 'Visible human').
	self assert: (presenter combinedRichText asString includesSubstring: 'Visible ai').
	self deny: (presenter combinedRichText asString includesSubstring: 'Hidden think')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRefreshCombinedTextShowsThinkMessagesWhenDisabled [

	presenter setMessages: {
			(AbMessage sender: #human text: 'Visible human').
			(AbMessage sender: #ai text: 'Visible think' isThink: true) }.
	presenter hideThinkEnabled: false.
	self assert: (presenter combinedRichText asString includesSubstring: 'Visible think')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testRichTextForReturnsTextWithSenderAndBody [

	| msg rich |
	msg := AbMessage sender: #ai text: 'Hello world'.
	rich := presenter richTextFor: msg.
	self assert: rich class equals: Text.
	self assert: (rich asString includesSubstring: 'AI').
	self assert: (rich asString includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessagesPresenterTest >> testScrollToBottomDoesNotErrorWhenEmpty [

	self shouldnt: [ presenter scrollToBottom ] raise: Error
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
