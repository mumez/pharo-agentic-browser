# Feature: Permission timeout keeps waiting while other permission requests are pending

Kanban issue: `1793099125174-permission-timeout-resumes-working-while-other-concurrent-pe`
(follow-up of PR #143 / PR #145)

## Goal

When several AI permission requests are pending and the oldest one times out
(`aiPermissionWaitTimeoutSeconds`), the topic stays in `#waitingForHuman`, the next pending
request is announced, and the topic resumes `#working` only once no request that blocks the agent
is left — the same post-answer behavior `AbTopic>>resolveApproval:withOptionId:` already has.

- The AI permission timeout path (`respondAiPermissionOnTimeout:`) shares the post-answer logic of
  `resolveApproval:withOptionId:` instead of firing `#humanResponded` unconditionally.
- The export approval timeout path (`respondExportOnTimeout:`) is behaviorally unchanged (never
  fires `#humanResponded`).
- New `AbTopicTest` coverage; `AbTopicTest` and `AgenticBrowser-Tests` pass; changed files are lint clean.

## Orchestration Shape

Sequential: implement (TDD) → test → lint & review, all via claude, each its own `seq:` block.

## Working Directory

`/home/mumez/git/pharo-agentic-browser` (existing checkout, branch
`feature/permission-timeout-keeps-pending-requests` created from `develop`; agents do not commit).

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
	builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Keep waiting for human when a permission request times out with others pending (TDD)'.
			t prompt: 'Fix the AI permission timeout path in AbTopic so it does not resume working while other permission requests are still pending. Work on the currently checked-out git branch only: do not switch branches, do not commit, do not push.

Problem:
When several AI permission requests are pending and the oldest one times out (aiPermissionWaitTimeoutSeconds), AbTopic>>requestPermission:options: calls #respondAiPermissionOnTimeout:, which calls #respondOnTimeout:approvalOption:logMessage:changeToHumanResponded: with true. That method sets the answer, announces the message, and fires #humanResponded whenever the topic is waiting for human - without checking for other pending requests and without announcing the next one. So the topic goes back to #working, AbChatPresenter>>onTopicStatusChanged:status: leaves approval mode, and the remaining requests are no longer shown.

Verified context (src/AgenticBrowser-Core/AbTopic.class.st):
- AbTopic>>resolveApproval: anApprovalMessage withOptionId: anOptionId already has the right post-answer logic: it answers the message only if it is still unanswered (and announces it), then announces the next pending request (#pendingApprovalMessage, AI permission requests first) and returns without #humanResponded if that next one #blocksAgentProgress; otherwise it fires #humanResponded when waiting for human.
- #respondExportOnTimeout: uses the same #respondOnTimeout:approvalOption:logMessage:changeToHumanResponded: with false. The export timeout path must stay behaviorally unchanged: it must never fire #humanResponded.
- Tests are in src/AgenticBrowser-Tests/AbTopicTest.class.st. Reuse the fixtures of the existing concurrent-request tests, e.g. testResolveApprovalWithSeveralPendingKeepsWaitingForHuman, testResolveApprovalWithSeveralPendingAnnouncesTheNext, testResolveApprovalOfLastAiPermissionResumesWorkingWithExportApprovalPending, testRequestPermissionTimesOutUsingAiPermissionTimeoutOption.

Suggested approach (verify it yourself before relying on it):
- Make #respondAiPermissionOnTimeout: log its message and delegate to resolveApproval: aMessage withOptionId: self settings aiPermissionTimeoutOption, so both the human answer and the timeout share one post-answer implementation (DRY). Check that an already-answered message (answered by the human just before the timeout) keeps its answer, as #respondOnTimeout:... does today with its early return.
- If #respondOnTimeout:approvalOption:logMessage:changeToHumanResponded: is then only used by the export path, simplify it (drop the now-dead boolean parameter, or inline it into #respondExportOnTimeout:) instead of leaving dead code. Keep intention-revealing names and the approval-private category. Update the AbTopic CRC class comment only if it mentions this behavior.
- Smallest change that solves the problem; no unrelated refactors.

Follow strict TDD: first add failing tests to AbTopicTest:
1. With two pending AI permission requests (topic in #waitingForHuman), timing out the first via #respondAiPermissionOnTimeout: answers it with the aiPermissionTimeoutOption, leaves the topic in #waitingForHuman, and the second is still the pending approval message.
2. The same situation announces the second (next pending) request.
3. Timing out the last pending AI permission request returns the topic to #working (keep or add coverage for this).
4. The export approval timeout still does not fire #humanResponded (existing tests may already cover it; add one only if missing).
Import (st-import) and run them to see them fail, then implement, import and run until green. Run AbTopicTest at the end.

When done, report which files and methods you changed, the tests added, and the final test counts.'.
			t goal: 'the new AbTopicTest tests for permission timeouts with several pending requests exist and all tests in AbTopicTest pass' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run topic and UI test suites and report'.
			t prompt: 'Using the st-test skill (or the run_class_test / run_package_test MCP tools), run AbTopicTest, then the whole AgenticBrowser-Tests package. Also find and run the test classes covering AbChatPresenter approval mode (search for references to resolveApproval:withOptionId: and respondAiPermissionOnTimeout: in test packages). Report exact pass/fail/error counts per class/package and the full text of any failure or error, quoting the failing test name and message. Do not fix anything in this step and do not commit or push - just run and report. If everything is green, say so explicitly.' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Lint and style review'.
			t prompt: 'Review the Tonel files changed for the permission-timeout fix (check git diff on the current branch; expect src/AgenticBrowser-Core/AbTopic.class.st and src/AgenticBrowser-Tests/AbTopicTest.class.st). Consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) for each changed file, and consult the smalltalk-developer skill style guide section. Check that method and test names are intention revealing, that the post-answer logic (announce next pending, fire #humanResponded only when no blocking request is left) is not duplicated between the human-answer and timeout paths (DRY), that no dead parameter or unused method is left behind, and that the export approval timeout path still never fires #humanResponded. Fix anything flagged, re-import, and re-run AbTopicTest to confirm it still passes. Do not commit or push. Report what you found and fixed, or confirm the files were already clean.' ]
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
