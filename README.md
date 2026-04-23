# pharo-agentic-browser

A GUI application inside the Pharo image for managing multiple AI agent work sessions as **topics**. It uses [pharo-acp](https://github.com/mumez/pharo-acp) (an ACP client library) as the backend and Spec2 for the UI.

## Overview

```
+---------------------+-------------------------------------------+
|   Topics            |  DB Optimization                          |
|                     |                                           |
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
2. Enter a title and select an agent from the dropdown
3. Click **Create** — the topic appears in the left sidebar with `○` (idle)
4. Type a request and press **Send** — status changes to `●` (working)
5. When the AI requests permission, the input placeholder changes and status shows `⏸`
6. Type your response (e.g. `yes` / `no`) and press **Send**
7. The AI resumes; when finished, status changes to `✓` (done)

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
| `AgenticBrowser-Core` | Domain model: `AbTopic`, `AbTopicManager`, `AbMessage`, announcements |
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

## Related Projects

- [pharo-acp](https://github.com/mumez/pharo-acp) — ACP client library for Pharo
- [SState](https://github.com/mumez/SState) — Simple state machine library for Pharo
- [PharoSmalltalkInteropServer](https://github.com/mumez/PharoSmalltalkInteropServer) — HTTP API server for Pharo package import/export/test

## License

MIT
