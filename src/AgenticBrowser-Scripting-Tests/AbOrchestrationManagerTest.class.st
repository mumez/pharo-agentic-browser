Class {
	#name : 'AbOrchestrationManagerTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'running' }
AbOrchestrationManagerTest >> setUp [
	super setUp.
	AbOrchestrationManager forTest: AbOrchestrationManager new
]

{ #category : 'running' }
AbOrchestrationManagerTest >> tearDown [
	AbOrchestrationManager forTest: nil.
	super tearDown
]

{ #category : 'private' }
AbOrchestrationManagerTest >> newOrchestration [
	^ AbMockTopicOrchestration new
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testDefaultReturnsSingleton [
	| m1 m2 |
	m1 := AbOrchestrationManager default.
	m2 := AbOrchestrationManager default.
	self assert: m1 == m2
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testForTestIsIsolatedFromDefault [
	self deny: AbOrchestrationManager forTest == AbOrchestrationManager default
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testRegisterReturnsOrchestrationId [
	| orc returnedId |
	orc := self newOrchestration.
	returnedId := AbOrchestrationManager forTest register: orc.
	self assert: returnedId equals: orc id
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testOrchestrationAtReturnsRegistered [
	| orc |
	orc := self newOrchestration.
	AbOrchestrationManager forTest register: orc.
	self assert: (AbOrchestrationManager forTest orchestrationAt: orc id) == orc
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testOrchestrationAtReturnsNilForUnknownId [
	self assert: (AbOrchestrationManager forTest orchestrationAt: 'nonexistent') isNil
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testUnregisterRemovesOrchestration [
	| orc |
	orc := self newOrchestration.
	AbOrchestrationManager forTest register: orc.
	AbOrchestrationManager forTest unregister: orc.
	self assert: (AbOrchestrationManager forTest orchestrationAt: orc id) isNil
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testReleaseEmptiesAll [
	| o1 o2 |
	o1 := self newOrchestration.
	o2 := self newOrchestration.
	AbOrchestrationManager forTest register: o1.
	AbOrchestrationManager forTest register: o2.
	AbOrchestrationManager forTest release.
	self assert: (AbOrchestrationManager forTest orchestrationAt: o1 id) isNil.
	self assert: (AbOrchestrationManager forTest orchestrationAt: o2 id) isNil
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testBaseOrchestrationRegisterMethod [
	| orc returnedId |
	orc := self newOrchestration.
	returnedId := orc register.
	self assert: returnedId equals: orc id.
	self assert: (AbOrchestrationManager forTest orchestrationAt: orc id) == orc
]

{ #category : 'tests' }
AbOrchestrationManagerTest >> testBaseOrchestrationUnregisterMethod [
	| orc |
	orc := self newOrchestration.
	orc register.
	orc unregister.
	self assert: (AbOrchestrationManager forTest orchestrationAt: orc id) isNil
]
