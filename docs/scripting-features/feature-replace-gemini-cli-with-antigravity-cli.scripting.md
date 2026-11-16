# Feature: Replace the Gemini CLI ACP preset with Antigravity CLI

Kanban-lo issue: `1794812130427-acpのプリセットを更新-gemini-cliを廃止してantigravity-cliを追加`

## Goal

Gemini CLI has reached end of support and is fully removed from the code presets, the Scripting DSL, the tests, and the docs. Its successor, Antigravity CLI (`agy`, ACP mode via `agy acp`), takes its place. All tests in `AgenticBrowser-Scripting-Tests` and `AgenticBrowser-Core-Tests` pass.

Assumptions (taken from the issue text; edit the script if you want something different):

- Preset name: `Antigravity CLI`, command `["agy", "acp"]`, in the slot where `Gemini CLI` was in `AbSettings >> defaultCodingAgentsJsonString`.
- Scripting DSL shortcut: `AbCodingAgentBuilder >> antigravity` replaces `AbCodingAgentBuilder >> gemini` (removed outright, no deprecated alias).
- README preset table links Antigravity CLI to https://antigravity.google/product/antigravity-cli/.
- Historical planning notes under `docs/phase4-scripting/` are left as they are.

## Orchestration Shape

sequential: implement (TDD) → test → lint & review, each in its own `seq:` block, all via claude

## Working Directory

`/home/mumez/git/pharo-agentic-browser`

## Script

```Smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
    builder sharedDirectoryPath: '/home/mumez/git/pharo-agentic-browser'.
    builder seq: {
        builder topicBy: [ :t |
            t title: 'Implement: replace Gemini CLI preset with Antigravity CLI (TDD)'.
            t prompt: 'In the Pharo project at /home/mumez/git/pharo-agentic-browser, Gemini CLI has reached end of support. Replace it with its successor, Antigravity CLI (executable `agy`; ACP mode is started with `agy acp`). Before editing any .st file, consult the smalltalk-developer skill (especially the style guide section). Follow TDD:
1. In src/AgenticBrowser-Scripting-Tests/AbCodingAgentBuilderTest.class.st, change testBuildByBlock to use `a antigravity` and expect #( ''agy'' ''acp'' ). Add a test (for example testAntigravitySetsArguments) in the same style as the existing per-shortcut tests such as the grokBuild one. Import the test package and confirm the new tests fail.
2. In src/AgenticBrowser-Core/AbSettings.class.st, in defaultCodingAgentsJsonString, replace {"name": "Gemini CLI", "command": ["gemini", "--acp"]} with {"name": "Antigravity CLI", "command": ["agy", "acp"]} in the same position.
3. In src/AgenticBrowser-Scripting/AbCodingAgentBuilder.class.st, remove the #gemini shortcut and add an #antigravity shortcut (category shortcuts) that calls `self useAgentArgumentsAt: ''Antigravity CLI''`. Update the class comment so it lists #antigravity instead of #gemini.
4. Grep src/ for any remaining reference to gemini / Gemini (case-insensitive) and replace it with Antigravity CLI. Import the changed packages and confirm the tests pass.
Do not touch unrelated code. Report the files you changed.'.
            t goal: 'AbCodingAgentBuilder >> gemini and the Gemini CLI preset are gone, AbCodingAgentBuilder >> antigravity returns #(''agy'' ''acp''), and all tests in AbCodingAgentBuilderTest pass' ]
    } agentBy: [ :a | a claude ].
    builder seq: {
        builder topicBy: [ :t |
            t title: 'Docs: replace Gemini CLI with Antigravity CLI'.
            t prompt: 'In /home/mumez/git/pharo-agentic-browser, Gemini CLI was replaced in the code by Antigravity CLI (executable `agy`, ACP mode `agy acp`, preset name "Antigravity CLI", Scripting DSL shortcut `antigravity`). Update the documentation to match, in English:
- README.md: in the intro sentence, the "Create a topic" step, and the "Agent-agnostic" bullet, replace "Gemini CLI" with "Antigravity CLI". In the preset agents table, replace the Gemini CLI row with an Antigravity CLI row in the form [`agy acp`](https://antigravity.google/product/antigravity-cli/) with "ACP is built-in" in the Install column, matching the style of the other rows.
- AGENTS.md: replace the "Gemini CLI" mention in the overview, and change the agentArguments: example #(''gemini'' ''--acp'') to #(''agy'' ''acp'').
- docs/scripting.md and skills/ab-scripting-feature-dev/references/scripting-dsl.md: in the Agent Builder table, replace the `gemini` / Gemini CLI row with `antigravity` / Antigravity CLI.
- docs/web-ui-api.md: replace the Gemini CLI entry in the example JSON with { "name": "Antigravity CLI", "command": ["agy", "acp"] }, keeping the column alignment.
Leave historical planning notes under docs/phase4-scripting/ unchanged. Finally, run a case-insensitive grep for "gemini" across the repo (excluding .git and docs/phase4-scripting/) and report any remaining hits.' ]
    } agentBy: [ :a | a claude ].
    builder seq: {
        builder topicBy: [ :t |
            t title: 'Test: run Scripting and Core test suites'.
            t prompt: 'In /home/mumez/git/pharo-agentic-browser, Gemini CLI was just replaced with Antigravity CLI (AbSettings defaultCodingAgentsJsonString, AbCodingAgentBuilder >> antigravity). Using the st-test skill (or the smalltalk-interop MCP run_class_test / run_package_test tools), run these and report the pass/fail counts for each:
1. AbCodingAgentBuilderTest
2. The AgenticBrowser-Scripting-Tests package
3. The AgenticBrowser-Core-Tests package
If anything fails, find out whether the Gemini to Antigravity change caused it. If it did, fix it and re-run until green. If the failure existed before the change, report it without fixing it.' ]
    } agentBy: [ :a | a claude ].
    builder seq: {
        builder topicBy: [ :t |
            t title: 'Lint & review: Antigravity CLI preset change'.
            t prompt: 'In /home/mumez/git/pharo-agentic-browser, review the uncommitted changes (git diff) that replace Gemini CLI with Antigravity CLI. Consult the st-lint skill (or the smalltalk-validator MCP lint_tonel_smalltalk_from_file tool) against every changed .st file, and consult the smalltalk-developer skill style guide section. Check that method categories, the AbCodingAgentBuilder class comment, and the test names are consistent with the existing code. Check that no Gemini references remain outside docs/phase4-scripting/, and that the Antigravity CLI row in README.md links to https://antigravity.google/product/antigravity-cli/. Fix anything you find, re-import changed packages, re-run AbCodingAgentBuilderTest, and report the findings and fixes.' ]
    } agentBy: [ :a | a claude ] ].
script forkRunThen: [ :orc | Transcript crShow: 'Done: ' , orc result ]
    onTimeout: [ :timeoutStep :ex | Transcript crShow: 'Timed out: ' , timeoutStep printString ].
script register
```

## How to run

Paste the script above into a Pharo Playground, or ask the assistant to run it via st-eval. `forkRunThen:onTimeout:` runs the orchestration in the background and returns immediately — watch for the completion block's own report (e.g. via Transcript), the `onTimeout:` block's report if a step stalls, or check progress with `AbOrchestrationManager default orchestrationAt: <orchestration script id>`.
