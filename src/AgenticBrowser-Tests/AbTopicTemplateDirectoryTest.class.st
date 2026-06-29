Class {
	#name : 'AbTopicTemplateDirectoryTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicTemplateDirectoryTest >> tearDown [

	AbTopicTemplateDirectory reset.
	super tearDown
]

{ #category : 'tests' }
AbTopicTemplateDirectoryTest >> testDefaultReturnsSameInstance [

	self assert: AbTopicTemplateDirectory default == AbTopicTemplateDirectory default
]

{ #category : 'tests' }
AbTopicTemplateDirectoryTest >> testResetClearsSingleton [

	| first |
	first := AbTopicTemplateDirectory default.
	AbTopicTemplateDirectory reset.
	self deny: AbTopicTemplateDirectory default == first
]

{ #category : 'tests' }
AbTopicTemplateDirectoryTest >> testSetupDirectoryCreatesDirectoryWhenMissing [

	| templateDir instance |
	templateDir := FileLocator temp / ('ab-template-' , UUID new asString36).
	instance := AbTopicTemplateDirectory new
		            path: templateDir;
		            setupDirectory.
	[
		self assert: templateDir exists
	] ensure: [ templateDir exists ifTrue: [ templateDir deleteAll ] ]
]

{ #category : 'tests' }
AbTopicTemplateDirectoryTest >> testSetupDirectoryGeneratesDefaultFilesWhenEmpty [

	| templateDir instance |
	templateDir := FileLocator temp / ('ab-template-' , UUID new asString36).
	instance := AbTopicTemplateDirectory new
		            path: templateDir;
		            setupDirectory.
	[
		self assert: (templateDir / 'CLAUDE.md') exists.
		self assert: (templateDir / 'AGENTS.md') exists
	] ensure: [ templateDir exists ifTrue: [ templateDir deleteAll ] ]
]

{ #category : 'tests' }
AbTopicTemplateDirectoryTest >> testSetupDirectorySkipsGenerationWhenNotEmpty [

	| templateDir existingFile instance |
	templateDir := FileLocator temp / ('ab-template-' , UUID new asString36).
	templateDir ensureCreateDirectory.
	existingFile := templateDir / 'custom.md'.
	existingFile writeStreamDo: [ :s | s nextPutAll: 'custom' ].
	instance := AbTopicTemplateDirectory new
		            path: templateDir;
		            setupDirectory.
	[
		self deny: (templateDir / 'CLAUDE.md') exists.
		self deny: (templateDir / 'AGENTS.md') exists
	] ensure: [ templateDir exists ifTrue: [ templateDir deleteAll ] ]
]
