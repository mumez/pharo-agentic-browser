Class {
	#name : 'AbSequentialStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbSequentialStep >> run [
	| currentResult |
	currentResult := self previousResult.

	self topicBuilders do: [ :builder |
		| topic semaphore prompt activeConfig |
		activeConfig := self activeAgentConfig.
		topic := builder instantiateWith: activeConfig.
		topic workingDirectoryPath: self sharedDirectoryPath.

		"自動承認の有効化"
		topic settings aiPermissionWaitTimeoutSeconds: 0.
		topic settings aiPermissionTimeoutOption: #allow_once.
		topic settings exportApprovalWaitTimeoutSeconds: 0.
		topic settings exportApprovalTimeoutOption: #allow_once.

		AbTopicManager activeManager addTopic: topic.

		semaphore := Semaphore new.
		topic announcer
			when: AbTopicStatusChanged
			do: [ :ann |
				((topic topicGoal description isNil or: [ topic topicGoal description isEmpty ])
					ifTrue: [ ann status = #endTurn ]
					ifFalse: [ ann status = #goalAchieved ])
						ifTrue: [ semaphore signal ] ]
			for: self.

		"セッションの接続と事前アクションの適用"
		topic session ensureConnected.
		activeConfig postConnectActions do: [ :action | action value: topic ].

		prompt := self promptForBuilder: builder topic: topic injecting: currentResult.
		topic sendPrompt: prompt.
		semaphore wait.
		currentResult := self resultFromTopic: topic ].
	^ currentResult
]
