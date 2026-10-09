# Spec: Start crit from working directories without `.crit.config.json`

Source: Kanban-lo issue `1791551477041-configがない既存のworkingdirectoryからもcritを起動できるようにする`

## Objective

Today the "Review by crit" control is shown only when the topic's working directory already
contains `.crit.config.json` with a valid port (`AbCritDaemon >> unavailableReason` returns
`'no crit port assigned'` otherwise). The port is assigned only when `AbWorkingDirectory >> ensureExists`
creates a brand-new directory. Directories that existed before crit support, were created while
`useCrit` was false, or were reused through `/topics/create`, therefore cannot start crit unless
the user writes the config by hand.

After this change:

- The control depends only on `useCrit` and `.git`.
- The port is decided when crit is started, not when the directory is created.
- Ports are recycled: only topics whose crit daemon is actually running hold a port.

Users: Pharo UI (topic list context menu) and Web UI (`critReviewAvailable`, `/crit/start`).

## Behavior

### Availability (`AbCritDaemon >> unavailableReason`)

| Condition | Reason string |
|---|---|
| `AbSettings default useCrit` is false | `useCrit is false` |
| working directory has no `.git` | `working directory has no .git` |
| otherwise | `nil` (available) |

`refusalReasonOnStart` keeps `topic status is initial` as an additional refusal.
The reason `no crit port assigned` is removed.

### Start (`AbCritDaemon >> startReviewForHost:ifStarted:ifFailed:`)

1. Validate host (unchanged). Check `refusalReasonOnStart` (unchanged).
2. Inside the crit start mutex (see Concurrency):
   1. Ask whether this topic's daemon is running (`isDaemonRunning`).
      - Status error → fail `crit status failed (is crit on PATH?)` (unchanged).
      - Running → reuse the daemon. Do not inspect or rewrite the port. Report the URL (unchanged).
   2. Not running → ensure a usable port:
      - Collect **used ports** = ports read from `.crit.config.json` of every *other* topic in the
        topic manager whose crit daemon is running (`topic critDaemon isDaemonRunning`).
        A topic whose status check raises an error counts as not running.
      - If this directory's config has a valid port that is not in used ports → keep it, no write.
      - Otherwise pick the lowest port in `AbSettings default critPortInterval` not in used ports and
        write it. If the file is missing or unreadable, create it from
        `AbCritConfigFile class >> defaultContents`. Other keys of an existing file are preserved.
      - `critPortInterval` is nil → fail `invalid critPortRange: <range>`.
      - No free port → fail `crit port range exhausted: <low>-<high>`.
   3. Spawn crit and wait until running (unchanged command, polling, and 10 s limit).
      - Timeout → fail with a message that names the port and the likely cause:
        `crit did not start within 10 seconds on port <port> (the port may be in use by another process)`.
   4. Post `Crit review: <url>` and call `ifStarted:` with url and port (unchanged).
3. All failures go through the existing `fail:with:` path (system message with log path, logger warn,
   `ifFailed:` → `critReviewFailed` push). The button / menu item stays enabled, so the user can retry.

Port values are read from the file at start time, not from a value cached before the start.

### Working directory creation

`AbWorkingDirectory >> ensureExists` no longer calls `AbCritConfigFile assignPortIn:`.
Copying the topic template (which may contain `.crit.config.json` with `port: 0`) is unchanged.

### Concurrency

Two different topics starting at the same time must not get the same port. Because a port is only
"used" once its daemon is running, port selection and spawn+wait must be serialized together.
Decision: one class-level mutex in `AbCritDaemon` covering steps 2.1–2.3 for **all** directories.
It replaces both the per-directory `launchMutexes` and `AbCritConfigFile`'s `PortAssignmentMutex`.
Starts are rare and user-initiated, so serializing them (worst case 10 s each) is acceptable.

### Out of scope

- Stopping crit, or detecting crit daemons started outside AgenticBrowser in directories that no topic owns.
- Probing whether a port is bound at the OS level before spawning.
- Caching daemon status across starts. (Allowed later if the per-topic `crit status` cost is a problem.)
- Web UI client code changes beyond what follows from `critReviewAvailable` changing value.

## Tech Stack

Pharo 13/14, Tonel sources under `src/`, SUnit, Spec2 (UI), Ripple (WebUI), `crit` CLI on PATH,
`OSSUnixSubprocess` for shell commands.

## Commands

Development runs against a live Pharo image through the smalltalk-interop MCP tools:

- Import: `import_package` with the absolute path of `src/` and the package name
  (`AgenticBrowser-Core`, `AgenticBrowser-Tests`, `AgenticBrowser-UI`, `AgenticBrowser-WebUI`,
  `AgenticBrowser-WebUI-Tests`)
