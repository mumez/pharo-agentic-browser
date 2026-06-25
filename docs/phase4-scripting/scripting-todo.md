# AbTopicOrchestration — Review TODO

Status as of `develop` (2026-06-25). Latest work: plan mode validation, model validation, error cleanup on orchestration failure.

**Test status:** `AgenticBrowser-Scripting-Tests` — 44 passed (10 `AbCodingAgentBuilderTest` + 7 `AbTopicBuilderTest` + 27 `AbTopicOrchestrationTest`; mock-based, no real agents).

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
- [x] Shared working directory per orchestration; steps can override directory path
- [x] `planMode` — resolves option value dynamically by name match; raises `AbScriptingError noSuchMode` when no matching option found or `modeConfigOption` is nil
- [x] `model:` — validates against available options; raises `AbScriptingError modelNotSupported` with available option list when no match found
- [x] Unit tests: `AbCodingAgentBuilderTest`, `AbTopicBuilderTest`, `AbTopicOrchestrationTest`
- [x] Mock DSL smoke test: `testScriptingExampleSmoke` (mirrors `docs/scripting.md` example)
- [x] CRC-style class comments added to all Scripting classes
- [x] Timeout support on orchestration steps (`testSequentialStepRunRaisesTimeoutWhenTopicNeverCompletes`, `testParallelStepRunRaisesTimeoutWhenTopicNeverCompletes`)
- [x] Topics removed from manager even on orchestration error (`testRunRemovesTopicsFromManagerEvenOnError`)
- [x] Configuration blocks on orchestration steps (`d8776f1`)
- [x] Debug logging on orchestration steps (`832033c`)
- [x] `save` / `explore` methods on `AbTopicOrchestration`

---


## Code quality (recommended, not blocking)

### Refactoring

- [x] Extract duplicated auto-approval + topic setup into `AbTopicBuilder >> prepareWith:for:` and `AbTopic >> registerTo:`; removed `AbOrchestrationStep >> prepareTopicFrom:using:`

### Design clarifications to document

- [ ] **Parallel step combined result format** — currently non-nil results joined with double CRLF; document in spec if this is the contract

---

## Test gaps (Mock-level)

- [ ] `AbCodingAgentBuilder` — `opencode`, `copilot`, `cursorAgent`, `kilo`, `kiro` shortcuts untested (`claude`, `codex`, `gemini`, `planMode`, `model:` covered)
- [ ] `AbTopicOrchestrationBuilder` — no dedicated test class (only indirect coverage via mock helpers)

---

## Runtime / headless usage (manual, out of CI)

- [ ] **Manual smoke via `st-eval`** — run `docs/scripting.md` example against real agents in a dev image

---

## Out of scope (future)

- [ ] Failure propagation (abort remaining steps on error)
- [ ] WebUI or REST entry point for orchestration
- [ ] Optional integration test job with real ACP agents (separate pipeline)
- [ ] Export orchestration results to file / structured log for headless automation
