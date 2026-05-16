Class {
	#name : 'AgenticBrowser',
	#superclass : 'Object',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AgenticBrowser class >> open [

	AbSettings load.
	AbTopicManager load.
	^ AbBrowserPresenter open
]
