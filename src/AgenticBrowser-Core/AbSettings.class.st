Class {
	#name : 'AbSettings',
	#superclass : 'Object',
	#instVars : [
		'settingsDict'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbSettings class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
AbSettings class >> defaultCopied [

	^ self new initFrom: self default
]

{ #category : 'class initialization' }
AbSettings class >> initialize [

	default := nil
]

{ #category : 'actions-dictionary' }
AbSettings >> at: aKey ifAbsentPut: aBlock [

	^ self settingsDict at: aKey ifAbsentPut: aBlock
]

{ #category : 'actions-dictionary' }
AbSettings >> at: aKey put: aValue [

	^ self settingsDict at: aKey put: aValue
]

{ #category : 'converting' }
AbSettings >> asDictionary [

	^ self keys inject: Dictionary new into: [ :dict :key |
		  dict
			  at: key put: (self perform: key);
			  yourself ]
]

{ #category : 'defaults' }
AbSettings >> defaultWatcherMessageThrottleDuration [

	^ 2 seconds
]

{ #category : 'initialization' }
AbSettings >> initFrom: otherSettings [

	self initialize.
	otherSettings settingsDict keysAndValuesDo: [ :k :v |
		self settingsDict at: k put: v ].
	^ self
]

{ #category : 'initialization' }
AbSettings >> initialize [

	settingsDict := Dictionary new
]

{ #category : 'actions-dictionary' }
AbSettings >> keys [

	^ self settingsDict keys
]

{ #category : 'private' }
AbSettings >> settingsDict [

	^ settingsDict ifNil: [ settingsDict := Dictionary new ]
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleDuration [

	^ self
		  at: #watcherMessageThrottleDuration
		  ifAbsentPut: [ self defaultWatcherMessageThrottleDuration ]
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleDuration: aDuration [

	self at: #watcherMessageThrottleDuration put: aDuration
]
