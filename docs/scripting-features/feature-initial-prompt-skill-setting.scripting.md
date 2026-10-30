# Feature: Initial prompt skill setting

Kanban issue: `1793261354302-absettings-usestbuddyskilloninitialprompt-の見直し`

## Goal

The boolean `AbSettings >> useStBuddySkillOnInitialPrompt` is replaced by a free-form string setting
`AbSettings >> initialPromptSkill` (default `/smalltalk-dev:st-buddy`), so the first prompt of a topic
can be prefixed with any skill invocation (`$st-buddy` for codex/junie, a custom skill, or nothing):

- `initialPromptSkill` is saved to / restored from `ab-settings.json`; `useStBuddySkillOnInitialPrompt`
  is no longer written to the JSON.
- An old `ab-settings.json` that still has `useStBuddySkillOnInitialPrompt` loads correctly
  (`true` → `/smalltalk-dev:st-buddy`, `false` → empty).
- The `useStBuddySkillOnInitialPrompt` getter is kept for display, derived from `initialPromptSkill`
  (true only for exactly `/st-buddy` or `/smalltalk-dev:st-buddy`).
- The settings dialog has an `Initial Prompt Skill:` field above the st-buddy checkbox; toggling the
  checkbox rewrites the field (one-way sync); Save writes the field value.
- The Web UI settings API exposes `initialPromptSkill` and keeps `useStBuddySkillOnInitialPrompt`.
- Docs (README.md, AGENTS.md, docs/web-ui-api.md) describe the new setting.
- All four test packages pass; changed files are lint clean.

## Orchestration Shape

Sequential: implement (TDD) → test → lint & review, all via claude, each its own `seq:` block.

## Working Directory

`/home/mumez/git/pharo-agentic-browser` (existing checkout, branch
`feature/initial-prompt-skill-setting` already checked out, based on `develop`).

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
	builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Implement initialPromptSkill setting (TDD)'.
			t prompt: 'Replace the boolean setting AbSettings>>useStBuddySkillOnInitialPrompt with a free-form string setting AbSettings>>initialPromptSkill, so the first prompt of a topic can be prefixed with any skill invocation (e.g. "$st-buddy" for codex/junie, "/smalltalk-dev:st-buddy" for Claude, or a custom skill). Work on the currently checked-out git branch only: do not switch branches, do not commit, do not push. Before editing any .st file, invoke the smalltalk-dev:smalltalk-developer skill and follow its style guide.

Verified context (checked against the code):
- AbSettings (src/AgenticBrowser-Core/AbSettings.class.st) stores values in settingsDict. Each getter is "self at: #key ifAbsent: [ self defaultKey ]" and each #defaultXxx method (category defaults) delegates to the global instance when not isDefault. #asFullJsonDictionary serializes EVERY unary selector in the accessing protocol, so a unary getter left in accessing is written to ab-settings.json. AbSettings class>>loadFrom: calls "settings perform: key asMutator with: value" for each JSON key and skips unknown keys. Precedent for a legacy-key setter: #stallMonitoringIntervalSeconds: (keyword selectors are not serialized).
- AbChatPresenter>>onSendButtonClicked (src/AgenticBrowser-UI/AbChatPresenter.class.st) currently prepends the hard-coded "/st-buddy " on the first message when settings useStBuddySkillOnInitialPrompt is true. The class comment also mentions "/st-buddy ".
- AbSettingsPresenter (src/AgenticBrowser-UI/AbSettingsPresenter.class.st) builds widgets in #initializePresenters, writes back in #saveSettings, lays out in #addGeneralSettingsTo:. Text fields use #labeledRow:field:; checkboxes are added directly with withConstraints: [ :c | c height: 28 ] - keep that (a checkbox inside a height-constrained labeled row is invisible on Pharo 14). The window height comes from #windowHeight (550 with crit rows, 420 without); recent commits tuned it so the Save/Cancel buttons stay inside the window on Pharo 14, so add about one row height (~34) to both values and keep the existing layout test passing.
- AbTopicManagerRipple>>topicSettingKeys (src/AgenticBrowser-WebUI/AbTopicManagerRipple.class.st) lists the keys used by /topic/getSettings (perform: getter) and /topic/setSettings (perform: setter).
- Existing tests to update: AbSettingsTest (line ~172 asserts the JSON includesKey useStBuddySkillOnInitialPrompt - invert it; testUseStBuddySkillOnInitialPrompt* tests), AbSettingsPresenterTest (useStBuddy checkbox tests), AbChatPresenterTest (line ~615 expects "/st-buddy hello world" - becomes "/smalltalk-dev:st-buddy hello world"), AbTopicManagerRippleTest (testGetSettings*/testSetSettingsUpdatesTopicSettings).

