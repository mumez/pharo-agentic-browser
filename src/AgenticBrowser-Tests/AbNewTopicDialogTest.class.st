Class {
	#name : 'AbNewTopicDialogTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbNewTopicDialogTest >> testDetectPrefixesFromDirectoryWithSrc [

	| dialog dir prefixes |
	dialog := AbNewTopicDialog new.
	dir := FileLocator temp / ('test-ab-dialog-' , UUID new asString36).
	(dir / 'src' / 'ACP-Core') ensureCreateDirectory.
	(dir / 'src' / 'ACP-UI') ensureCreateDirectory.
	(dir / 'src' / 'BaselineOfACP') ensureCreateDirectory.
	[
	prefixes := dialog detectPackagePrefixesFromDirectory: dir fullName.
	self assert: (prefixes includes: 'ACP-*').
	self assert: (prefixes includes: 'BaselineOfACP') ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbNewTopicDialogTest >> testDetectPrefixesReturnsEmptyForNonExistentDir [

	| dialog prefixes |
	dialog := AbNewTopicDialog new.
	prefixes := dialog detectPackagePrefixesFromDirectory: '/nonexistent/path'.
	self assert: prefixes isEmpty
]

{ #category : 'tests' }
AbNewTopicDialogTest >> testDetectPrefixesReturnsEmptyForNoSrcDir [

	| dialog dir prefixes |
	dialog := AbNewTopicDialog new.
	dir := FileLocator temp / ('test-ab-dialog-' , UUID new asString36).
	dir ensureCreateDirectory.
	[
	prefixes := dialog detectPackagePrefixesFromDirectory: dir fullName.
	self assert: prefixes isEmpty ]
		ensure: [ dir deleteAll ]
]
