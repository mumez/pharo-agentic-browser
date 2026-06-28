"
I am the abstract base for DSL element builders (AbTopicBuilder, AbCodingAgentBuilder).

I hold a reference to the parent builder and a collection of deferred actions that are executed
once the ACP session for a topic is established via #finalizeOnSessionEstablished:.
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
