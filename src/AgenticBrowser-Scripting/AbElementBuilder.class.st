"
I am the abstract base for DSL element builders (AbTopicBuilder, AbCodingAgentBuilder).

I hold a reference to the parent builder and a collection of deferred actions that are executed
once the ACP session for a topic is established via #finalizeOnSessionEstablished:.

The deferred action pattern is used for configuration that requires a live ACP session —
for example, applying mode or model settings only after the session reports its available options.
Subclasses register [aTopic] blocks via sessionEstablishedActions, and #finalizeOnSessionEstablished:
evaluates them in order with the topic as argument.

Responsibility:
- Hold a reference to the parent builder (for DSL chaining)
- Collect deferred [aTopic] blocks to execute when the session is ready
- Execute all deferred actions when #finalizeOnSessionEstablished: is called

Collaborators:
- AbTopicOrchestrationBuilder: acts as parent builder for AbTopicBuilder and AbCodingAgentBuilder
- AbOrchestrationStep: calls #finalizeOnSessionEstablished: once the topic's session is live
- AbTopic: passed as argument to each deferred action

Public API and Key Messages:
- #on: aParentBuilder - class-side factory
- #buildBy: aBlock - evaluate the configuration block with self as argument
- #finalizeOnSessionEstablished: aTopic - execute all collected deferred actions

Internal Representation:
- parentBuilder - the enclosing DSL builder
- sessionEstablishedActions - OrderedCollection of [aTopic] blocks; evaluated on session ready
"
Class {
	#name : 'AbElementBuilder',
	#superclass : 'Object',
	#instVars : [
		'parentBuilder',
		'sessionEstablishedActions'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbElementBuilder class >> on: aParentBuilder [
	^ self new
		parentBuilder: aParentBuilder;
		yourself
]

{ #category : 'building' }
AbElementBuilder >> buildBy: aBlock [
	aBlock value: self
]

{ #category : 'event handling' }
AbElementBuilder >> finalizeOnSessionEstablished: aTopic [
	self sessionEstablishedActions do: [ :action | action value: aTopic ]
]

{ #category : 'accessing' }
AbElementBuilder >> parentBuilder [
	^ parentBuilder
]

{ #category : 'accessing' }
AbElementBuilder >> parentBuilder: aBuilder [
	parentBuilder := aBuilder
]

{ #category : 'accessing' }
AbElementBuilder >> sessionEstablishedActions [
	^ sessionEstablishedActions ifNil: [ sessionEstablishedActions := OrderedCollection new ]
]
