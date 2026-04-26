# pharo-agentic-browser

A GUI application inside the Pharo image for managing multiple AI agent work sessions as **topics**. It uses [pharo-acp](https://github.com/mumez/pharo-acp) (an ACP client library) as the backend and Spec2 for the UI.

## Overview

```
+---------------------+-------------------------------------------+
|   Topics            |  [Human] /st-buddy Add pagination to      |
|                     |          the user list                    |
|                     +-------------------------------------------+
|  ● DB Optimization  |  [AI] I'll add pagination. First, let     |
|  ⏸ UI Improvement   |       me check the current structure...   |
|  ✓ Fix Tests        |                                           |
|                     |  [System] UserList-Core was modified;     |
|  [+ New Topic]      |           .st files have been updated       |
|                     |  ⏸ [AI] May I modify DBAdapter#connect?   |
|                     |  [Human] yes                              |
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
- **Working directory management** — per-topic directory with one-click export/import/test via SisServer; supports custom paths for existing projects
- **Multiple package prefixes** — track multiple package families (e.g. `#('ACP-*' 'BaselineOfACP')`) per topic
- **Image change watching** — `AbTopicRelatedPackagesWatcher` monitors image changes, inserts system messages into chat, and asks for confirmation before adding untracked packages

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
2. Enter a title and select an agent
3. (Optional) Enter an existing project directory — package prefixes are auto-detected from `src/` subdirectories
4. Click **Create** — the topic appears in the left sidebar with `○` (idle)
5. Right-click the topic and choose **Set Target Packages...** to configure which packages to watch
6. Type a request and press **Send** — status changes to `●` (working)
7. When the AI requests permission, the input placeholder changes and status shows `⏸`
8. Type your response (e.g. `yes` / `no`) and press **Send**
9. The AI resumes; when finished, status changes to `✓` (done)

You can also right-click a topic to **Rename...** or **Delete** it.

> **Note:** The first message in each topic is automatically prefixed with `/st-buddy ` to activate the Smalltalk buddy agent mode.

### Image Change Watching

Watching starts automatically when a topic first connects (on the first **Send**). No manual setup is required.

To manually control watching if needed:

```smalltalk
"Start watching"
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
| `AgenticBrowser-Core` | Domain model: `AbTopic`, `AbTopicManager`, `AbMessage`, `AbWorkingDirectory`, `AbTopicRelatedPackagesWatcher`, announcements |
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

Each topic has a working directory at `~/agentic-browser/<safe-topic-name>-<uuid8>/`. The UUID suffix ensures stability even if the topic title changes. It wraps `SisServer` to export, import, and run tests for packages matching any of the topic's `packagePrefixes`:

```smalltalk
topic workingDirectory exportPackage: 'AgenticBrowser-Core'.
topic workingDirectory importPackage: 'AgenticBrowser-Core'.
topic workingDirectory runAllTests.
```

You can also set a custom working directory path when creating a topic from an existing project directory.

### Image Change Watcher (`AbTopicRelatedPackagesWatcher`)

`AbTopicRelatedPackagesWatcher` subscribes to `SystemAnnouncer` for `MethodAnnouncement` and `ClassAnnouncement`. When a method or class is saved:

- If the package matches any of the topic's `packagePrefixes`, it inserts a system message into the chat (e.g. `"AgenticBrowser-Core was modified; .st files have been updated"`) and exports the package
- If the package does **not** match, it shows a confirmation dialog asking whether to add the package to tracked prefixes
- Changes during import are suppressed to avoid re-export loops

## Related Projects

- [pharo-acp](https://github.com/mumez/pharo-acp) — ACP client library for Pharo
- [SState](https://github.com/mumez/SState) — Simple state machine library for Pharo
- [PharoSmalltalkInteropServer](https://github.com/mumez/PharoSmalltalkInteropServer) — HTTP API server for Pharo package import/export/test

## License

MIT
