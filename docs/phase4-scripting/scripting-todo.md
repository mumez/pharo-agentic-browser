# AbTopicOrchestration — Review TODO

Status as of branch `feature/scripting-api` (latest commits include step result passing and smoke test).

**Test status:** `AgenticBrowser-Scripting-Tests` — 30 passed (Mock-based, no real agents).

---

## Done (for review context)

- [x] Package `AgenticBrowser-Scripting` (DSL builder, seq/para steps, agent/topic builders)
- [x] Baseline groups: `default` includes Scripting; `Tests` includes Scripting-Tests
- [x] Sequential topic-to-topic result injection (`=== Previous Topic Result ===`)
- [x] Step-to-step result passing (seq output → para input → next seq input)
- [x] Parallel step: inject prior step result into each topic; combine outputs for next step
- [x] Goal completion waits for `#goalAchieved`; non-goal waits for `#endTurn`
- [x] Default agent fallback (`AbTopicOrchestration` override → `AbSettings default`)
- [x] Auto-approval settings on orchestrated topics
- [x] Shared working directory per orchestration
- [x] `planMode` post-connect action on agent builder
- [x] Unit tests: `AbAgentBuilderTest`, `AbTopicBuilderTest`, `AbTopicOrchestrationTest`
- [x] Mock DSL smoke test: `testScriptingExampleSmoke` (mirrors `docs/ab-scripting.txt` example)

---


## Code quality (recommended, not blocking)

### Class comments

- [ ] Add CRC-style class comments for Scripting classes (none yet):
  - `AbTopicOrchestration`, `AbTopicOrchestrationBuilder`
  - `AbOrchestrationStep`, `AbSequentialStep`, `AbParallelStep`
  - `AbTopicBuilder`, `AbCodingAgentBuilder`

### Refactoring

- [x] Extract duplicated auto-approval + topic setup into `AbTopicBuilder >> prepareWith:for:` and `AbTopic >> registerTo:`; removed `AbOrchestrationStep >> prepareTopicFrom:using:`
- [ ] Consider shortening long test methods flagged by tonel lint (>15 lines)

### Design clarifications to document

- [ ] **Parallel step combined result format** — currently non-nil results joined with double CRLF; document in spec if this is the contract

---

## Test gaps (Mock-level)

- [ ] `AbCodingAgentBuilder` — `opencode`, `copilot`, `cursorAgent`, `kilo`, `kiro` shortcuts untested (`claude`, `codex`, `gemini`, `planMode` covered)
- [x] `AbCodingAgentBuilder` — `model:` setter and `processModel` covered (`testModelSetsModelName`, `testModelUsesModelConfigOptionIdWhenPresent`, `testModelUsesDefaultModelIdWhenOptionMissing`)
- [ ] `AbTopicOrchestrationBuilder` — no dedicated test class (only indirect coverage)
- [x] Parallel step — topics within the same para step do not inject each other’s results (`testParallelStepTopicsDoNotInjectEachOthersResults`)
- [ ] Error path — topic never reaches `#endTurn` / `#goalAchieved` (orchestration hang; no timeout today)

---

## Runtime / headless usage (manual, out of CI)

- [ ] **Manual smoke via `st-eval`** — run `docs/ab-scripting.txt` example against real agents in a dev image
- [ ] Verify `AbTopicManager>>activeManager` uses `default` outside tests (extension on `AbTopicManager`)
- [ ] Confirm orchestration leaves topics in manager as expected; decide if cleanup/teardown API is needed

---

## Out of scope (future)

- [ ] Orchestration run timeout / per-topic timeout
- [ ] Failure propagation (abort remaining steps on error)
- [ ] WebUI or REST entry point for orchestration
- [ ] Optional integration test job with real ACP agents (separate pipeline)
- [ ] Export orchestration results to file / structured log for headless automation
