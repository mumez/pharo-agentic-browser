# pharo-agentic-browser

A GUI application inside the Pharo image for managing multiple AI agent work sessions as **topics**. It uses [pharo-acp](https://github.com/mumez/pharo-acp) (an ACP client library) as the backend and Spec2 for the UI.

## Overview

```
+---------------------+-------------------------------------------+
|   Topics            |  ~/agentic-browser/DB-Optimization  ↑ ↓ ▶ |
|                     +-------------------------------------------+
|  ● DB Optimization  |  AI: Found QueryClass and DBAdapter.      |
|  ⏸ UI Improvement   |      Starting export and work.            |
|  ✓ Fix Tests        |                                           |
|                     |  AI: Fixed N+1 issue.                     |
|  [+ New Topic]      |  ⏸ May I modify DBAdapter#connect?        |
|                     |  > User input...                          |
+---------------------+-------------------------------------------+
```

The core workflow:
1. Create a topic and select an ACP-compatible agent (Gemini CLI, Claude Code, OpenCode, etc.)
2. Type a request in the chat pane
3. The AI starts working (task decomposition, code changes, tests)
4. When the AI needs human judgment, it pauses and asks in the chat
5. Respond in plain text — the AI resumes
6. Topic status is always visible in the sidebar

## Features

- **Multi-topic management** — run multiple AI agent sessions in parallel
- **Status tracking** — per-topic state machine (`idle → working → waitingForHuman → done`)
- **Human-in-the-loop** — conversation-style approval flow (no modal dialogs)
- **Agent-agnostic** — works with any ACP-compatible agent
- **Image persistence** — topic history and state survive Pharo image save/restore
- **Working directory management** — per-topic directory with one-click export/import/test via SisServer
- **Image change watching** — auto re-exports watched packages when you edit code in the Pharo image

## Requirements

- [Pharo](https://pharo.org/) 12+
- [pharo-acp](https://github.com/mumez/pharo-acp)
- [SState](https://github.com/mumez/SState)
- [PharoSmalltalkInteropServer](https://github.com/mumez/PharoSmalltalkInteropServer)
- At least one ACP-compatible agent installed (e.g. `claude-agent-acp`, `gemini --acp`)

## Installation

In a Pharo 12 image, open a Playground and evaluate:

```smalltalk
Metacello new
    baseline: 'AgenticBrowser';
    repository: 'github://mumez/pharo-agentic-browser:main/src';
    load.
```

To also load the test suite:

```smalltalk
Metacello new
    baseline: 'AgenticBrowser';
    repository: 'github://mumez/pharo-agentic-browser:main/src';
    load: 'Tests'.
```

## Usage

Open the browser window:

```smalltalk
AbBrowserPresenter open.
```

1. Click **+ New Topic**
2. Enter a title, select an agent, and optionally select packages to watch
3. Click **Create** — the topic appears in the left sidebar with `○` (idle)
4. Type a request and press **Send** — status changes to `●` (working)
5. When the AI requests permission, the input placeholder changes and status shows `⏸`
6. Type your response (e.g. `yes` / `no`) and press **Send**
7. The AI resumes; when finished, status changes to `✓` (done)

### Working Directory Toolbar

When a topic has watched packages, the chat pane shows a toolbar with:

- **Path label** — working directory (`~/agentic-browser/<topic-name>/`)
- **↑ Export** — export watched packages from the image to the working directory
- **↓ Import** — import packages from the working directory into the image
- **▶ Tests** — run tests for watched packages and show results in chat

### Image Change Watching

Enable automatic re-export whenever you edit code in the Pharo image:

```smalltalk
"Start watching (re-exports on every method/class save)"
AbTopicManager uniqueInstance topics first startWatching.

"Stop watching"
AbTopicManager uniqueInstance topics first stopWatching.
```

## Supported Agents

| Agent | Arguments |
|-------|-----------|
| Claude Code | `claude-agent-acp` |
| Gemini CLI | `gemini --acp` |
| OpenCode | `opencode acp` |
| GitHub Copilot CLI | `copilot --acp --stdio` |
| Codex | `codex-acp` |

## Package Structure

| Package | Contents |
|---------|----------|
| `AgenticBrowser-Core` | Domain model: `AbTopic`, `AbTopicManager`, `AbMessage`, `AbWorkingDirectory`, `AbImageWatcher`, announcements |
| `AgenticBrowser-Handler` | ACP callback bridge: `AbTopicHandler` |
| `AgenticBrowser-UI` | Spec2 presenters: browser, topic list, chat, new-topic dialog |
| `AgenticBrowser-Tests` | SUnit tests for Core |
| `BaselineOfAgenticBrowser` | Metacello baseline |

## Architecture

### State Machine (SState)

Each topic has an FSM with four states:

```
#idle ──promptSent──▶ #working ──permissionRequested──▶ #waitingForHuman
                          ▲                                      │
                          └──────────humanResponded──────────────┘
                          │
                       ended
                          ▼
                        #done ──promptSent──▶ #working
```

### Human-in-the-Loop Approval

When the AI requests permission, `AbTopicHandler#requestPermission:` blocks its thread on a `Semaphore`. The UI enters approval mode (placeholder text changes). When the user submits a response, `AbTopic#resolveApproval:` fires the `#humanResponded` event and signals the semaphore, unblocking the handler thread.

### Working Directory (`AbWorkingDirectory`)

Each topic has a working directory at `~/agentic-browser/<safe-topic-name>/`. It wraps `SisServer` to export, import, and run tests for a named package:

```smalltalk
topic workingDirectory exportPackage: 'AgenticBrowser-Core'.
topic workingDirectory importPackage: 'AgenticBrowser-Core'.
topic workingDirectory runAllTests.
```

### Image Change Watcher (`AbImageWatcher`)

`AbImageWatcher` subscribes to `SystemAnnouncer` for `MethodAnnouncement` and `ClassAnnouncement`. When a method or class in a watched package is saved, it forks a call to `workingDirectory exportPackage:`, keeping the working directory in sync automatically.

## Related Projects

- [pharo-acp](https://github.com/mumez/pharo-acp) — ACP client library for Pharo
- [SState](https://github.com/mumez/SState) — Simple state machine library for Pharo
- [PharoSmalltalkInteropServer](https://github.com/mumez/PharoSmalltalkInteropServer) — HTTP API server for Pharo package import/export/test

## License

MIT
