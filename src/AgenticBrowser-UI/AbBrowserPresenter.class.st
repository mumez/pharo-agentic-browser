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
		  add: self topicListPresenter withConstraints: [ :c | c width: 220 ];
		  add: self chatPresenter;
		  yourself
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializePresenters [

	super initializePresenters.
	topicListPresenter := self instantiate: AbTopicListPresenter.
	chatPresenter := self instantiate: AbChatPresenter.
	AbTopicManager uniqueInstance subscribeAllTopicsToSisServer
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
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

{ #category : 'accessing' }
AbBrowserPresenter >> chatPresenter [

	^ chatPresenter
]

{ #category : 'accessing' }
AbBrowserPresenter >> topicListPresenter [

	^ topicListPresenter
]

{ #category : 'accessing' }
AbBrowserPresenter >> messagesPresenter [

	^ self chatPresenter messagesPresenter
]
