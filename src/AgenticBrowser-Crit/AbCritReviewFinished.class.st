"
I am announced on a topic's announcer when a crit review Finish has been delivered to the topic.

Responsibility:
- I tell subscribers which topic's review finished, how it finished, and how many comments remain unresolved.

Collaborators:
- AbCritReviewFinishResultsManager: It announces me after delivering an approval or sending an unresolved prompt, and when it discards a later round's result, which crit returns to the agent itself.
- AbTopicManagerRipple: It pushes me to WebUI clients as a critReviewFinished event.

Public API and Key Messages:
- AbCritReviewFinished class>>topic:kind:unresolvedCount: - Instance for one delivered Finish.
- #topic / #kind / #unresolvedCount - The topic, #approved or #unresolved, and the unresolved comment count (0 when approved).

Internal Representation:
- topic - The AbTopic the result was delivered to.
- kind - #approved or #unresolved.
- unresolvedCount - Integer count of unresolved comments.
"
Class {
	#name : 'AbCritReviewFinished',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'kind',
		'unresolvedCount'
	],
	#category : 'AgenticBrowser-Crit',
	#package : 'AgenticBrowser-Crit'
}

{ #category : 'instance creation' }
AbCritReviewFinished class >> topic: anAbTopic kind: aKindSymbol unresolvedCount: anInteger [

	^ self new
		  topic: anAbTopic;
		  kind: aKindSymbol;
		  unresolvedCount: anInteger;
		  yourself
]

{ #category : 'accessing' }
AbCritReviewFinished >> kind [

	^ kind
]

{ #category : 'accessing' }
AbCritReviewFinished >> kind: aKindSymbol [

	kind := aKindSymbol
]

{ #category : 'accessing' }
AbCritReviewFinished >> topic [

	^ topic
]

{ #category : 'accessing' }
AbCritReviewFinished >> topic: anAbTopic [

	topic := anAbTopic
]

{ #category : 'accessing' }
AbCritReviewFinished >> unresolvedCount [

	^ unresolvedCount
]

{ #category : 'accessing' }
AbCritReviewFinished >> unresolvedCount: anInteger [

	unresolvedCount := anInteger
]
