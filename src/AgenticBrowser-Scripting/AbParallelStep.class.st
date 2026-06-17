Class {
	#name : 'AbParallelStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbParallelStep >> run [
	| semaphores |
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
			topic sendPrompt: (builder prompt ifNil: [ topic title ])
		] fork.
		
		semaphore
	].
	
	"すべての並列処理の完了を待つ"
	semaphores do: [ :sem | sem wait ]
]
