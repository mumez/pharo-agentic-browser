# Feature: Ripple API — folder selection for Topic creation (workingDir)

## Goal

The server-side Ripple API (`AbTopicManagerRipple`) supports:
1. Listing existing subfolders under `<image-dir>/agentic-browser/` (excluding the reserved
   `topic-template` and `screenshots` folders), with creation/modification timestamps.
2. Creating a Topic with an optional `workingDir` folder name, safely validated against path
   traversal and reserved names, reusing an existing folder or creating a new one as appropriate,
   with a way for the caller to distinguish "reuse if it exists" from "must be new" intent.

All new and existing SUnit tests in `AgenticBrowser-WebUI-Tests` (and any other affected test
package) pass. This is server-API-only work — no web-ui client changes.

## Orchestration Shape

Sequential: implement (TDD) → test → lint & review, all via claude, each its own `seq:` block.

## Working Directory

`/home/mumez/git/pharo-agentic-browser` (existing checkout — agents work directly against this repo).

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
	builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Implement Ripple API workingDir support (TDD)'.
			t prompt: 'Implement server-side changes in AbTopicManagerRipple (src/AgenticBrowser-WebUI/AbTopicManagerRipple.class.st) to support specifying a working-directory folder when creating a Topic. Follow strict TDD: write a failing SUnit test first, then implement, then confirm it passes, for each of the two changes below. Follow the existing test file src/AgenticBrowser-WebUI-Tests/AbTopicManagerRippleTest.class.st conventions closely (see testCreateTopicAddsToManagerAndRepliesWithTopicId, testCreateTopicDefaultsTitleToUntitled, testCreateTopicPushesTopicAddedEvent for the harness pattern used against handleCreateTopic:/handleRequest:).

REQUIRED CHANGE 1 — new endpoint to list working-directory folders:
- Add a new endpoint, e.g. "/workingDirs/list", to AbTopicManagerRipple>>handleRequest: (alongside the existing /topics/list etc. dispatch), and a new handleListWorkingDirs: handler.
- It must list immediate subfolders of AbSettings defaultAgenticBrowserRootDirectory (src/AgenticBrowser-Core/AbSettings.class.st), excluding the reserved folder names "topic-template" and "screenshots" (created by AbTopicTemplateDirectory and AbScreenshotAttachment respectively — see src/AgenticBrowser-Core/AbTopicTemplateDirectory.class.st and AbScreenshotAttachment.class.st).
- Each entry should include the folder name plus creation/modification timestamps (FileReference exposes creationTime/modificationTime) so the client can sort.
- Tests: empty root (no folders), non-empty root, and confirms reserved folders are excluded.

REQUIRED CHANGE 2 — extend /topics/create with an optional workingDir:
- Extend handleCreateTopic: (and the /topics/create body handling) to accept an optional "workingDir" body key: a plain relative folder name (no path separators).
- Validation, in order: reject the name if it contains "/", "\\", or "..", or is an absolute path (invalid-name error). Reject the reserved names "topic-template" and "screenshots" (invalid-name error). Resolve AbSettings defaultAgenticBrowserRootDirectory / workingDir into a FileReference and double-check with a beginsWith: guard that it still resolves under the agentic-browser root — reuse the exact guard pattern already used in AbTopicTemplateDirectory>>copyTo: ("aWorkingDirectory path fullName beginsWith: AbSettings defaultAgenticBrowserRootDirectory fullName") rather than inventing a new one.
- Add a second optional boolean body key, "isNewFolder" (default false), to disambiguate intent: when workingDir names a folder that already exists AND isNewFolder is true, treat it as a collision and raise an application error (an equivalent of FOLDER_EXISTS/HTTP 409) instead of reusing it. When isNewFolder is false/absent: reuse the folder if it already exists, or create it if it does not (this is the only behavior a caller who omits workingDir/isNewFolder needs, and matches todays implied default).
- When reusing or creating, set the new Topics working directory via AbTopic>>workingDirectoryPath: (src/AgenticBrowser-Core/AbTopic.class.st) BEFORE the directory-creation side effects run, so that AbWorkingDirectory>>ensureExists / AbTopicTemplateDirectory>>copyTo: (src/AgenticBrowser-Core/AbWorkingDirectory.class.st) seed a genuinely-new folder from the topic-template exactly like the default path does today.
- When workingDir is omitted entirely, do not change todays behavior at all: the server must still auto-assign the default "<safeTopicName>-<uuid8>" path via AbWorkingDirectory>>defaultPath.
- On any validation failure or folder-name collision, signal an RpError the same way existing handlers do (see topicNotFoundError:, createTopicFailedError: etc.) with a distinct application error code so the web-ui can tell it apart from other creation failures — use code 10009 for the folder-name collision (FOLDER_EXISTS-equivalent) and code 10010 for an invalid/reserved workingDir name, continuing the existing 1000x numbering already used in this class.
- Tests: creating a topic with a new workingDir (folder gets created and seeded from template); creating with an existing workingDir and isNewFolder absent/false (reuses the folder, no error); creating with an existing workingDir and isNewFolder: true (raises the collision error, code 10009); path-traversal rejection for "../foo", an absolute path, and a name containing "/" (code 10010); reserved-name rejection for "topic-template" and "screenshots" (code 10010).

Document your isNewFolder-vs-reuse design choice briefly in your final summary so the reviewer understands why that flag exists — the source issue described "reuse existing" and "reject on collision" as separate behaviors without saying how a caller signals which one it means, so this flag is the resolution.

When done, report which files you changed and a summary of the two new endpoints/behaviors.'.
			t goal: 'AbTopicManagerRipple supports /workingDirs/list and workingDir/isNewFolder on /topics/create as specified, and all new SUnit tests for this feature are passing green' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run full test suite and report'.
			t prompt: 'Using the st-test skill (or the run_package_test / run_class_test MCP tools), run the full SUnit test suites for AgenticBrowser-WebUI-Tests, AgenticBrowser-Core-Tests, and AgenticBrowser-Scripting-Tests. Report exact pass/fail/error counts per package and the full text of any failure or error, quoting the failing test name and message. Do not fix anything yourself in this step — just run and report. If everything is green, say so explicitly.' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Lint and style review'.
			t prompt: 'Review the Tonel files changed in the previous steps (expect at least src/AgenticBrowser-WebUI/AbTopicManagerRipple.class.st and src/AgenticBrowser-WebUI-Tests/AbTopicManagerRippleTest.class.st) for lint and style issues: consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) against each changed file, and consult the smalltalk-developer skills style guide section. Fix anything flagged (naming, method categorization, class comment updates for AbTopicManagerRipple reflecting the new endpoints, etc.), then re-run the affected tests to confirm they still pass after your fixes. Report what you found and fixed, or confirm the files were already clean.' ]
	} agentBy: [ :a | a claude ] ].
script forkRunThen: [ :orc | Transcript crShow: 'Done: ' , orc result ]
	onTimeout: [ :timeoutStep :ex | Transcript crShow: 'Timed out: ' , timeoutStep printString ].
script register
```

## How to run

Paste the script above into a Pharo Playground, or ask the assistant to run it via st-eval.
`forkRunThen:onTimeout:` runs the orchestration in the background and returns immediately — watch
for the completion block's own report (e.g. via Transcript), the `onTimeout:` block's report if a
step stalls, or check progress with `AbOrchestrationManager default orchestrationAt: <orchestration script id>`.