- Test: `run_class_test` for `AbCritDaemonTest`, `AbCritConfigFileTest`, `AbWorkingDirectoryTest`,
  `AbTopicListPresenterTest`, `AbTopicManagerRippleTest`; then `run_package_test` for
  `AgenticBrowser-Tests` and `AgenticBrowser-WebUI-Tests`
- Lint: `lint_tonel_smalltalk_from_file` on every changed `.st` file

## Project Structure

| Path | Change |
|---|---|
| `src/AgenticBrowser-Core/AbCritDaemon.class.st` | availability rule, start flow, port selection call, single mutex, timeout message, class comment |
| `src/AgenticBrowser-Core/AbCritConfigFile.class.st` | used ports = running topics only; drop `PortAssignmentMutex`; keep `writePort:` / `defaultContents`; class comment |
| `src/AgenticBrowser-Core/AbWorkingDirectory.class.st` | remove port assignment from `ensureExists`; class comment |
| `src/AgenticBrowser-Tests/AbCritDaemonTest.class.st`, `AbStubCritDaemon.class.st` | new and updated tests; stub per-topic running state |
| `src/AgenticBrowser-Tests/AbCritConfigFileTest.class.st`, `AbWorkingDirectoryTest.class.st` | update for the new rules |
| `src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st`, `src/AgenticBrowser-WebUI-Tests/AbTopicManagerRippleTest.class.st` | availability without config |
| `docs/web-ui-api.md` | `/crit/start` reason list, failure reasons |

`AbTopicListPresenter` and `AbTopicManagerRipple` need no code change; they already ask
`critDaemon isAvailable` / `refusalReasonOnStart`.

## Code Style

Follow the existing crit code and the `smalltalk-developer` style guide: intention-revealing names, no
`set` prefixes, accessors in `accessing`, CRC class comments updated with the behavior. Example of
the existing tone:

```smalltalk
unavailableReason

	AbSettings default useCrit ifFalse: [ ^ 'useCrit is false' ].
	(self directory / '.git') exists ifFalse: [ ^ 'working directory has no .git' ].
	^ nil
```

## Testing Strategy

TDD with SUnit; tests extend `AbTestCase` and never spawn crit (`AbStubCritDaemon` overrides
`runShellCommand:`). Other topics' running state is injected via `AbTopicSession >> critDaemon:`.

Required test cases:

1. Available with `useCrit` true and `.git`, without `.crit.config.json`.
2. Unavailable when `useCrit` is false / no `.git` (existing, kept).
3. Start without config → file created from defaults with the lowest free port; started callback gets that port.
4. Start with a valid config port not used by a running topic → port kept, file not rewritten.
5. Start with a config port used by another topic whose daemon is running → reassigned to a free port; other keys preserved.
6. A topic with an assigned port whose daemon is not running does not block that port.
7. Own daemon already running → no port rewrite, no spawn, started callback with the existing port.
8. No free port → `ifFailed:` with `crit port range exhausted: ...`; no spawn.
9. Invalid `critPortRange` → `ifFailed:` with `invalid critPortRange: ...`; no spawn.
10. Spawn timeout → `ifFailed:` message contains the port and `may be in use by another process`.
11. `ensureExists` on a new directory does not write a port.
12. Ripple: `critReviewAvailable` is true for a `.git` directory without config; `/crit/start` no longer
    rejects with `no crit port assigned`.
13. Pharo UI: "Review by crit" item appears for a `.git` directory without config.

## Boundaries

- Always: write the failing test first; lint and import changed packages; run the listed test classes and both test packages before reporting done; update class comments and `docs/web-ui-api.md` to match.
- Ask first: changing the `crit` spawn command or its flags; adding a daemon-status cache; touching Web UI client (JS) code; changing Ripple error codes.
- Never: spawn a real crit process in tests; stop or kill running crit daemons; modify unrelated topic-list or Ripple behavior.

## Success Criteria

- A topic whose working directory has `.git` but no `.crit.config.json` shows "Review by crit" (Pharo) and `critReviewAvailable: true` (Web UI) when `useCrit` is true.
- Starting crit there creates `.crit.config.json` with a port from `critPortRange` that no running topic uses, and the review URL uses that port.
- Starting crit for a topic whose configured port is held by another running topic moves it to a free port.
- Port-range exhaustion, an invalid range, and a spawn timeout each produce a `critReviewFailed` / system message with the reasons above, and the user can retry.
- All tests in `AgenticBrowser-Tests` and `AgenticBrowser-WebUI-Tests` pass.

## Open Questions

None.
