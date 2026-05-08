Class {
	#name : 'AbTopicGoalStateTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedAnnouncementCarriesTopicAndGoal [

	| ann topic goal |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	ann := AbTopicGoalAchieved new topic: topic; goal: goal; yourself.
	self assert: ann topic == topic.
	self assert: ann goal == goal
]
