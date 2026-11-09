# Feature: Rename crit internal directories to `_crit-results` / `_crit-logs`

Kanban issue: `1794226709646-crit-results-crit-logs-のリネーム`

## Goal

AgenticBrowser's system-reserved directories under the AgenticBrowser root are prefixed with `_`,
so they are distinguishable from user-created working directories:

- crit finish results are written under `<agenticBrowserRoot>/_crit-results/` (was `crit-results/`).
- crit daemon logs are written under `<agenticBrowserRoot>/_crit-logs/` (was `crit-logs/`).
- `AbTopicManagerRipple >> isReservedWorkingDirectoryName:` treats any folder name starting with `_`
  as reserved, in addition to `topic-template` and `screenshots` (which are not renamed). So
  `_`-prefixed folders are excluded from `/workingDirectories/list` and rejected by `/topics/create`
  (code 10010), without adding one entry per internal folder.
- Finish hooks written by older versions into `.crit.config.json` (pointing at `.../crit-results/...`)
  are still recognized as system-defined, so they don't block attaching the new hooks.
- Existing directories on disk are not migrated.
- Crit and WebUI tests pass; changed files are lint clean.

## Orchestration Shape

Sequential: implement (TDD) → test → lint & review, all via claude, each its own `seq:` block.

## Working Directory

`/home/mumez/git/pharo-agentic-browser` (existing checkout, branch
`feature/rename-crit-dirs-underscore-prefix` created from `develop`; agents do not commit).

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
	builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Rename crit dirs to _crit-results/_crit-logs and reserve _-prefixed folders (TDD)'.
			t prompt: 'Rename AgenticBrowser''s internal crit directories and make every folder name starting with "_" reserved. Work on the currently checked-out git branch only: do not switch branches, do not commit, do not push.

Why: system-reserved directories under the AgenticBrowser root directory should start with "_" from now on, so they are distinguishable from user-created working directories, and so AbTopicManagerRipple >> isReservedWorkingDirectoryName: no longer needs a new entry for every internal folder.

Verified context:
- AbCritReviewFinishResultsManager >> directoryName (src/AgenticBrowser-Crit/AbCritReviewFinishResultsManager.class.st) answers ''crit-results''. Its CRC class comment mentions crit-results/ twice.
- AbCritDaemon >> logFile (src/AgenticBrowser-Crit/AbCritDaemon.class.st) hardcodes ''crit-logs''.
- AbTopicManagerRipple >> isReservedWorkingDirectoryName: (src/AgenticBrowser-WebUI/AbTopicManagerRipple.class.st) only checks AbTopicTemplateDirectory reservedFolderName and AbScreenshotAttachment reservedFolderName. It is used by handleListWorkingDirectories: (exclusion) and validateWorkingDirectoryName: (rejection with code 10010). The class comment says "/workingDirectories/list - ... (excluding reserved ''topic-template'' and ''screenshots'')".
- docs/use-crit.md (around line 70) mentions <imageDir>/agentic-browser/crit-results/.
- Tests that reference the old names: AbCritReviewFinishResultsManagerTest and AbCritConfigFileTest (crit-results), AbCritDaemonTest (crit-logs) in src/AgenticBrowser-Crit-Tests; AbTopicManagerRippleTest in src/AgenticBrowser-WebUI-Tests (testListWorkingDirectoriesExcludesReservedFolders, testCreateTopicSignalsErrorForReservedWorkingDirectoryName*).

Requirements:
1. Results directory becomes ''_crit-results'' and log directory becomes ''_crit-logs''. Do not rename topic-template or screenshots.
2. isReservedWorkingDirectoryName: answers true for any name beginning with ''_'' as well as for the two existing reservedFolderName constants. Update the AbTopicManagerRipple class comment accordingly.
3. Legacy hooks: AbCritReviewFinishResultsManager >> isSystemDefinedHookCommand: builds its regex from directoryName. Hooks that older versions wrote into topics'' .crit.config.json point at ''.../crit-results/<topicId>-<kind>.json''; after the rename they would be misclassified as user-defined, and hasUserDefinedHookNamedAnyOf:in: would then refuse to attach the new hooks. Verify this yourself; unless you find evidence it is unnecessary, keep recognizing the legacy ''crit-results'' directory name as system-defined in addition to ''_crit-results'' (with tests for both), keeping the regex logic DRY. Mention it in the class comment where it says hooks from an earlier root are still treated as ours.
4. Update the CRC class comments and docs/use-crit.md to the new names.
5. Do not migrate, move, or delete existing directories on disk. Smallest change that satisfies the above; no unrelated refactors. Use intention-revealing names.

Follow strict TDD: first update/add failing tests (new directory names in AbCritReviewFinishResultsManagerTest and AbCritDaemonTest; legacy and new hook commands recognized as system-defined; AbTopicManagerRippleTest: a "_"-prefixed folder such as ''_crit-results'' is excluded from /workingDirectories/list, and /topics/create with workingDirectory ''_anything'' fails with code 10010 - follow the existing reserved-name tests). Import (st-import) and run them to see them fail, then implement, import, and run until green. Run AgenticBrowser-Crit-Tests and AbTopicManagerRippleTest at the end.

When done, report which files you changed, the tests added/changed, and the final test counts.'.
			t goal: 'crit results/logs use _crit-results and _crit-logs, _-prefixed working directory names are reserved, legacy crit-results hooks are still recognized as system-defined, and all tests in AgenticBrowser-Crit-Tests and AbTopicManagerRippleTest pass' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run crit and WebUI test suites and report'.
			t prompt: 'Using the st-test skill (or the run_class_test / run_package_test MCP tools), run the AgenticBrowser-Crit-Tests, AgenticBrowser-WebUI-Tests and AgenticBrowser-Tests packages. Report exact pass/fail/error counts per package and the full text of any failure or error, quoting the failing test name and message. Also run "git grep -n ''crit-results\|crit-logs''" in /home/mumez/git/pharo-agentic-browser and report any remaining occurrences that are not either the new _-prefixed names or the intentional legacy crit-results hook recognition (ignore docs/scripting-features). Do not fix anything in this step and do not commit or push - just run and report. If everything is green, say so explicitly.' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Lint and style review'.
			t prompt: 'Review the files changed for the _crit-results / _crit-logs rename (check git diff on the current branch; expect AbCritReviewFinishResultsManager, AbCritDaemon, AbTopicManagerRipple, their test classes, and docs/use-crit.md). Consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) for each changed Tonel file, and consult the smalltalk-developer skill style guide section. Check that class/method/variable names are intention revealing, that directory-name and regex logic is not duplicated (DRY), that accessors/constants are in appropriate categories, and that CRC class comments and docs match the new names and the "_"-prefix reservation rule. Fix anything flagged, re-import, and re-run AgenticBrowser-Crit-Tests and AbTopicManagerRippleTest to confirm they still pass. Do not commit or push. Report what you found and fixed, or confirm the files were already clean.' ]
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
