"
I represent the topic-template directory that seeds new working directories.

Responsibility:
- I am a singleton. On first access via #default, I set up the template directory
  and populate it with default files (CLAUDE.md, AGENTS.md) when it is empty.
- I copy my contents into a newly-created AbWorkingDirectory, but only when
  that directory is under the same agentic-browser root.

Collaborators:
- AbSettings: I read #defaultAgenticBrowserRootDirectory for both my own path
  and the guard check in #copyTo:.
- AbWorkingDirectory: #ensureExists sends me #copyTo: after creating a new directory.

Public API and Key Messages:
- AbTopicTemplateDirectory class >> #default - Shared singleton; initializes on first call.
- AbTopicTemplateDirectory class >> #reset - Clear the singleton (for testing).
- #setupDirectory - Ensure the template directory exists; generate default files if empty.
- #copyTo: aWorkingDirectory - Copy all template children into aWorkingDirectory.
  Does nothing if the template directory does not exist or the target is not under
  the agentic-browser root.

Internal Representation:
- default (classInstVar) - Cached singleton instance.
- path - FileReference to the template directory root.
"
Class {
	#name : 'AbTopicTemplateDirectory',
	#superclass : 'Object',
	#instVars : [
		'path'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicTemplateDirectory class >> default [

	default ifNil: [ default := self new setupDirectory ].
	^ default
]

{ #category : 'accessing' }
AbTopicTemplateDirectory class >> reset [

	default := nil
]

{ #category : 'operations' }
AbTopicTemplateDirectory >> copyTo: aWorkingDirectory [

	self exists ifFalse: [ ^ self ].
	(aWorkingDirectory path fullName beginsWith: AbSettings defaultAgenticBrowserRootDirectory fullName)
		ifFalse: [ ^ self ].
	self path children do: [ :entry |
		entry copyAllTo: aWorkingDirectory path / entry basename ]
]

{ #category : 'defaults' }
AbTopicTemplateDirectory class >> defaultContextFileContent [

	^ '
## General Rules

- Act based on facts. If you are unsure, state your assumptions.
- Write the minimum code that solves the problem.

## Implementation Rules

- When editing `.st` files, actively consult the `smalltalk-developer` skill.
  - In particular, the style guide section is important.
- When debugging Smalltalk code, consult the `smalltalk-debugger` skill.
  - In particular, focus on the troubleshooting and UI debugging sections.
- Names matter. Always check that class/method/variable names are intentionally revealing. (Long names are fine)
- Always keep the DRY principle to make the code simple and clean.
- When adding a new feature, ensure it is covered by unit tests.

## Key Gotchas

- Timeout on import — Check your dependency order. Try `read_screen` for details (a Pharo debugger window has likely opened).
- **No `eval` hack** for resolving imports: Tonel files should be safely imported via the `st-import` skill. Preparing package loading code yourself could be dangerous.
'
]

{ #category : 'defaults' }
AbTopicTemplateDirectory class >> defaultAgentsMdContent [

	^ self defaultContextFileContent
]

{ #category : 'defaults' }
AbTopicTemplateDirectory class >> defaultClaudeMdContent [

	^ self defaultContextFileContent
]

{ #category : 'testing' }
AbTopicTemplateDirectory >> exists [

	^ self path exists and: [ self path isDirectory ]
]

{ #category : 'private' }
AbTopicTemplateDirectory >> generatedefaultFiles [

	(self path / 'CLAUDE.md') writeStreamDo: [ :s |
		s nextPutAll: self class defaultClaudeMdContent ].
	(self path / 'AGENTS.md') writeStreamDo: [ :s |
		s nextPutAll: self class defaultAgentsMdContent ]
]

{ #category : 'initialization' }
AbTopicTemplateDirectory >> initialize [

	path := AbSettings defaultAgenticBrowserRootDirectory / 'topic-template'
]

{ #category : 'accessing' }
AbTopicTemplateDirectory >> path [

	^ path
]

{ #category : 'accessing' }
AbTopicTemplateDirectory >> path: aFileReference [

	path := aFileReference
]

{ #category : 'initialization' }
AbTopicTemplateDirectory >> setupDirectory [

	self path ensureCreateDirectory.
	self path children ifEmpty: [ self generatedefaultFiles ].
	^ self
]
