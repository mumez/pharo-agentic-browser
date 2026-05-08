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

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedStatusAnnouncementFired [

	| topic announced |
	topic := AbTopic new.
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
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	self assert: topic status equals: #goalAchieved
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testIsGoalAchievedPredicate [

	| topic |
	topic := AbTopic new.
	self deny: topic isGoalAchieved.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	self assert: topic isGoalAchieved
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testResetFromGoalAchievedTransitionsToInitial [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	topic resetFromGoalAchieved.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalDescriptionCreatesAbTopicGoal [

	| topic |
	topic := AbTopic new.
	topic goalDescription: 'all tests pass'.
	self assert: (topic topicGoal isKindOf: AbTopicGoal).
	self assert: topic topicGoal description equals: 'all tests pass'
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementReturnsFalseWhenNoGoal [

	| topic |
	topic := AbTopic new.
	self deny: topic checkGoalAchievement
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementReturnsFalseWhenFileAbsent [

	| topic |
	topic := AbTopic new.
	topic goalDescription: 'all tests pass'.
	self deny: topic checkGoalAchievement
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementTransitionsToGoalAchievedWhenFilePresent [

	| topic resultFile |
	topic := AbTopic new.
	topic goalDescription: 'all tests pass'.
	"State is already #working because goalDescription: called sendPrompt: which fired #promptSent"
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
