"
I am the announcement fired when an AbTopicOrchestration finishes its run (whether successfully or with an error).

Responsibility:
- Carry a reference to the completed orchestration

Collaborators:
- AbTopicOrchestration: fires me in its #run ensure: block
- AbOrchestrationGroup: subscribes to me to coordinate parallel orchestration completion
"
Class {
	#name : 'AbOrchestrationEnded',
	#superclass : 'Announcement',
	#instVars : [
		'orchestration'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationEnded class >> orchestration: anOrchestration [
	^ self new
		orchestration: anOrchestration;
		yourself
]

{ #category : 'accessing' }
AbOrchestrationEnded >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbOrchestrationEnded >> orchestration: anOrchestration [
	orchestration := anOrchestration
]
