Class {
	#name : 'AbElementBuilder',
	#superclass : 'Object',
	#instVars : [
		'parentBuilder'
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

{ #category : 'actions' }
AbElementBuilder >> buildBy: aBlock [
	aBlock value: self.
	^ self
]

{ #category : 'accessing' }
AbElementBuilder >> postConnectActions [
	^ #()
]

{ #category : 'actions' }
AbElementBuilder >> onConnected: aTopic [
	self postConnectActions do: [ :action | action value: aTopic ]
]