Requirements:
1. AbSettings: add #initialPromptSkill / #initialPromptSkill: in the accessing category and #defaultInitialPromptSkill in defaults (isDefault-delegation pattern), default "/smalltalk-dev:st-buddy".
2. AbSettings>>useStBuddySkillOnInitialPrompt: aBoolean stays in accessing (so old JSON still loads through perform:). true sets initialPromptSkill to the default value "/smalltalk-dev:st-buddy" (reuse defaultInitialPromptSkill, do not duplicate the literal); false sets it to the empty string. It must NOT store #useStBuddySkillOnInitialPrompt in settingsDict. Add a short comment explaining it is kept for loading older ab-settings.json and for the checkbox.
3. AbSettings>>useStBuddySkillOnInitialPrompt (getter) is derived: true iff initialPromptSkill trimBoth equals "/st-buddy" or "/smalltalk-dev:st-buddy" (exact match only; custom values such as "$st-buddy" answer false). Move it OUT of the accessing protocol (e.g. testing) so the key no longer appears in asFullJsonDictionary. Remove defaultUseStBuddySkillOnInitialPrompt if nothing uses it anymore. Update the AbSettings CRC class comment.
4. AbChatPresenter>>onSendButtonClicked: on the first message, prefix with (settings initialPromptSkill trimBoth) followed by one space when that is not empty; when empty send the text unchanged. Update the class comment line.
5. AbSettingsPresenter: add a text field (e.g. initialPromptSkillField, reader in accessing) shown with the label "Initial Prompt Skill:" via labeledRow:field:, placed directly above the "Use st-buddy skill on initial prompt" checkbox, initialized from settings initialPromptSkill. One-way live sync: when the checkbox state changes, rewrite the field text (true -> the AbSettings default "/smalltalk-dev:st-buddy", false -> empty string). Editing the field does NOT change the checkbox. The checkbox initial state comes from the derived getter. #saveSettings writes only the field text to initialPromptSkill: and must NOT call useStBuddySkillOnInitialPrompt: (that would clobber a custom value). Adjust #windowHeight as described above. Update the CRC class comment.
6. AbTopicManagerRipple>>topicSettingKeys: add initialPromptSkill and keep useStBuddySkillOnInitialPrompt for compatibility.
7. Docs: update docs/web-ui-api.md (settings JSON example and both key tables), README.md (the note around line 168 saying the first message is prefixed with "/st-buddy " and the settings table around line 396), and AGENTS.md (around line 56) to describe the configurable initialPromptSkill (default "/smalltalk-dev:st-buddy", empty disables the prefix, the legacy useStBuddySkillOnInitialPrompt key is still accepted when loading).
8. Smallest change that satisfies the above; no unrelated refactors.

Follow strict TDD: first write failing tests, import them and run them to see them fail, then implement, import (st-import, path /home/mumez/git/pharo-agentic-browser/src) and run until green. Tests to add or adjust:
- AbSettingsTest: default initialPromptSkill; useStBuddySkillOnInitialPrompt: true / false mapping; it does not add a useStBuddySkillOnInitialPrompt key to settingsDict; derived getter true for "/st-buddy" and "/smalltalk-dev:st-buddy", false for "$st-buddy" and empty; asFullJsonDictionary includes initialPromptSkill and does not include useStBuddySkillOnInitialPrompt; loading an old JSON containing useStBuddySkillOnInitialPrompt true / false restores initialPromptSkill accordingly (reuse the way AbSettingsTest already exercises loadFrom: without touching the real user settings file).
- AbChatPresenterTest: first message uses the default prefix; a custom value (e.g. "$st-buddy") is used as prefix; an empty value sends the text without prefix.
- AbSettingsPresenterTest: field shows the default value; toggling the checkbox off clears the field and on restores the default; editing the field leaves the checkbox unchanged; save writes the field text (including a custom value while the checkbox is on).
- AbTopicManagerRippleTest: getSettings includes initialPromptSkill; setSettings with initialPromptSkill updates the topic settings; existing useStBuddySkillOnInitialPrompt assertions still pass.
Run all four test packages at the end: AgenticBrowser-Tests, AgenticBrowser-Crit-Tests, AgenticBrowser-Scripting-Tests, AgenticBrowser-WebUI-Tests.

When done, report which files you changed, the tests added or changed, and the final test counts per package.'.
			t goal: 'initialPromptSkill replaces useStBuddySkillOnInitialPrompt as described, the new and updated unit tests pass, and all tests in AgenticBrowser-Tests, AgenticBrowser-Crit-Tests, AgenticBrowser-Scripting-Tests and AgenticBrowser-WebUI-Tests pass' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Run all test packages and report'.
			t prompt: 'In the Pharo image connected via the smalltalk-interop MCP server, first re-import the packages from /home/mumez/git/pharo-agentic-browser/src in this order so the image matches the files: AgenticBrowser-Core, AgenticBrowser-Crit, AgenticBrowser-Handler, AgenticBrowser-UI, AgenticBrowser-Scripting, AgenticBrowser-WebUI, AgenticBrowser-Tests, AgenticBrowser-Crit-Tests, AgenticBrowser-Scripting-Tests, AgenticBrowser-WebUI-Tests. Then, using the st-test skill (or the run_package_test MCP tool), run AgenticBrowser-Tests, AgenticBrowser-Crit-Tests, AgenticBrowser-Scripting-Tests and AgenticBrowser-WebUI-Tests. Report exact pass/fail/error/skip counts per package and the full text of any failure or error, quoting the failing test name and message. Do not fix anything in this step and do not commit or push - just run and report. If everything is green, say so explicitly.' ]
	} agentBy: [ :a | a claude ].
	builder seq: {
		builder topicBy: [ :t |
			t title: 'Lint and style review'.
			t prompt: 'Review the changes for the initialPromptSkill setting feature (run git diff on the current branch in /home/mumez/git/pharo-agentic-browser; expect AbSettings, AbChatPresenter, AbSettingsPresenter, AbTopicManagerRipple, their tests, README.md, AGENTS.md and docs/web-ui-api.md). Consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) for each changed .st file, and consult the smalltalk-developer skill style guide section. Check that: class/method/variable names are intention revealing; the default "/smalltalk-dev:st-buddy" literal is defined once (DRY) and reused by the setter and the settings dialog; the derived useStBuddySkillOnInitialPrompt getter is not in the accessing protocol (so it is not saved to JSON) while all real accessors are in accessing; saveSettings does not call useStBuddySkillOnInitialPrompt:; CRC class comments and the docs match the behavior. Fix anything flagged, re-import, and re-run AgenticBrowser-Tests and AgenticBrowser-WebUI-Tests to confirm they still pass. Do not commit or push. Report what you found and fixed, or confirm the files were already clean.' ]
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
