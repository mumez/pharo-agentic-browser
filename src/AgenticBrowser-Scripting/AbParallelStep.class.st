Class {
	#name : 'AbParallelStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbParallelStep >> run [
	| semaphores topics incomingResult |
	incomingResult := self previousResult.
	topics := OrderedCollection new.
	semaphores := self topicBuilders collect: [ :builder |
		| topic semaphore activeConfig |
		activeConfig := self activeAgentConfig.
		topic := builder instantiateWith: activeConfig.
		topic workingDirectoryPath: self sharedDirectoryPath.

		"自動承認の有効化"
		topic settings aiPermissionWaitTimeoutSeconds: 0.
		topic settings aiPermissionTimeoutOption: #allow_once.
		topic settings exportApprovalWaitTimeoutSeconds: 0.
		topic settings exportApprovalTimeoutOption: #allow_once.

		AbTopicManager activeManager addTopic: topic.
		topics add: topic.

		semaphore := Semaphore new.
		topic announcer
			when: AbTopicStatusChanged
			do: [ :ann |
				((topic topicGoal description isNil or: [ topic topicGoal description isEmpty ])
					ifTrue: [ ann status = #endTurn ]
					ifFalse: [ ann status = #goalAchieved ])
						ifTrue: [ semaphore signal ] ]
			for: self.

		[
			topic session ensureConnected.
			activeConfig postConnectActions do: [ :action | action value: topic ].
			topic sendPrompt: (self promptForBuilder: builder topic: topic injecting: incomingResult)
		] fork.

		semaphore ].

	semaphores do: [ :sem | sem wait ].
	^ self combinedResultsFrom: topics
]
