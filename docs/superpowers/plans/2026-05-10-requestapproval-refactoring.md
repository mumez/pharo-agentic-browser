# requestApproval Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `requestApproval:options:` into two distinct paths — `requestPermission:options:` (ACP handler, waits indefinitely) and `requestPackageExport:` (watcher, auto-rejects on timeout).

**Architecture:** `AbTopic` exposes two public entry points with different wait semantics; both share private plumbing methods. `AbTopicHandler` and `AbTopicRelatedPackagesWatcher` each call only the entry point matching their context.

**Tech Stack:** Pharo 13, Tonel format, MCP smalltalk-interop tools for import/test, TDD.

---

## File Map

| File | Change |
|------|--------|
| `src/AgenticBrowser-Core/AbTopic.class.st` | Add `requestPermission:`, `requestPermission:options:`, `requestPackageExport:`; remove `requestApproval:`, `requestApproval:options:` |
| `src/AgenticBrowser-Handler/AbTopicHandler.class.st` | Change `requestPermission:` to call `topic requestPermission:options:` |
| `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st` | Change `requestApprovalToExportPackage:` to call `topic requestPackageExport:`; remove `requestApprovalToTrackPackage:` |
| `src/AgenticBrowser-Tests/AbTopicTest.class.st` | Rename approval tests to permission tests; add `requestPackageExport:` timeout test |

---

### Task 1: Add `requestPermission:` and `requestPermission:options:` to AbTopic (TDD)

