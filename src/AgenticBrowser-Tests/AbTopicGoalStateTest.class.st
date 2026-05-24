Class {
	#name : 'AbTopicGoalStateTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementReturnsFalseWhenFileAbsent [

	| topic |
	topic := self newTopic.
	topic topicGoal description: 'all tests pass'.
	self deny: topic checkGoalAchievement
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementReturnsFalseWhenNoGoal [

	| topic |
	topic := self newTopic.
	self deny: topic checkGoalAchievement
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementTransitionsToGoalAchievedWhenFilePresent [

	| topic resultFile |
	topic := self newTopic.
	topic topicGoal description: 'all tests pass'.
	topic stateMachine handleEvent: #promptSent.
	resultFile := topic topicGoal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Done.' ].
	[
		self assert: topic checkGoalAchievement.
		self assert: topic isGoalAchieved.
		self deny: resultFile exists ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedAnnouncementCarriesTopicAndGoal [

	| ann topic goal |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	ann := AbTopicGoalAchieved new topic: topic; goal: goal; yourself.
	self assert: ann topic == topic.
	self assert: ann goal == goal
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedStatusAnnouncementFired [

	| topic announced |
	topic := self newTopic.
	announced := false.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | ann status = #goalAchieved ifTrue: [ announced := true ] ]
		for: self.
	[
		topic stateMachine handleEvent: #promptSent.
		topic stateMachine handleEvent: #goalReached.
		self assert: announced ]
	ensure: [ topic announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedTransitionFromWorking [

	| topic |
	topic := self newTopic.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	self assert: topic status equals: #goalAchieved
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalDescriptionCreatesAbTopicGoal [

	| topic |
	topic := self newTopic.
	topic topicGoal description: 'all tests pass'.
	self assert: (topic topicGoal isKindOf: AbTopicGoal).
	self assert: topic topicGoal description equals: 'all tests pass'
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testIsGoalAchievedPredicate [

	| topic |
	topic := self newTopic.
	self deny: topic isGoalAchieved.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	self assert: topic isGoalAchieved
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testResetFromGoalAchievedTransitionsToInitial [

	| topic |
	topic := self newTopic.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	topic resetFromGoalAchieved.
	self assert: topic status equals: #initial
]
