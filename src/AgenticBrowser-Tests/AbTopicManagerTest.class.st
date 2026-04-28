Class {
	#name : 'AbTopicManagerTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicManagerTest >> setUp [

	AbTopicManager resetInstance
]

{ #category : 'tests' }
AbTopicManagerTest >> testAddTopic [

	| manager topic |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Test topic'.
	manager addTopic: topic.
	self assert: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testAddTopicAnnouncesAbTopicAdded [

	| manager topic received |
	manager := AbTopicManager uniqueInstance.
	received := nil.
	manager announcer
		when: AbTopicAdded
		do: [ :ann | received := ann topic ]
		for: self.
	topic := AbTopic new title: 'Test'.
	manager addTopic: topic.
	self assert: received == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopic [

	| manager topic |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Test topic'.
	manager addTopic: topic.
	manager removeTopic: topic.
	self deny: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicsInitiallyEmpty [

	self assert: AbTopicManager uniqueInstance topics isEmpty
]

{ #category : 'tests' }
AbTopicManagerTest >> testAtReturnsTopicByTopicId [

	| manager topic |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Lookup topic by at:'.
	manager addTopic: topic.
	self assert: (manager at: topic topicId) == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testUniqueInstance [

	self assert: AbTopicManager uniqueInstance == AbTopicManager uniqueInstance
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicForWorkingDirectoryPath [

	| manager topic path |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Path Lookup'.
	path := (FileLocator temp / ('ab-topic-path-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	manager addTopic: topic.
	self assert: (manager topicForWorkingDirectoryPath: path) == topic
]
