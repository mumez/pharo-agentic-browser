"
I represent a completion goal attached to an AbTopic.

Responsibility:
- I hold the goal description text and build the notification prompt sent to the agent.
- I detect goal achievement by checking for the existence of a result file in the topic's working directory.
- I store the result text (read from the file) once the goal is achieved.
- I fire an optional callback block when the goal is achieved.
- I build the resume prompt sent to a stalled topic to nudge it back toward goal completion.

Collaborators:
- AbTopic: I am owned by a topic; I read its workingDirectory path and settings for the notification prompt.
- AbTopicGoalAchieved: AbTopic announces it carrying self when I report achievement.

Public API and Key Messages:
- #description: - Set the goal text (triggers agent notification via AbTopic>>goalDescription:).
- #notificationPrompt - The full prompt string sent to the agent; includes the result filename and optional command prefix.
- #checkAchievement - Return true and capture result text if the result file exists; deletes the file on success.
- #isAchieved - True once result is non-nil.
- #whenAchieved: - Register a callback block (receives self as argument) fired on achievement.
- #resumePrompt - The prompt text sent to a stalled topic to resume progress toward the goal.

Internal Representation:
- description - The human-readable goal condition string.
- result - The file contents read from result-<topicId>.md; nil until achieved.
- whenAchieved - Optional zero-or-one-argument block called on achievement.
- resumePrompt - Optional override for the resume prompt text; falls back to #defaultResumePrompt when nil.

Implementation Points:
- The result file is result-<topicId>.md in the topic's working directory root (not the src subdirectory).
- The file is deleted immediately after reading, so #checkAchievement is safe to call repeatedly.
- When useCommandOnGoalSet is true in the topic's settings, the notification prompt is prefixed with goalSetCommand (default: '/goal').
"
Class {
	#name : 'AbTopicGoal',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'description',
		'result',
		'whenAchieved',
		'resumePrompt'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicGoal class >> on: aTopic [

	^ self new topic: aTopic; yourself
]

{ #category : 'accessing' }
AbTopicGoal >> result [
	^ result
]

{ #category : 'accessing' }
AbTopicGoal >> result: aString [
	result := aString
]

{ #category : 'operations' }
AbTopicGoal >> checkAchievement [

	| file |
	file := self resultFile.
	file exists ifFalse: [ ^ false ].
	self result: file contents.
	file delete.
	^ true
]

{ #category : 'accessing' }
AbTopicGoal >> description [
	^ description
]

{ #category : 'accessing' }
AbTopicGoal >> description: aString [
	description := aString
]

{ #category : 'testing' }
AbTopicGoal >> isAchieved [
	^ self result notNil
]

{ #category : 'accessing' }
AbTopicGoal >> notificationPrompt [

	| basePrompt |
	basePrompt := ('Goal has been set: {1}. When the goal is achieved, summarize and report in {2}. Keep retrying until the goal is achieved.'
		format: { description. self resultFileBasename }).
	self topic settings useCommandOnGoalSet ifFalse: [ ^ basePrompt ].
	^ ('{1} {2}' format: { self topic settings goalSetCommand. basePrompt })
]

{ #category : 'accessing' }
AbTopicGoal >> resultFile [

	^ topic workingDirectory path / self resultFileBasename
]

{ #category : 'accessing' }
AbTopicGoal >> resultFileBasename [

	^ 'result-' , topic topicId , '.md'
]

{ #category : 'accessing' }
AbTopicGoal >> resumePrompt [

	^ resumePrompt ifNil: [ self defaultResumePrompt ]
]

{ #category : 'accessing' }
AbTopicGoal >> resumePrompt: aString [
	resumePrompt := aString
]

{ #category : 'private' }
AbTopicGoal >> defaultResumePrompt [

	^ 'Your work may already be complete. If so, you have not yet written the required goal result file. Please write your summary now to {1} in the current working directory (do not redo any other work) so the goal can be marked achieved. Otherwise, keep retrying until the goal is achieved: {2}'
		  format: { self resultFileBasename. self description }
]

{ #category : 'operations' }
AbTopicGoal >> fireWhenAchieved [

	self whenAchieved ifNotNil: [ :block | block cull: self ]
]

{ #category : 'accessing' }
AbTopicGoal >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicGoal >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbTopicGoal >> whenAchieved: aBlock [
	whenAchieved := aBlock
]

{ #category : 'accessing' }
AbTopicGoal >> whenAchieved [
	^ whenAchieved
]
