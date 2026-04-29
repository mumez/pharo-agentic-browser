Class {
	#name : 'AbBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'topicListPresenter',
		'chatPresenter'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AbBrowserPresenter class >> open [

	^ self new open
]

{ #category : 'initialization' }
AbBrowserPresenter >> connectPresenters [

	topicListPresenter onTopicSelected: [ :topic |
		chatPresenter topic: topic ]
]

{ #category : 'layout' }
AbBrowserPresenter >> defaultLayout [

	^ SpBoxLayout newLeftToRight
		  add: topicListPresenter withConstraints: [ :c | c width: 220 ];
		  add: chatPresenter;
		  yourself
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializePresenters [

	topicListPresenter := self instantiate: AbTopicListPresenter.
	chatPresenter := self instantiate: AbChatPresenter.
	AbTopicManager uniqueInstance subscribeAllTopicsToSisServer
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Agentic Browser';
		initialExtent: 900 @ 600.
	aWindowPresenter whenClosedDo: [ self onWindowClosed ]
]

{ #category : 'private' }
AbBrowserPresenter >> onWindowClosed [

	| manager |
	manager := AbTopicManager uniqueInstance.
	manager cleanupAllTopics
]
