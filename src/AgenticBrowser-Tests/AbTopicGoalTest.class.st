Class {
	#name : 'AbTopicGoalTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicGoalTest >> testCheckAchievementReturnsFalseWhenNoFile [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self deny: goal checkAchievement
]

{ #category : 'tests' }
AbTopicGoalTest >> testCheckAchievementReturnsTrueAndSetsAchievedAndDeletesFile [

	| goal topic resultFile |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	resultFile := goal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Goal reached: tests green.' ].
	[
		self assert: goal checkAchievement.
		self assert: goal isAchieved.
		self assert: goal achieved equals: 'Goal reached: tests green.'.
		self deny: resultFile exists ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]

{ #category : 'tests' }
AbTopicGoalTest >> testDescriptionAccessor [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: goal description equals: 'all tests pass'
]

{ #category : 'tests' }
AbTopicGoalTest >> testIsAchievedFalseByDefault [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	self deny: goal isAchieved
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptContainsDescriptionAndFileName [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: (goal notificationPrompt includesSubstring: 'all tests pass').
	self assert: (goal notificationPrompt includesSubstring: 'result-' , topic topicId , '.md')
]

{ #category : 'tests' }
AbTopicGoalTest >> testOnTopicCreatesInstance [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	self assert: (goal isKindOf: AbTopicGoal)
]

{ #category : 'tests' }
AbTopicGoalTest >> testResultFileIsInWorkingDirectory [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	self assert: goal resultFile parent = topic workingDirectory path.
	self assert: goal resultFile basename equals: 'result-' , topic topicId , '.md'
]

{ #category : 'tests' }
AbTopicGoalTest >> testWhenAchievedBlockIsCalledAfterCheckAchievement [

	| goal topic resultFile called |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'done'.
	called := false.
	goal whenAchieved: [ called := true ].
	resultFile := goal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Result.' ].
	[
		goal checkAchievement.
		goal runWhenAchievedBlock.
		self assert: called ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]
