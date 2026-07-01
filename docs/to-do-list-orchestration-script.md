# To-do List App: Multi-Agent Orchestration Example

This script builds a complete Spec2 To-do list app in Pharo from scratch using six agents across seven phases — fully automated, no manual steps required.

## What this orchestration does

The script demonstrates a realistic development workflow driven entirely by the Scripting DSL:

1. **Setup** — a lightweight Claude Haiku session creates the package directory structure.
2. **Research** (parallel) — four Haiku agents simultaneously look up the Spec2 components needed (`SpListPresenter`, `SpCheckBoxPresenter`, `SpButtonPresenter`, `SpBoxLayout`). Running these concurrently cuts the research time to that of a single lookup.
3. **Design** — Codex consolidates the research results into `research-Spec2.md`, then produces a TDD implementation plan (`implementation-plan.md`) covering requirements, class design, and planned test cases.
4. **Implementation** — Codex follows the plan, writes skeleton code, imports it into the live Pharo image, runs the tests, and iterates until all tests are green. The `goal:` declaration keeps this topic running until that condition is met.
5. **UI testing** — Cursor CLI opens the presenter window inside Pharo, drives it via MCP eval calls, reads the screen with `read_screen`, and reports pass/fail for each interaction step.
6. **Review** — Claude (full model) checks for idiomatic Pharo/Spec2 style, edge cases, and simplicity, then re-imports and re-runs tests to confirm nothing regressed.
7. **Documentation** — Claude Haiku (fast and cheap for prose) adds CRC-style class comments and writes a `README.md`.

### Agent and model assignments

| Phase | Task type | Agent | Model |
|-------|-----------|-------|-------|
| 0 Setup | Project scaffolding | Claude | Haiku (lightweight) |
| 1 Research | API lookup × 4 (parallel) | Claude | Haiku (lightweight) |
| 2 Design | Planning and writing docs | Codex | default |
| 3 Implementation | Edit → import → test loop | Codex | default |
| 4 UI testing | Interactive Pharo window test | Cursor CLI | default |
| 5 Review | Code review and cleanup | Claude | default (full) |
| 6 Documentation | Class comments and README | Claude | Haiku (lightweight) |

Using a lighter model for research, setup, and documentation keeps costs low without sacrificing quality where it matters (implementation and review).

## Prerequisites

