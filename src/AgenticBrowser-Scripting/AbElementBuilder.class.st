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

{ #category : 'accessing' }
AbElementBuilder >> parentBuilder [
	^ parentBuilder
]

{ #category : 'accessing' }
AbElementBuilder >> parentBuilder: aBuilder [
	parentBuilder := aBuilder
]

{ #category : 'building' }
AbElementBuilder >> buildBy: aBlock [
	aBlock value: self
]

{ #category : 'accessing' }
AbElementBuilder >> sessionEstablishedActions [
	^ sessionEstablishedActions ifNil: [ sessionEstablishedActions := OrderedCollection new ]
]

{ #category : 'event handling' }
AbElementBuilder >> finalizeOnSessionEstablished: aTopic [
	self sessionEstablishedActions do: [ :action | action value: aTopic ]
]
