"
I am the top-level window that assembles the Agentic Browser UI.

Responsibility:
- I compose AbTopicListPresenter (left panel, 25%) and AbChatPresenter (right panel) in a horizontal paned layout.
- I wire topic selection from the list to the chat pane.
- I start all topic watchers when the window opens.
- I provide a Settings menu item that opens AbSettingsPresenter for the global configuration.
- On window close I release sub-presenters, stop all topic watchers, and persist both AbSettings and AbTopicManager to their fuel files.

Collaborators:
- AbTopicListPresenter: Left-panel component; I subscribe to its selection callback.
- AbChatPresenter: Right-panel component; I call #topic: on it when the selection changes.
- AbTopicManager: I call #startAllTopicsWatching on open and #cleanupAllTopics + #save on close.
- AbSettings: I trigger #save on window close.
- AbSettingsPresenter: I open it via #openOnDefault from the Settings menu.

Public API and Key Messages:
- AbBrowserPresenter class>>open - Create, open, and return the browser window.
"
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

	| presenter |
	presenter := self new.
	presenter open.
	^ presenter
]

{ #category : 'accessing' }
AbBrowserPresenter >> chatPresenter [

	^ chatPresenter
]

{ #category : 'initialization' }
AbBrowserPresenter >> connectPresenters [

	topicListPresenter onTopicSelected: [ :topic |
		chatPresenter topic: topic ]
]

{ #category : 'layout' }
AbBrowserPresenter >> defaultLayout [

	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 0.25;
		  add: self topicListPresenter;
		  add: self chatPresenter;
		  yourself
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializePresenters [

	super initializePresenters.
	topicListPresenter := self instantiate: AbTopicListPresenter.
	chatPresenter := self instantiate: AbChatPresenter.
	AbTopicManager uniqueInstance startAllTopicsWatching
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Agentic Browser';
		initialExtent: 900 @ 600;
		menu: self buildMenuBar.
	aWindowPresenter whenClosedDo: [ self onWindowClosed ]
]

{ #category : 'private' }
AbBrowserPresenter >> buildMenuBar [
	| menu |
	menu := self newMenuBar.
	menu addGroup: [ :group |
		group addItem: [ :item |
			item name: 'Settings…';
			    icon: AbUiConstants gear;
				action: [ self openSettings ] ] ].
	^ menu
]

{ #category : 'actions' }
AbBrowserPresenter >> openSettings [
	AbSettingsPresenter openOnDefault
]

{ #category : 'accessing' }
AbBrowserPresenter >> messagesPresenter [

	^ self chatPresenter messagesPresenter
]

{ #category : 'private' }
AbBrowserPresenter >> onWindowClosed [

	| manager |
	topicListPresenter release.
	chatPresenter release.
	manager := AbTopicManager uniqueInstance.
	manager cleanupAllTopics.
	AbSettings save.
	AbTopicManager save
]

{ #category : 'accessing' }
AbBrowserPresenter >> topicListPresenter [

	^ topicListPresenter
]