**Files:**
- Modify: `src/AgenticBrowser-Tests/AbTopicTest.class.st`
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`

- [ ] **Step 1: Write three failing tests** — rename the three existing `requestApproval` tests to `requestPermission` variants

  In `AbTopicTest`:

  Remove:
  - `testRequestApprovalReturnsResolvedResponse`
  - `testRequestApprovalFromIdleTransitionsToDone` (invalid — ACP permission cannot arrive before first prompt)
  - `testRequestApprovalFromDoneTransitionsToWorking`

  Add:

  ```smalltalk
  testRequestPermissionReturnsResolvedResponse
      | topic response done |
      topic := AbTopic new.
      done := Semaphore new.
      [
      response := topic requestPermission: 'Approve this action?'.
      done signal ] fork.
      [ topic hasPendingApprovalRequest ] whileFalse: [
          (Delay forMilliseconds: 1) wait ].
      topic resolveApproval: 'yes'.
      done waitTimeoutMilliseconds: 1000.
      self assert: response equals: #allowOnce
  ```

  ```smalltalk
  testRequestPermissionFromDoneTransitionsToWorking
      | topic response done |
      topic := AbTopic new.
      topic stateMachine handleEvent: #promptSent.
      topic stateMachine handleEvent: #turnEnded.
      done := Semaphore new.
      [
      response := topic requestPermission: 'Approve this action?'.
      done signal ] fork.
      [ topic hasPendingApprovalRequest ] whileFalse: [
          (Delay forMilliseconds: 1) wait ].
      topic resolveApproval: 'yes'.
      done waitTimeoutMilliseconds: 1000.
      self assert: response equals: #allowOnce.
      self assert: topic status equals: #working
  ```

- [ ] **Step 2: Import AgenticBrowser-Tests and run to confirm failures**

  Use `import_package` MCP tool for `AgenticBrowser-Tests`, then `run_class_test` on `AbTopicTest`. Expect `testRequestPermission*` to fail with "does not understand #requestPermission:".

- [ ] **Step 3: Add `requestPermission:` and `requestPermission:options:` to AbTopic**

  In `AbTopic` (category `approval`):

  ```smalltalk
  requestPermission: aDescription
      ^ self requestPermission: aDescription options: self defaultApprovalOptions
  ```

  ```smalltalk
  requestPermission: aDescription options: approvalOptions
      | msg permissionResponse |
      msg := self addApprovalRequestAndWaitForHuman: aDescription options: approvalOptions.
      permissionResponse := self waitForPermissionResponseOf: msg.
      permissionResponse ifNil: [
          self logger debug: 'requestPermission: timeout reached, auto rejecting'.
          msg approvalResponse: #rejectOnce.
          self isWaitingForHuman ifTrue: [ self stateMachine handleEvent: #humanResponded ] ].
      self logger debug: 'requestPermission: done. response=' , msg approvalResponse printString.
      ^ msg approvalResponse ifNil: [ #rejectOnce ]
  ```

  `wasInitial` 処理なし — ACP プロトコル上、initial 状態でパーミッションが来ることはない。

  `waitForPermissionResponseOf:` returns the response value (or nil on timeout):

  ```smalltalk
  waitForPermissionResponseOf: aMessage
      | waitSeconds |
      waitSeconds := 0.
      [ aMessage approvalResponse isNil and: [ waitSeconds < AbSettings default permissionWaitTimeoutSeconds ] ] whileTrue: [
          1 second wait.
          waitSeconds := waitSeconds + 1 ].
      ^ aMessage approvalResponse
  ```

  Add `permissionWaitTimeoutSeconds` and `permissionWaitTimeoutSeconds:` to `AbSettings` (default: 1800).

  > **Note:** If the user closes the window mid-wait, the background process will continue until the timeout expires. This is the same pre-existing behavior as `waitForApprovalResponseOf:` and will be addressed in a separate task (disconnect → force-resolve pending approvals).

- [ ] **Step 4: Import AgenticBrowser-Core and run tests**

  Import `AgenticBrowser-Core`, then `AgenticBrowser-Tests`, then run `AbTopicTest`. Expect the three new `testRequestPermission*` tests to pass.

- [ ] **Step 5: Commit**

  Export `AgenticBrowser-Core` and `AgenticBrowser-Tests`, then:
  ```bash
  git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
  git commit -m "feat: add requestPermission: entry point to AbTopic (ACP handler path)"
  ```

---

### Task 2: Add `requestPackageExport:` to AbTopic (TDD)

**Files:**
- Modify: `src/AgenticBrowser-Tests/AbTopicTest.class.st`
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`

- [ ] **Step 1: Rename timeout test and add idle-state test for `requestPackageExport:`**

  Remove `testRequestApprovalTimesOutAndRejects` from `AbTopicTest`, add:

  ```smalltalk
  testRequestPackageExportTimesOutAndRejects
      | topic response done timedOut |
      topic := AbTopic new.
      AbSettings default approvalWaitTimeoutSeconds: 0.
      done := Semaphore new.
      [
      response := topic requestPackageExport: 'Package ''Foo'' was modified. Export now?'.
      done signal ] fork.
      timedOut := done waitTimeoutMilliseconds: 200.
      self deny: timedOut.
      self assert: response equals: #rejectOnce.
      self assert: topic status equals: #initial  "state machine not touched"
  ```

  Also add (watcher は `initial` 状態でも起動するため、ステートマシンの状態に関わらず動作することを確認):

  ```smalltalk
  testRequestPackageExportFromIdleReturnsResponse
      | topic response done |
      topic := AbTopic new.
      done := Semaphore new.
      [
      response := topic requestPackageExport: 'Package ''Foo'' was modified. Export now?'.
      done signal ] fork.
      [ topic hasPendingApprovalRequest ] whileFalse: [
          (Delay forMilliseconds: 1) wait ].
      topic resolveApproval: 'yes'.
      done waitTimeoutMilliseconds: 1000.
      self assert: response equals: #allowOnce.
      self assert: topic status equals: #initial  "state machine not touched"
  ```

- [ ] **Step 2: Fix `resolveApprovalWithOptionId:` to conditionally fire `#humanResponded`**

  Current:
  ```smalltalk
  resolveApprovalWithOptionId: anOptionId
      | pending |
      pending := self pendingApprovalMessage.
      pending ifNil: [ ^ self ].
      pending approvalResponse: anOptionId.
      self stateMachine handleEvent: #humanResponded.
      ...
  ```

  Change to fire `#humanResponded` only when in `waitingForHuman` (consistent with `rejectApprovalOnTimeout:`):

  ```smalltalk
  resolveApprovalWithOptionId: anOptionId
      | pending |
      pending := self pendingApprovalMessage.
      pending ifNil: [ ^ self ].
      pending approvalResponse: anOptionId.
      self isWaitingForHuman ifTrue: [ self stateMachine handleEvent: #humanResponded ].
      self logger debug: 'resolveApproval: status(after humanResponded)=' , self status printString.
      self logger debug: 'resolveApproval: done'
  ```

  Add test to `AbTopicTest`:

  ```smalltalk
  testResolveApprovalWhenNotWaitingForHumanDoesNotChangeState
      | topic msg |
      topic := AbTopic new.
      msg := AbMessage approvalRequestText: 'Export?'.
      topic messages add: msg.
      topic resolveApproval: 'yes'.
      self assert: topic status equals: #initial  "no state change"
  ```

- [ ] **Step 3: Import AgenticBrowser-Tests and run to confirm failures**

  Run `AbTopicTest`. Expect `testRequestPackageExport*` and `testResolveApprovalWhenNotWaiting*` to fail.

- [ ] **Step 4: Add `requestPackageExport:` to AbTopic; fix `resolveApprovalWithOptionId:`**

  In `AbTopic` (category `approval`):

  ```smalltalk
  requestPackageExport: aDescription
      | msg waitSeconds |
      msg := self addApprovalRequest: aDescription options: self defaultApprovalOptions.
      waitSeconds := 0.
      [ msg approvalResponse isNil and: [ waitSeconds < AbSettings default approvalWaitTimeoutSeconds ] ] whileTrue: [
          1 second wait.
          waitSeconds := waitSeconds + 1 ].
      msg approvalResponse isNil ifTrue: [
          self logger debug: 'requestPackageExport: timeout reached, auto rejecting'.
          msg approvalResponse: #rejectOnce ].
      self logger debug: 'requestPackageExport: done. response=' , msg approvalResponse printString.
      ^ msg approvalResponse ifNil: [ #rejectOnce ]
  ```

  ステートマシンには一切触れない。`addApprovalRequest:options:` で UI にメッセージを追加するのみ。

  Fix `resolveApprovalWithOptionId:` (see Step 2 above).

- [ ] **Step 4: Import and run tests**

  Import `AgenticBrowser-Core`, `AgenticBrowser-Tests`, run `AbTopicTest`. All tests should pass.

- [ ] **Step 5: Commit**

  Export both packages:
  ```bash
  git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
  git commit -m "feat: add requestPackageExport: to AbTopic with timeout auto-reject (watcher path)"
  ```

---

### Task 3: Update AbTopicHandler to use `requestPermission:options:`

**Files:**
- Modify: `src/AgenticBrowser-Handler/AbTopicHandler.class.st`

No test change needed — `AbTopicHandlerTest` tests `permissionOptionsFor:` and `applyApprovalOptionId:toResponse:`, not the routing to `requestApproval:`. After this change those tests still pass.

- [ ] **Step 1: Change `requestPermission:` in AbTopicHandler**

  Current:
  ```smalltalk
  requestPermission: anACPRequestPermission
      | response approvalOptionId |
      self logger debug: 'requestPermission: ' , anACPRequestPermission printString.
      anACPRequestPermission inspect.
      approvalOptionId := self topic
                        requestApproval: (self permissionPromptTextFor: anACPRequestPermission)
                        options: (self permissionOptionsFor: anACPRequestPermission).
      ...
  ```

  Change `requestApproval:options:` to `requestPermission:options:`:

  ```smalltalk
  requestPermission: anACPRequestPermission
      | response approvalOptionId |
      self logger debug: 'requestPermission: ' , anACPRequestPermission printString.
      approvalOptionId := self topic
                        requestPermission: (self permissionPromptTextFor: anACPRequestPermission)
                        options: (self permissionOptionsFor: anACPRequestPermission).
      self logger debug: 'requestPermission: got approvalResponse=' , approvalOptionId printString.
      response := anACPRequestPermission makeResponse.
      self applyApprovalOptionId: approvalOptionId toResponse: response.
      ^ response
  ```

- [ ] **Step 2: Import AgenticBrowser-Handler and run tests**

  Import `AgenticBrowser-Handler`, `AgenticBrowser-Tests`, run `AbTopicHandlerTest`. All tests should pass.

- [ ] **Step 3: Commit**

  ```bash
  git add src/AgenticBrowser-Handler/AbTopicHandler.class.st
  git commit -m "refactor: AbTopicHandler uses requestPermission:options: on topic"
  ```

---

### Task 4: Update watcher to use `requestPackageExport:`; remove dead `requestApprovalToTrackPackage:`

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st`

- [ ] **Step 1: Verify `requestApprovalToTrackPackage:` is dead code**

  Check that no test or method calls `requestApprovalToTrackPackage:`. (Confirmed from `doHandlePackageChange:` — it only calls `requestApprovalToExportPackage:` or `trackExternalPackageChange:`.)

- [ ] **Step 2: Change `requestApprovalToExportPackage:` and remove dead method**

  Change `requestApprovalToExportPackage:` in `AbTopicRelatedPackagesWatcher`:

  ```smalltalk
  requestApprovalToExportPackage: aPackageName
      | approvalResponse |
      self logger debug: 'requestApprovalToExportPackage: ' , aPackageName.
      [
      approvalResponse := self topic requestPackageExport:
                          (self exportPackageApprovalPromptFor: aPackageName).
      self handleExportPackageApprovalResponse: approvalResponse packageName: aPackageName ]
          ensure: [ self cleanupPendingApprovalFor: aPackageName in: 'requestApprovalToExportPackage:' ]
  ```

  Remove method `requestApprovalToTrackPackage:` entirely.
  Remove method `trackPackageApprovalPromptFor:` (used only by the removed method).

- [ ] **Step 3: Check tests — verify no test calls `requestApprovalToTrackPackage:`**

  Verify `testHandlePackageChangeForExternalPackageTracksWithoutApproval` — it tests that external packages are tracked without approval via `trackExternalPackageChange:`, which is unaffected.

- [ ] **Step 4: Import and run full test suite**

  Import Core, Handler, UI, Tests in order. Run `AbTopicRelatedPackagesWatcherTest` and `AbTopicTest`. All should pass.

- [ ] **Step 5: Commit**

  ```bash
  git add src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st
  git commit -m "refactor: watcher uses requestPackageExport:; remove dead requestApprovalToTrackPackage:"
  ```

---

### Task 5: Remove old `requestApproval:` and `requestApproval:options:` from AbTopic

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicTest.class.st`

- [ ] **Step 1: Verify no remaining callers of `requestApproval:`**

  Grep for `requestApproval:` in the codebase. After Tasks 3–4 it should only appear in `AbTopic` itself (the method definitions being removed) and in any remaining tests.

  ```bash
  grep -r "requestApproval:" src/ --include="*.st" -l
  ```

  Expected: only `AbTopic.class.st` and `AbTopicTest.class.st`.

- [ ] **Step 2: Remove methods from AbTopic**

  Remove from `AbTopic`:
  - `requestApproval:` (the 1-arg dispatcher)
  - `requestApproval:options:` (the old combined flow)

- [ ] **Step 3: Remove remaining old test methods from AbTopicTest**

  Verify that `testRequestApprovalTimesOutAndRejects`, `testRequestApprovalReturnsResolvedResponse`, `testRequestApprovalFromIdleTransitionsToDone`, `testRequestApprovalFromDoneTransitionsToWorking` are already gone (removed in Tasks 1–2). Remove any that remain.

- [ ] **Step 4: Import Core and Tests; run full suite**

  Import Core, Handler, UI, Tests. Run all tests — expect 0 failures.

- [ ] **Step 5: Commit**

  ```bash
  git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
  git commit -m "refactor: remove requestApproval: and requestApproval:options: from AbTopic"
  ```

---

### Task 6: Final import, full test run, export all packages

- [ ] **Step 1: Full import in dependency order**

  Import: `AgenticBrowser-Core` → `AgenticBrowser-Handler` → `AgenticBrowser-UI` → `AgenticBrowser-Tests`

- [ ] **Step 2: Run all package tests**

  Run tests on all four packages. Expect 0 failures.

- [ ] **Step 3: Export all packages**

  Export all four packages.

- [ ] **Step 4: Final git push**

  ```bash
  git push
  ```
