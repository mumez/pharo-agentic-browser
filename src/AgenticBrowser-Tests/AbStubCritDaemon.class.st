"
I am an AbCritDaemon that records shell commands and answers scripted status text.

Responsibility:
- I override #runShellCommand: so tests never spawn crit or any other process.
- I answer queued status JSON, or the result of commandBlock when one is set.

Collaborators:
- AbCritDaemonTest: It scripts my replies and asserts the commands I recorded.

Public API and Key Messages:
- #statusReplies - Queue of stdout strings consumed by crit status commands.
- #commandBlock: - Optional one-argument block used instead of the queue.
- #executedCommands - Every command string passed to #runShellCommand:, in order.
"
Class {
	#name : 'AbStubCritDaemon',
	#superclass : 'AbCritDaemon',
	#instVars : [
		'executedCommands',
		'statusReplies',
		'commandBlock'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'instance creation' }
AbStubCritDaemon class >> forTopic: anAbTopic [

	^ (super forTopic: anAbTopic)
		  readyPollDelay: 0 milliSeconds;
		  readyPollAttempts: 3;
		  yourself
]

{ #category : 'initialization' }
AbStubCritDaemon >> initialize [

	super initialize.
	executedCommands := OrderedCollection new.
	statusReplies := OrderedCollection new
]

{ #category : 'accessing' }
AbStubCritDaemon >> commandBlock [

	^ commandBlock
]

{ #category : 'accessing' }
AbStubCritDaemon >> commandBlock: aBlock [

	commandBlock := aBlock
]

{ #category : 'accessing' }
AbStubCritDaemon >> executedCommands [

	^ executedCommands
]

{ #category : 'accessing' }
AbStubCritDaemon >> statusReplies [

	^ statusReplies
]

{ #category : 'command execution' }
AbStubCritDaemon >> runShellCommand: aCommandString [

	self executedCommands add: aCommandString.
	self commandBlock ifNotNil: [ :block | ^ block value: aCommandString ].
	(aCommandString beginsWith: 'crit status') ifTrue: [
		self statusReplies ifEmpty: [ ^ '{"daemon":{"running":false}}' ].
		^ self statusReplies removeFirst ].
	^ ''
]
