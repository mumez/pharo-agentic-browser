Class {
	#name : 'AbTopicHandlerTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'private' }
AbTopicHandlerTest >> samplePermissionRequest [

	| rawValues toolCall |
	toolCall := Dictionary new
		            at: 'title' put: 'run_package_test';
		            at: 'rawInput' put: (Dictionary new
				             at: 'package_name' put: 'MoneyCalc';
				             yourself);
		            yourself.
	rawValues := Dictionary new
		             at: 'options' put: {
				             (Dictionary new
					              at: 'kind' put: 'allow_once';
					              at: 'name' put: 'Allow once';
					              at: 'optionId' put: 'allow_once';
					              yourself).
				             (Dictionary new
					              at: 'kind' put: 'allow_always';
					              at: 'name' put: 'Always allow';
					              at: 'optionId' put: 'allow_always';
					              yourself).
				             (Dictionary new
					              at: 'kind' put: 'reject_once';
					              at: 'name' put: 'Deny';
					              at: 'optionId' put: 'reject_once';
					              yourself) };
		             at: 'sessionId' put: 'session-1';
		             at: 'toolCall' put: toolCall;
		             yourself.
	^ ACPRequestPermission new rawValues: rawValues
]

{ #category : 'tests' }
AbTopicHandlerTest >> testApplyApprovalOptionIdAllowOnce [

	| response outcome |
	response := ACPRequestPermissionResponse new.
	AbTopicHandler new
		applyApprovalOptionId: AbConstants allowOnce
		toResponse: response.
	outcome := response asDictionary at: 'outcome'.
	self assert: (outcome at: 'optionId') equals: 'allow_once'
]

{ #category : 'tests' }
AbTopicHandlerTest >> testApplyApprovalOptionIdPassesThroughCustomOptionId [

	| response outcome |
	response := ACPRequestPermissionResponse new.
	AbTopicHandler new
		applyApprovalOptionId: #yes_please
		toResponse: response.
	outcome := response asDictionary at: 'outcome'.
	self assert: (outcome at: 'optionId') equals: 'yes_please'
]

{ #category : 'tests' }
AbTopicHandlerTest >> testApplyApprovalOptionIdRejectAlways [

	| response outcome |
	response := ACPRequestPermissionResponse new.
	AbTopicHandler new
		applyApprovalOptionId: #reject_always
		toResponse: response.
	outcome := response asDictionary at: 'outcome'.
	self assert: (outcome at: 'optionId') equals: 'reject_always'
]

{ #category : 'tests' }
AbTopicHandlerTest >> testPermissionOptionsForUsesOptionNameAndId [

	| options request |
	request := self samplePermissionRequest.
	options := AbTopicHandler new permissionOptionsFor: request.
	self assert: options size equals: 3.
	self assert: options first key equals: 'Allow once'.
	self assert: options first value equals: AbConstants allowOnce.
	self assert: options second key equals: 'Always allow'.
	self assert: options second value equals: AbConstants allowAlways.
	self assert: options third key equals: 'Deny'.
	self assert: options third value equals: AbConstants rejectOnce
]

{ #category : 'tests' }
AbTopicHandlerTest >> testPermissionPromptTextForIncludesToolCallContext [

	| promptText request |
	request := self samplePermissionRequest.
	promptText := AbTopicHandler new permissionPromptTextFor: request.
	self assert: (promptText includesSubstring: 'run_package_test').
	self assert: (promptText includesSubstring: 'MoneyCalc')
]
