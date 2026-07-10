"
I am announced on AbTopicManager classAnnouncer when a new default instance is loaded from persistence.
Subscribers use me to refresh their topicManager reference to the newly loaded instance.
"
Class {
	#name : 'AbTopicManagerLoaded',
	#superclass : 'Announcement',
	#instVars : [
		'topicManager'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicManagerLoaded class >> topicManager: aManager [

	^ self new
		  topicManager: aManager;
		  yourself
]

{ #category : 'accessing' }
AbTopicManagerLoaded >> topicManager [
	^ topicManager
]

{ #category : 'accessing' }
AbTopicManagerLoaded >> topicManager: aManager [
	topicManager := aManager
]
