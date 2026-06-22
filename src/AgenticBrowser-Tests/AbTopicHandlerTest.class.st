Class {
	#name : 'AbTopicHandlerTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'private' }
AbTopicHandlerTest >> permissionOption: kind name: aName optionId: anOptionId [

	^ Dictionary new
		  at: 'kind' put: kind;
		  at: 'name' put: aName;
		  at: 'optionId' put: anOptionId;
		  yourself
]

{ #category : 'private' }
AbTopicHandlerTest >> samplePermissionRequest [
	"Real Claude Code sends kind != optionId for allow_once: kind='allow_once', optionId='allow'."

	| rawValues toolCall |
	toolCall := Dictionary new
		            at: 'title' put: 'run_package_test';
		            at: 'rawInput' put: (Dictionary new at: 'package_name' put: 'MoneyCalc'; yourself);
		            yourself.
	rawValues := Dictionary new
		             at: 'options' put: {
				             (self permissionOption: 'allow_once' name: 'Allow once' optionId: 'allow').
				             (self permissionOption: 'allow_always' name: 'Always allow' optionId: 'allow_always').
				             (self permissionOption: 'reject_once' name: 'Deny' optionId: 'reject_once') };
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
AbTopicHandlerTest >> testPermissionOptionsForUsesKindAsValue [
	"Options use 'kind' as value so internal symbols (#allow_once etc.)
	 match regardless of what ACP sends as optionId."

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
AbTopicHandlerTest >> testResolveAcpOptionIdMapsAllowOnceToActualOptionId [
	"#allow_once (kind) must resolve to 'allow' (the real ACP optionId).
	 This is the core of the auto-approval bug: sending 'allow_once' instead
	 of 'allow' caused Claude Code to reject the permission response."

	| request result |
	request := self samplePermissionRequest.
	result := AbTopicHandler new
		          resolveAcpOptionId: AbConstants allowOnce
		          forRequest: request.
	self assert: result equals: 'allow'
]

{ #category : 'tests' }
AbTopicHandlerTest >> testResolveAcpOptionIdAllowAlways [

	| request result |
	request := self samplePermissionRequest.
	result := AbTopicHandler new
		          resolveAcpOptionId: AbConstants allowAlways
		          forRequest: request.
	self assert: result equals: 'allow_always'
]

{ #category : 'tests' }
AbTopicHandlerTest >> testResolveAcpOptionIdFallsBackForUnknownSymbol [

	| request result |
	request := self samplePermissionRequest.
	result := AbTopicHandler new
		          resolveAcpOptionId: #disconnected
		          forRequest: request.
	self assert: result equals: 'disconnected'
]

{ #category : 'tests' }
AbTopicHandlerTest >> testPermissionPromptTextForIncludesToolCallContext [

	| promptText request |
	request := self samplePermissionRequest.
	promptText := AbTopicHandler new permissionPromptTextFor: request.
	self assert: (promptText includesSubstring: 'run_package_test').
	self assert: (promptText includesSubstring: 'MoneyCalc')
]
