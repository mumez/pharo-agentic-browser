Class {
	#name : 'AbTopicGoalTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicGoalTest >> testCheckAchievementReturnsFalseWhenNoFile [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self deny: goal checkAchievement
]

{ #category : 'tests' }
AbTopicGoalTest >> testCheckAchievementReturnsTrueAndSetsResultAndDeletesFile [

	| goal topic resultFile |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	resultFile := goal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Goal reached: tests green.' ].
	[
		self assert: goal checkAchievement.
		self assert: goal isAchieved.
		self assert: goal result equals: 'Goal reached: tests green.'.
		self deny: resultFile exists ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]

{ #category : 'tests' }
AbTopicGoalTest >> testDescriptionAccessor [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: goal description equals: 'all tests pass'
]

{ #category : 'tests' }
AbTopicGoalTest >> testIsAchievedFalseByDefault [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	self deny: goal isAchieved
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptContainsDescriptionAndFileName [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: (goal notificationPrompt includesSubstring: 'all tests pass').
	self assert: (goal notificationPrompt includesSubstring: 'result-' , topic topicId , '.md')
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptPrependsGoalSetCommandWhenEnabled [

	| goal topic |
	topic := self newTopic.
	topic settings useCommandOnGoalSet: true.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: (goal notificationPrompt beginsWith: '/goal ')
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptOmitsCommandWhenUseCommandIsFalse [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self deny: (goal notificationPrompt beginsWith: '/')
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptContainsDescriptionAndFileNameWithCommand [

	| goal topic |
	topic := self newTopic.
	topic settings useCommandOnGoalSet: true.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: (goal notificationPrompt includesSubstring: 'all tests pass').
	self assert: (goal notificationPrompt includesSubstring: 'result-' , topic topicId , '.md')
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptUsesConfiguredCommandWhenEnabled [

	| goal topic |
	topic := self newTopic.
	topic settings useCommandOnGoalSet: true.
	topic settings goalSetCommand: '/mygoal'.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: (goal notificationPrompt beginsWith: '/mygoal ')
]

{ #category : 'tests' }
AbTopicGoalTest >> testOnTopicCreatesInstance [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	self assert: (goal isKindOf: AbTopicGoal)
]

{ #category : 'tests' }
AbTopicGoalTest >> testResultFileBasenameMatchesTopicId [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	self assert: goal resultFileBasename equals: 'result-' , topic topicId , '.md'
]

{ #category : 'tests' }
AbTopicGoalTest >> testResultFileIsInWorkingDirectory [

	| goal topic |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	self assert: goal resultFile parent = topic workingDirectory path.
	self assert: goal resultFile basename equals: 'result-' , topic topicId , '.md'
]

{ #category : 'tests' }
AbTopicGoalTest >> testwhenAchievedIsCalledAfterCheckAchievement [

	| goal topic resultFile called |
	topic := self newTopic.
	goal := AbTopicGoal on: topic.
	goal description: 'done'.
	called := false.
	goal whenAchieved: [ called := true ].
	resultFile := goal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Result.' ].
	[
		goal checkAchievement.
		goal fireWhenAchieved.
		self assert: called ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]