- Claude Code, Codex, and Cursor CLI must be configured as agents in AgenticBrowser.
- The AgenticBrowser Scripting package must be loaded (see [scripting.md](scripting.md#installation)).

## Script

Copy and paste this into a Pharo Playground and evaluate the whole code.

```smalltalk
orchestrationScript := AgenticBrowser scriptBy: [ :builder |

	"Phase 0: Project setup — create package directories before any code is written"
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Set up project structure'.
			t prompt: '/st-buddy Build a simple To-do list app in Pharo Smalltalk using the Spec2 framework with a TDD approach.

First, decide a package prefix based on your agent name (e.g. "Cl" for Claude).
Then set up the project structure under the shared working directory:
- src/<Prefix>Todo/       (main package)
- src/<Prefix>Todo-Tests/ (test package)

Use the st-setup-project skill to create the project structure.
Output the chosen prefix and package names as the result.' ]
	} agentBy: [ :a | a claude model: 'haiku' ].

	"Phase 1: Research Spec2 components — run all four lookups in parallel to save time"
	builder para: {
		builder topicBy: [ :t |
			t title: 'Research SpListPresenter'.
			t prompt: 'Research the SpListPresenter class in Pharo Spec2.
Document: how to create a list, set items (collection:), handle selection (whenSelectionChangedDo:), and any useful configuration.
Reply with a concise API summary.' ].
		builder topicBy: [ :t |
			t title: 'Research SpCheckBoxPresenter'.
			t prompt: 'Research the SpCheckBoxPresenter class in Pharo Spec2.
Document: how to create a checkbox, get/set its state, and handle state-change events (whenChangedDo:).
Reply with a concise API summary.' ].
		builder topicBy: [ :t |
			t title: 'Research SpButtonPresenter'.
			t prompt: 'Research the SpButtonPresenter class in Pharo Spec2.
Document: how to create a button, set its label, and attach a click action (action:).
Reply with a concise API summary.' ].
		builder topicBy: [ :t |
			t title: 'Research SpBoxLayout'.
			t prompt: 'Research SpBoxLayout in Pharo Spec2.
Document: how to create vertical/horizontal layouts (newTopToBottom, newLeftToRight), add components, and configure spacing/padding.
Reply with a concise API summary.' ]
	} agentBy: [ :a | a claude model: 'haiku' ].

	"Phase 2: Design — consolidate research, then produce a TDD implementation plan"
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Consolidate research results'.
			t prompt: 'Write the research results from the previous step to `research-Spec2.md`.' ].
		builder topicBy: [ :t |
			t title: 'Design implementation plan'.
			t prompt: 'Referring to `research-Spec2.md`, design a TDD implementation plan for a Spec2 To-do list app with these requirements:
- Each item is displayed as a checkbox row (checked = selected for removal)
- Input field at the bottom left for new item text
- Add and Remove buttons at the bottom right
- Only checked items can be removed

Write the plan to `implementation-plan.md` with these sections:
1. Requirements
2. Class design based on the research
3. Planned test cases covering the requirements' ]
	} agentBy: [ :a | a codex ].

	"Phase 3: Implementation — skeleton → import → test, then iterate until all tests pass"
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Implement and test'.
			t prompt: 'Based on `implementation-plan.md`, implement the To-do list app with TDD.

Steps:
1. Write skeleton model and presenter classes with planned methods (bodies may return nil or be empty)
2. Write a test class with the planned test methods (tests will fail at first — that is expected)
3. Import the main package (absolute path), then the test package
4. Run the test class to confirm the tests are recognized (failures are OK at this point)
5. Implement the real logic
6. Re-import and re-run tests after each change; fix failures until all tests are green
   (Consult the `smalltalk-debugger` skill for errors or timeouts)'.
			t goal: 'all unit tests pass' ]
	} agentBy: [ :a | a codex ].

	"Phase 4: UI testing — open the window in Pharo and drive it interactively via eval"
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run UI tests in Pharo'.
			t prompt: 'Open the Spec2 To-do list window in Pharo and verify it works interactively.

Steps (use the Pharo eval tool for each):
1. Open the window: `win := MyTodoPresenter open`
2. Capture the screen with MCP `read_screen` and confirm the layout
3. Add an item by sending messages to `win presenter`; verify it appears in the list
4. Check the item (set its checkbox state); verify it is marked
5. Remove the checked item (call the remove action); verify it disappears
6. Close the window: `win window close`

Report the pass/fail result of each step.' ]
	} agentBy: [ :a | a cursorAgent ].

	"Phase 5: Review — idiomatic style, edge cases, simplicity; re-run tests to confirm"
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Review and improve'.
			t prompt: 'Review the To-do list implementation for:
1. Idiomatic Pharo/Spec2 style
2. Edge cases: empty input (should not add blank items), remove with nothing checked (noop)
3. Code clarity and simplicity

Apply any improvements to the .st files, re-import, and verify tests still pass.' ]
	} agentBy: [ :a | a claude ].

	"Phase 6: Documentation — CRC class comments and README; re-import to check syntax"
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Add documentation'.
			t prompt: 'Add documentation to the To-do list implementation:
1. CRC-style class comment for the key classes (consult the `smalltalk-commenter` skill)
2. Write `README.md` covering:
   - Overview
   - Usage
   - Original plan and current status

Update the .st files with the comments and re-import to confirm no syntax errors.' ]
	} agentBy: [ :a | a claude model: 'haiku' ]
].

"Uncomment the line below to keep all agent topics visible in the UI after the run:"
"orchestrationScript settings lingerOrchestrationTopicsAfterRun: true."

[orchestrationScript run.
orchestrationScript explore] fork.
```
