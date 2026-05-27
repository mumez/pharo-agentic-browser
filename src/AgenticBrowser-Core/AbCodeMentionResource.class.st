Class {
	#name : 'AbCodeMentionResource',
	#superclass : 'Object',
	#instVars : [
		'uri',
		'text'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'factory' }
AbCodeMentionResource class >> uri: aUriString text: aTextString [

	^ self new
		uri: aUriString;
		text: aTextString;
		yourself
]

{ #category : 'accessing' }
AbCodeMentionResource >> uri [

	^ uri
]

{ #category : 'accessing' }
AbCodeMentionResource >> uri: aString [

	uri := aString
]

{ #category : 'accessing' }
AbCodeMentionResource >> text [

	^ text
]

{ #category : 'accessing' }
AbCodeMentionResource >> text: aString [

	text := aString
]

{ #category : 'prompt' }
AbCodeMentionResource >> applyToPromptParams: params [

	params resourcePrompt: self uri text: self text
]
