"
I am the result of one crit review Finish: one JSON file written by a finish hook, listed by AbCritReviewFinishResultsManager.

Responsibility:
- I wrap one result file with the topicId and kind it was named after, parse the hook payload, and build the prompt that hands crit's review loop to the agent.

Collaborators:
- AbCritReviewFinishResultsManager: It creates me for each result file in its directory.
- AbTopicManager: It sends my prompt to the topic and deletes me.

Public API and Key Messages:
- AbCritReviewFinishResult class>>file:topicId:kind: - Instance for one result file.
- #topicId / #kind / #isApproved - The topic and finish kind of the file, without reading it.
- #unresolvedCount - The unresolved comment count from the payload; 0 for an approval, without reading the file.
- #payload - The hook's stdin JSON as a Dictionary. Signals an error when the file is not complete JSON (for example while the hook is still writing it).
- #prompt - English prompt in the shape of crit's own: unresolved count, the unresolved comments with their replies, the crit comment --reply-to instruction, and the next round command (crit --session <id>).
- #delete - Delete the result file.

Internal Representation:
- file - FileReference of the result file.
- topicId - topicId String the file was named after.
- kind - #unresolved or #approved.
- payload - Parsed JSON, cached after the first successful read.
"
Class {
	#name : 'AbCritReviewFinishResult',
	#superclass : 'Object',
	#instVars : [
		'file',
		'topicId',
		'kind',
		'payload'
	],
	#category : 'AgenticBrowser-Crit',
	#package : 'AgenticBrowser-Crit'
}

{ #category : 'instance creation' }
AbCritReviewFinishResult class >> file: aFileReference topicId: aTopicIdString kind: aKindSymbol [

	^ self new
		  file: aFileReference;
		  topicId: aTopicIdString;
		  kind: aKindSymbol;
		  yourself
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> file [

	^ file
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> file: aFileReference [

	file := aFileReference
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> kind [

	^ kind
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> kind: aKindSymbol [

	kind := aKindSymbol
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> topicId [

	^ topicId
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> topicId: aTopicIdString [

	topicId := aTopicIdString
]

{ #category : 'testing' }
AbCritReviewFinishResult >> isApproved [

	^ self kind = #approved
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> payload [

	^ payload ifNil: [ payload := STONJSON fromString: self file contents ]
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> unresolvedCount [

	self isApproved ifTrue: [ ^ 0 ].
	^ self payload at: 'unresolved_count'
]

{ #category : 'accessing' }
AbCritReviewFinishResult >> prompt [

	^ String lf join: {
			  self summarySentence.
			  ''.
			  STONJSON toString: (self payload at: 'comments_unresolved_json').
			  ''.
			  self replyInstruction.
			  ''.
			  'When you''re done, run:'.
			  ''.
			  '  ' , (self payload at: 'next_round_cmd') }
]

{ #category : 'private' }
AbCritReviewFinishResult >> summarySentence [

	| count |
	count := self unresolvedCount.
	^ 'The review finished with {1} unresolved {2}.' format: {
			  count.
			  (count = 1
				   ifTrue: [ 'comment' ]
				   ifFalse: [ 'comments' ]) }
]

{ #category : 'private' }
AbCritReviewFinishResult >> replyInstruction [

	^ 'Address each comment. For each one, reply explaining what you did using `crit comment --reply-to <comment-id> --author <your-name> "<explanation>"`.'
]

{ #category : 'operations' }
AbCritReviewFinishResult >> delete [

	self file ensureDelete
]
