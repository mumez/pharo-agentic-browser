Class {
	#name : 'AbWorkingDirectoryTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbWorkingDirectoryTest >> testDirectoryNameContainsSafeTopicName [

	| topic workDir |
	topic := AbTopic new title: 'ab-test-My Cool Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: (workDir directoryName includesSubstring: 'My-Cool-Feature')
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testDirectoryNameContainsTopicIdPrefix [

	| topic workDir expectedIdPrefix |
	topic := AbTopic new title: 'ab-test-My Cool Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	expectedIdPrefix := topic topicId copyFrom: 1 to: 8.
	self assert: (workDir directoryName includesSubstring: expectedIdPrefix)
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testEnsureExists [

	| topic workDir |
	topic := AbTopic new title: 'ab-test-wd-creation'.
	workDir := AbWorkingDirectory forTopic: topic.
	workDir ensureExists.
	self assert: workDir path exists.
	workDir path deleteAll
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementBeginImport [

	| topic workDir path znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?package_name=Foo&path='
		         , path , '/src'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	self deny: workDir isImportingFromSource.
	workDir handleSisRequestAnnouncement: ann.
	self assert: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementEndImport [

	| topic workDir path znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	workDir beginImportFromSource.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?package_name=Foo&path='
		         , path , '/src'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement after: teaReq.
	workDir handleSisRequestAnnouncement: ann.
	self deny: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementIgnoresMissingPackageName [

	| topic workDir path znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?path=' , path , '/src'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	workDir handleSisRequestAnnouncement: ann.
	self deny: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementMatchesSuffixPath [
	"Verify that a path with a different prefix but matching /src/<packageName> suffix
	 is handled. This simulates symlink or Docker mount scenarios."

	| topic workDir znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	topic workingDirectoryPath: '/local/real/path/wd'.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?package_name=Foo&path=/docker/mounted/path/src'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	self deny: workDir isImportingFromSource.
	workDir handleSisRequestAnnouncement: ann.
	self assert: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementMatchesWindowsPath [
	"Verify that Windows-style backslash paths are normalized and matched correctly."

	| topic workDir teaReq ann znReq |
	topic := AbTopic new title: 'ab-test'.
	topic workingDirectoryPath: '/local/real/path/wd'.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?package_name=Foo&path=C:\Users\user\work\src'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	self deny: workDir isImportingFromSource.
	workDir handleSisRequestAnnouncement: ann.
	self assert: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementIgnoresDifferentPath [

	| topic workDir path znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?package_name=Foo&path=/different/path'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	workDir handleSisRequestAnnouncement: ann.
	self deny: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementIgnoresOtherUrls [

	| topic workDir path znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/eval?package_name=Foo&path=' , path.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	workDir handleSisRequestAnnouncement: ann.
	self deny: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testHandleSisRequestAnnouncementMatchesSourcePath [

	| topic workDir path znReq teaReq ann |
	topic := AbTopic new title: 'ab-test'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	znReq := ZnRequest get:
		         'http://localhost:1234/import-package?package_name=Foo&path='
		         , path , '/src'.
	teaReq := TeaRequest new setZnRequest: znReq pathParams: Dictionary new.
	ann := SisRequestAnnouncement before: teaReq.
	self deny: workDir isImportingFromSource.
	workDir handleSisRequestAnnouncement: ann.
	self assert: workDir isImportingFromSource
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testNewTopicWorkingDirectoryDoesNotExist [

	"A freshly-created topic must have no working directory on disk yet.
	 This is the precondition for auto-export when a package prefix is first set."

	| topic workDir |
	topic := AbTopic new title: 'ab-test-brand-new-topic'.
	workDir := AbWorkingDirectory forTopic: topic.
	self deny: workDir path exists
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testPathIsInsideAgenticBrowserSubdir [

	| topic workDir |
	topic := AbTopic new title: 'ab-test-my-feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	self
		assert: workDir path parent fullName
		equals: (Smalltalk imageDirectory / 'agentic-browser') fullName
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameEmptyFallback [

	| topic workDir |
	topic := AbTopic new title: ''.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'topic'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameReplacesSpecialChars [

	| topic workDir |
	topic := AbTopic new title: 'ab-test-My Cool Topic!'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'ab-test-My-Cool-Topic-'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSourcePathAppendsSrcDirectory [

	| topic workDir |
	topic := AbTopic new title: 'ab-test'.
	workDir := AbWorkingDirectory forTopic: topic.
	self
		assert: workDir sourcePath fullName
		equals: workDir path fullName , '/src'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSrcDirectoryDefaultsToSrc [

	| topic workDir |
	topic := AbTopic new title: 'ab-test'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir srcDirectory equals: 'src'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testEnsureExistsCopiesTemplateContentsToNewDirectory [

	| topic workDir templateDir templateFile agenticBrowserDir |
	agenticBrowserDir := Smalltalk imageDirectory / 'agentic-browser'.
	templateDir := agenticBrowserDir / 'topic-template'.
	templateFile := templateDir / 'CLAUDE.md'.
	[
		templateDir ensureCreateDirectory.
		templateFile writeStreamDo: [ :s | s nextPutAll: '# Test template' ].
		topic := AbTopic new title: 'ab-test-template-copy'.
		workDir := AbWorkingDirectory forTopic: topic.
		workDir ensureExists.
		self assert: (workDir path / 'CLAUDE.md') exists
	] ensure: [
		workDir path exists ifTrue: [ workDir path deleteAll ].
		templateDir exists ifTrue: [
			templateFile exists ifTrue: [ templateFile delete ].
			templateDir children ifEmpty: [ templateDir delete ] ]
	]
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testEnsureExistsDoesNotCopyTemplateWhenDirectoryAlreadyExists [

	| topic workDir templateDir templateFile agenticBrowserDir |
	agenticBrowserDir := Smalltalk imageDirectory / 'agentic-browser'.
	templateDir := agenticBrowserDir / 'topic-template'.
	templateFile := templateDir / 'CLAUDE.md'.
	[
		templateDir ensureCreateDirectory.
		templateFile writeStreamDo: [ :s | s nextPutAll: '# Test template' ].
		topic := AbTopic new title: 'ab-test-no-copy-existing'.
		workDir := AbWorkingDirectory forTopic: topic.
		workDir path ensureCreateDirectory.
		workDir ensureExists.
		self deny: (workDir path / 'CLAUDE.md') exists
	] ensure: [
		workDir path exists ifTrue: [ workDir path deleteAll ].
		templateDir exists ifTrue: [
			templateFile exists ifTrue: [ templateFile delete ].
			templateDir children ifEmpty: [ templateDir delete ] ]
	]
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testEnsureExistsDoesNotCopyTemplateForCustomPath [

	| topic workDir customPath templateDir templateFile agenticBrowserDir |
	agenticBrowserDir := Smalltalk imageDirectory / 'agentic-browser'.
	templateDir := agenticBrowserDir / 'topic-template'.
	templateFile := templateDir / 'CLAUDE.md'.
	customPath := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	[
		templateDir ensureCreateDirectory.
		templateFile writeStreamDo: [ :s | s nextPutAll: '# Test template' ].
		topic := AbTopic new title: 'ab-test-custom-path'.
		topic workingDirectoryPath: customPath.
		workDir := AbWorkingDirectory forTopic: topic.
		workDir ensureExists.
		self deny: (workDir path / 'CLAUDE.md') exists
	] ensure: [
		workDir path exists ifTrue: [ workDir path deleteAll ].
		templateDir exists ifTrue: [
			templateFile exists ifTrue: [ templateFile delete ].
			templateDir children ifEmpty: [ templateDir delete ] ]
	]
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testExportClassNamedWritesClassFile [

	| topic workDir path classFile |
	topic := AbTopic new title: 'ab-test-export-class'.
	path := (FileLocator temp / ('ab-wd-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	[
	workDir exportClassNamed: 'AbTopic' in: 'AgenticBrowser-Core'.
	classFile := workDir sourcePath / 'AgenticBrowser-Core' / 'AbTopic.class.st'.
	self assert: classFile exists.
	self assert: (classFile contents includesSubstring: 'AbTopic') ]
		ensure: [ workDir path deleteAll ]
]
