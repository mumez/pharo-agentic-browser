Class {
	#name : 'AbTopicGoalAchieved',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'goal'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicGoalAchieved >> goal [
	^ goal
]

{ #category : 'accessing' }
AbTopicGoalAchieved >> goal: anAbTopicGoal [
	goal := anAbTopicGoal
]

{ #category : 'accessing' }
AbTopicGoalAchieved >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicGoalAchieved >> topic: anAbTopic [
	topic := anAbTopic
]
