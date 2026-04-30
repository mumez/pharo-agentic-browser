Class {
	#name : 'AbDialog',
	#superclass : 'SpPresenter',
	#instVars : [],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbDialog >> agentOptions [

	^ OrderedCollection new
		  add: 'claude-agent-acp' -> #( 'claude-agent-acp' );
		  add: 'Gemini CLI' -> #( 'gemini' '--acp' );
		  add: 'OpenCode' -> #( 'opencode' 'acp' );
		  add: 'Copilot CLI' -> #( 'copilot' '--acp' '--stdio' );
		  add: 'codex-acp' -> #( 'codex-acp' );
		  yourself
]
