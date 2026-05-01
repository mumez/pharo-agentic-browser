Class {
	#name : 'AbLocalLogger',
	#superclass : 'Object',
	#instVars : [
		'logLevel'
	],
	#classInstVars : [
		'defaultLogLevel'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbLocalLogger class >> defaultLogLevel [
	^ defaultLogLevel ifNil: [ defaultLogLevel := 3 ]
]

{ #category : 'accessing' }
AbLocalLogger class >> defaultLogLevel: anInteger [
	^ defaultLogLevel := anInteger
]

{ #category : 'class initialization' }
AbLocalLogger class >> initialize [
	defaultLogLevel := nil
]

{ #category : 'actions' }
AbLocalLogger >> debug: record [
	self shouldLogDebug ifFalse: [ ^ self ].
	self log: record tag: 'DEBUG'
]

{ #category : 'actions' }
AbLocalLogger >> error: record [
	self shouldLogError ifFalse: [ ^ self ].
	self log: record tag: 'ERROR'
]

{ #category : 'actions' }
AbLocalLogger >> info: record [
	self shouldLogInfo ifFalse: [ ^ self ].
	self log: record tag: 'INFO'
]

{ #category : 'initialization' }
AbLocalLogger >> initialize [
	logLevel := nil
]

{ #category : 'accessing' }
AbLocalLogger >> isDebugging [
	^ self logLevel > 0
]

{ #category : 'accessing' }
AbLocalLogger >> isDebugging: aBoolean [
	| level |
	level := aBoolean ifTrue: [ self class defaultLogLevel ] ifFalse: [ 0 ].
	self logLevel: level
]

{ #category : 'private' }
AbLocalLogger >> log: record tag: tagString [
	Transcript cr; show: tagString , ':' , record asString
]

{ #category : 'accessing' }
AbLocalLogger >> logLevel [
	^ logLevel ifNil: [ logLevel := self class defaultLogLevel ]
]

{ #category : 'accessing' }
AbLocalLogger >> logLevel: anInteger [
	logLevel := anInteger
]

{ #category : 'testing' }
AbLocalLogger >> shouldLogDebug [
	^ self logLevel >= 3
]

{ #category : 'testing' }
AbLocalLogger >> shouldLogError [
	^ self logLevel >= 1
]

{ #category : 'testing' }
AbLocalLogger >> shouldLogInfo [
	^ self logLevel >= 4
]

{ #category : 'testing' }
AbLocalLogger >> shouldLogWarn [
	^ self logLevel >= 2
]

{ #category : 'actions' }
AbLocalLogger >> warn: record [
	self shouldLogWarn ifFalse: [ ^ self ].
	self log: record tag: 'WARN'
]
