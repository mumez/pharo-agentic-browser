Extension { #name : 'AgenticBrowser' }

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleGoalDrivenTopic [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Write Pharo summary'.
				t prompt: 'Write a one-sentence summary of what Pharo Smalltalk is.'.
				t goal: 'summary written to goal file' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	orchestrationScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleMultipleSteps [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder para: {
			builder topicBy: [ :t |
				t title: 'Research Pharo language'.
				t prompt: 'List 3 key Pharo Smalltalk language features in one sentence each. Reply with only the list.' ].
			builder topicBy: [ :t |
				t title: 'Research Pharo tools'.
				t prompt: 'List 3 key Pharo Smalltalk development tools in one sentence each. Reply with only the list.' ]
		} agentBy: [ :a | a claude ].
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Write Pharo overview'.
				t prompt: 'Write a short overview paragraph of Pharo Smalltalk based on the research results above.' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	orchestrationScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleParallelTopics [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder para: {
			builder topicBy: [ :t |
				t title: 'List Pharo features'.
				t prompt: 'List 3 Pharo Smalltalk language features in one sentence each. Reply with only the list.' ].
			builder topicBy: [ :t |
				t title: 'List Pharo tools'.
				t prompt: 'List 3 Pharo Smalltalk development tools in one sentence each. Reply with only the list.' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	orchestrationScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleSequentialTopics [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'List Pharo features'.
				t prompt: 'List 3 Pharo Smalltalk features in one sentence each. Reply with only the list.' ].
			builder topicBy: [ :t |
				t title: 'Summarize Pharo features'.
				t prompt: 'Summarize the feature list from the previous step in one sentence. Reply with only the summary.' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	orchestrationScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleGroupParallelOrchestrations [
	<script>
	| groupScript |
	groupScript := self groupScriptBy: [ :groupBuilder |
		groupBuilder para: {
			groupBuilder orchestrationBy: [ :builder |
				builder seq: {
					builder topicBy: [ :t |
						t title: 'Research Pharo language'.
						t prompt: 'Describe what Pharo Smalltalk is in one paragraph.' ]
				} agentBy: [ :a | a claude ] ].
			groupBuilder orchestrationBy: [ :builder |
				builder seq: {
					builder topicBy: [ :t |
						t title: 'Research Pharo ecosystem'.
						t prompt: 'Describe the Pharo Smalltalk ecosystem (tools, community) in one paragraph.' ]
				} agentBy: [ :a | a claude ] ]
		} ].
	[groupScript run.
	groupScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleGroupSequentialOrchestrations [
	<script>
	| groupScript |
	groupScript := self groupScriptBy: [ :groupBuilder |
		groupBuilder seq: {
			groupBuilder orchestrationBy: [ :builder |
				builder seq: {
					builder topicBy: [ :t |
						t title: 'List Pharo features'.
						t prompt: 'List 3 key Pharo Smalltalk features in one sentence each. Reply with only the list.' ]
				} agentBy: [ :a | a claude ] ].
			groupBuilder orchestrationBy: [ :builder |
				builder seq: {
					builder topicBy: [ :t |
						t title: 'Summarize Pharo features'.
						t prompt: 'Summarize the feature list from the previous step into a single sentence.' ]
				} agentBy: [ :a | a claude ] ]
		} ].
	[groupScript run.
	groupScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleSingleTopic [
	<script>
	| orchestrationScript |
	orchestrationScript :=  self scriptBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'List Pharo features'.
				t prompt: 'List 3 Pharo Smalltalk features in one sentence each. Reply with only the list.' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	orchestrationScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleSpec2TodoList [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |

		"Phase 0: Project setup - prepare directory structure before research"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Set up project structure'.
				t prompt: '/st-buddy Overview of the upcoming tasks:
Build a simple To-do list app in Pharo Smalltalk using the Spec2 framework with a TDD approach.

Full task list:
1. Project structure setup (this step)
2. Research Spec2 components (List, Checkbox, Button, Layout)
3. Design the implementation plan
4. Write unit tests first (TDD)
5. Implement model and Spec2 presenter classes
6. Import, run tests, fix until all pass
7. UI test (open in Pharo, verify add/remove)
8. Review and improve
9. Add documentation

First, decide a package prefix based on your agent name (e.g. "Cl" for Claude).
Then set up the project structure under the shared working directory:
- src/<Prefix>Todo/ (main package)
- src/<Prefix>Todo-Tests/ (test package)

Use the st-setup-project skill to create the project structure. Output the chosen prefix and package names as the result.' ]
		} agentBy: [ :a | a claude ].

		"Phase 1: Research Spec2 components in parallel"
		builder para: {
			builder topicBy: [ :t |
				t title: 'Research SpListPresenter'.
				t prompt: 'Research the SpListPresenter class in Pharo Spec2. Document: how to create a list, set items (collection:), handle selection (whenSelectionChangedDo:), and any useful configuration. Reply with a concise API summary.' ].
			builder topicBy: [ :t |
				t title: 'Research SpCheckBoxPresenter'.
				t prompt: 'Research the SpCheckBoxPresenter class in Pharo Spec2. Document: how to create a checkbox, get/set its state, and handle state-change events (whenChangedDo:). Reply with a concise API summary.' ].
			builder topicBy: [ :t |
				t title: 'Research SpButtonPresenter'.
				t prompt: 'Research the SpButtonPresenter class in Pharo Spec2. Document: how to create a button, set its label, and attach a click action (action:). Reply with a concise API summary.' ].
			builder topicBy: [ :t |
				t title: 'Research SpBoxLayout'.
				t prompt: 'Research SpBoxLayout in Pharo Spec2. Document: how to create vertical/horizontal layouts (newTopToBottom, newLeftToRight), add components, and configure spacing/padding. Reply with a concise API summary.' ]
		} agentBy: [ :a | a claude ].

		"Phase 2: Design - decide implementation plan based on research"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Design implementation plan'.
				t prompt: 'Based on the Spec2 research above, design a TDD implementation plan for a Spec2 To-do list app with these requirements:
- Each item displayed as a checkbox row (checked = selected for removal)
- Input field at the bottom left for new item text
- Add button and Remove button at the bottom right
- Only checked (selected) items can be removed

Output:
1. Package prefix based on agent name (e.g. "Cl" for Claude)
2. Class names: model class and Spec2 presenter class
3. Package names: main package and test package
4. TDD test cases to write first

Keep the design simple and idiomatic Pharo/Spec2.' ]
		} agentBy: [ :a | a claude ].

		"Phase 3: Write unit tests first (TDD)"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Write unit tests'.
				t prompt: 'Based on the implementation plan above, write SUnit unit tests for the To-do list model. Write complete Tonel-format .st file content covering:
1. Adding an item: verify it appears in the item list
2. Removing a checked item: mark an item checked, remove it, verify it is gone
3. Removing an unchecked item: verify it is a noop (item stays)
4. Listing items: verify all added items are returned

Use the class names and package names from the plan. Output the complete Tonel .st content ready to save.' ]
		} agentBy: [ :a | a claude ].

		"Phase 4: Implement model and Spec2 presenter"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Implement model and presenter'.
				t prompt: 'Based on the plan and unit tests above, implement the To-do list in Pharo Spec2. Create Tonel .st files for:
1. Model class: manages items (strings) and checked state; supports add, remove (checked only), list operations
2. Spec2 presenter class: SpBoxLayout with SpListPresenter for items with checkboxes, SpTextInputFieldPresenter for input, SpButtonPresenter for Add and Remove

Requirements:
- Each item row: checkbox bound to the item checked state
- Remove button removes only checked items
- Default layout using SpBoxLayout

Output complete Tonel .st content for both classes.' ]
		} agentBy: [ :a | a claude ].

		"Phase 5: Create files, import, run tests - fix until all pass"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Import packages and fix tests'.
				t prompt: 'Create the Tonel .st files from the previous steps in the shared working directory, import them into Pharo, and run the unit tests. Fix any failures until all tests pass.

Steps:
1. Create src/<MainPackage>/ and src/<TestPackage>/ directory structure under the shared working directory
2. Write package.st and class .st files for both packages
3. Import the main package (absolute path)
4. Import the test package (absolute path)
5. Run the test class
6. Fix any failures, re-import, re-run until all tests are green'.
				t goal: 'all unit tests pass' ]
		} agentBy: [ :a | a claude ].

		"Phase 6: UI test - open in Pharo and test interactively"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Run UI tests in Pharo'.
				t prompt: 'Open the Spec2 To-do list window in Pharo and run these UI test steps using eval:
1. Open the window (e.g. MyTodoPresenter new openWithSpec)
2. Add an item programmatically or via the UI, verify it appears
3. Check the item (set checkbox state), verify it is marked
4. Click Remove (or call remove method), verify the item disappears

Use the Pharo eval tool for each step. Report the pass/fail result of each step.' ]
		} agentBy: [ :a | a claude ].

		"Phase 7: Review and improve"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Review and improve'.
				t prompt: 'Review the To-do list implementation for:
1. Idiomatic Pharo/Spec2 style
2. Edge cases: empty input (should not add blank item), remove when nothing checked (noop)
3. Code clarity and simplicity

Apply any improvements to the .st files, re-import, and verify tests still pass.' ]
		} agentBy: [ :a | a claude ].

		"Phase 8: Documentation"
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Add documentation'.
				t prompt: 'Add documentation to the To-do list implementation:
1. CRC-style class comment for the model class (Responsibility, Collaborators, public API)
2. CRC-style class comment for the presenter class
3. Inline comments on the key layout method in the presenter

Update the .st files with the comments and re-import to confirm no syntax errors.' ]
		} agentBy: [ :a | a claude ]
	].
	[orchestrationScript run.
	orchestrationScript explore] fork.
]

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> groupRunBy: aBlock [
	^ (self groupScriptBy: aBlock) run
]

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> runBy: aBlock [
	^ (self scriptBy: aBlock) run
]

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> groupScriptBy: aBlock [
	^ self scriptBy: aBlock orchestrationType: AbOrchestrationGroup
]

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> scriptBy: aBlock [
	^ self scriptBy: aBlock orchestrationType: AbTopicOrchestration
]

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> scriptBy: aBlock orchestrationType: anOrchestrationClass [
	^ anOrchestrationClass buildBy: aBlock
]
