# AbTopicOrchestration Design and Feasibility Report (Revision 2)

The following specifications have been added and revised based on additional requirements.

---

## 1. New Requirements

### Requirement 1: Automatic Injection of Previous Topic Results into Subsequent Prompts

In a `seq:` execution flow, the output or final AI response from the preceding topic is automatically appended to the initial prompt of the next topic.

- **Result resolution**:
  - If the previous topic had a `goal` set and it was achieved (`topicGoal isAchieved` is true): retrieve `topicGoal result` (the contents of `result-<topicId>.md`).
  - If no goal was set, or the goal file does not exist: retrieve the final AI message text (`messages last text`).
- **Injection**:
  - The resolved result text is appended to the end of the next topic's initial prompt, delimited by a header such as `=== Previous Topic Result ===`.

### Requirement 2: Default Agent Configuration Fallback and Override

When no agent is explicitly specified for a topic, the system falls back through a priority chain of default configurations.

- **Fallback chain**:
  1. Agent config specified within the step (`agentConfig`)
  2. If absent, the `defaultAgentConfig` held by the `AbTopicOrchestration` instance
  3. If still absent, the system-wide default agent from `AbSettings default` (e.g., `claude-agent-acp`)
- **Override**:
  The per-orchestration default can be set via `orchestration defaultAgentConfig: anAgentConfig`.

---

## 2. Class and Method Design (Updated)

### `AbTopicOrchestration` (orchestration root)

```smalltalk
Class {
	#name : 'AbTopicOrchestration',
	#superclass : 'Object',
	#instVars : [
		'steps',
		'sharedDirectoryPath',
		'defaultAgentConfig'
	],
	#category : 'AgenticBrowser-Core'
}

AbTopicOrchestration >> initialize [
	steps := OrderedCollection new.
	sharedDirectoryPath := (Smalltalk imageDirectory / 'agentic-browser' / ('orchestration-' , UUID new asString36)) fullName.
	defaultAgentConfig := nil. "nil falls back to the first entry in AbSettings default codingAgents"
]

AbTopicOrchestration >> defaultAgentConfig [
	^ defaultAgentConfig ifNil: [ 
		"Fall back to resolving an AbAgentConfig from the system-wide default settings"
		self resolveSystemDefaultAgentConfig ]
]

AbTopicOrchestration >> defaultAgentConfig: anAgentConfig [
	defaultAgentConfig := anAgentConfig
]

AbTopicOrchestration >> run [
	steps do: [ :step | 
		step orchestration: self.
		step sharedDirectoryPath: self sharedDirectoryPath.
		step run ]
]
```

### `AbOrchestrationStep` (abstract step base class)

```smalltalk
Class {
	#name : 'AbOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration',
		'topicBuilders',
		'agentConfig',
		'sharedDirectoryPath'
	],
	#category : 'AgenticBrowser-Core'
}

AbOrchestrationStep >> activeAgentConfig [
	"Use the orchestration's default if no agent config was specified for this step"
	^ agentConfig ifNil: [ orchestration defaultAgentConfig ]
]
```

#### `AbSequentialStep` (sequential execution with automatic result injection)

```smalltalk
AbSequentialStep >> run [
	| previousResult |
	previousResult := nil.
	
	topicBuilders do: [ :builder |
		| topic semaphore prompt |
		topic := builder instantiateWith: self activeAgentConfig.
		topic workingDirectoryPath: self sharedDirectoryPath.
		
		"Enable auto-approval for permissions and exports"
		topic settings aiPermissionWaitTimeoutSeconds: 0.
		topic settings aiPermissionTimeoutOption: #allow_once.
		topic settings exportApprovalWaitTimeoutSeconds: 0.
		topic settings exportApprovalTimeoutOption: #allow_once.

		AbTopicManager default addTopic: topic.
		
		semaphore := Semaphore new.
		topic announcer when: AbTopicStatusChanged do: [ :ann |
			((topic topicGoal description isNil)
				ifTrue: [ ann status = #endTurn ]
				ifFalse: [ ann status = #goalAchieved ])
					ifTrue: [ semaphore signal ] ].
		
		"Determine the initial prompt"
		prompt := builder prompt ifNil: [ topic title ].
		
		"Inject the previous topic's result if one exists"
		previousResult ifNotNil: [
			prompt := String streamContents: [ :strm |
				strm << prompt.
				strm crlf; crlf.
				strm << '=== Previous Topic Result ==='; crlf.
				strm << previousResult ] ].
		
		"Send the initial prompt to start the topic"
		topic sendPrompt: prompt.
		
		"Wait for this topic to complete"
		semaphore wait.
		
		"Collect the result to pass to the next topic"
		previousResult := topic topicGoal isAchieved 
			ifTrue: [ topic topicGoal result ]
			ifFalse: [ 
				(topic messages notEmpty and: [ topic messages last sender = #ai ])
					ifTrue: [ topic messages last text ]
					ifFalse: [ nil ] ].
	]
]
```
