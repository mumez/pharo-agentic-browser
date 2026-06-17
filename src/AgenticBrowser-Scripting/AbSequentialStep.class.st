Class {
	#name : 'AbSequentialStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbSequentialStep >> run [
	| previousResult |
	previousResult := nil.
	
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

		"初期プロンプトの決定"
		prompt := builder prompt ifNil: [ topic title ].
		
		"前トピックの実行結果が存在すれば注入する"
		previousResult ifNotNil: [
			prompt := String streamContents: [ :strm |
				strm << prompt.
				strm crlf; crlf.
				strm << '=== Previous Topic Result ==='; crlf.
				strm << previousResult ] ].
		
		"最初のプロンプトを送信して開始"
		topic sendPrompt: prompt.
		
		"このトピックの完了を待つ"
		semaphore wait.
		
		"次のトピックへ引き継ぐ結果を回収"
		previousResult := topic topicGoal isAchieved 
			ifTrue: [ topic topicGoal result ]
			ifFalse: [ 
				(topic messages notEmpty and: [ topic messages last sender = #ai ])
					ifTrue: [ topic messages last text ]
					ifFalse: [ nil ] ].
	]
]
