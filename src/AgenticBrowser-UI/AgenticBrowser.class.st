Class {
	#name : 'AgenticBrowser',
	#superclass : 'Object',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AgenticBrowser class >> open [

	AbTopicManager load.
	^ AbBrowserPresenter open
]
