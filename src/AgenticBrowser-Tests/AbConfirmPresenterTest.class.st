Class {
	#name : 'AbConfirmPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbConfirmPresenterTest >> setUp [

	super setUp.
	presenter := AbConfirmPresenter new.
	presenter initializePresenters
]

{ #category : 'running' }
AbConfirmPresenterTest >> tearDown [

	presenter release.
	super tearDown
]

{ #category : 'tests' }
AbConfirmPresenterTest >> testApprovalOptionsWithThreeItemsUsesSubmitMode [

	presenter approvalOptions: {
			'Allow once' -> AbConstants allowOnce.
			'Allow always' -> AbConstants allowAlways.
			'Deny once' -> AbConstants rejectOnce }.

	self assert: presenter confirmButtonLabel equals: 'Submit'.
	self deny: presenter showsDenyButton
]

{ #category : 'tests' }
AbConfirmPresenterTest >> testApprovalOptionsWithTwoItemsUsesConfirmDenyMode [

	presenter approvalOptions: {
			'Allow once' -> AbConstants allowOnce.
			'Deny once' -> AbConstants rejectOnce }.

	self assert: presenter confirmButtonLabel equals: 'Confirm'.
	self assert: presenter denyButtonLabel equals: 'Deny'.
	self assert: presenter showsDenyButton
]

{ #category : 'tests' }
AbConfirmPresenterTest >> testDenyActionOptionIdUsesSecondChoiceInTwoItemMode [

	presenter approvalOptions: {
			'First' -> #first_option.
			'Second' -> #second_option }.

	self assert: presenter selectedOptionIdForDenyAction equals: #second_option
]

{ #category : 'tests' }
AbConfirmPresenterTest >> testSelectedOptionIdDefaultsToFirstOption [

	presenter approvalOptions: {
			'First' -> #first_option.
			'Second' -> #second_option.
			'Third' -> #third_option }.

	self assert: presenter selectedOptionId equals: #first_option
]
