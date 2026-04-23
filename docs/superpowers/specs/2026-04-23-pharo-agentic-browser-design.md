# pharo-agentic-browser Design Document

**Date**: 2026-04-23  
**Project**: pharo-agentic-browser  
**Backend**: [pharo-acp](https://github.com/mumez/pharo-acp)  
**Related skills**: [smalltalk-dev-plugin](https://github.com/mumez/smalltalk-dev-plugin)

---

## Overview

A GUI application inside the Pharo image that lets users manage multiple AI agent work sessions as "topics". It uses pharo-acp (an ACP client library) as the backend and Spec2 for the UI.

The core workflow:
1. User creates a topic and selects an ACP-compatible agent (Gemini CLI, Claude Code, etc.)
2. User types a request in the chat pane
3. AI starts working (task decomposition, code changes, tests)
4. When the AI needs human judgment, it pauses and asks in the chat
5. User responds in plain text; AI resumes
6. Topic status is always visible in the sidebar

---

## UI Design

### Layout: Two-pane (horizontal split)

```
+---------------------+-------------------------------------------+
|   Topics            |  DB Optimization                          |
|                     |                                           |
|  ● DB Optimization  |  AI: Found QueryClass and DBAdapter.      |
|  ⏸ UI Improvement   |      Starting export and work.            |
|  ✓ Fix Tests        |                                           |
|                     |  AI: Fixed N+1 issue.                     |
|                     |  ⏸ May I modify DBAdapter#connect?        |
|  [+ New Topic]      |  > User input...                          |
+---------------------+-------------------------------------------+
```

- **Left pane**: topic list with status icons + New Topic button
- **Right pane**: chat history for the selected topic + input field

### Topic Status Icons

| Symbol | Icon | Meaning |
|--------|------|---------|
| `#idle` | ○ | Not started |
| `#working` | ● | AI is working |
| `#waitingForHuman` | ⏸ | Waiting for human judgment |
| `#done` | ✓ | Finished |

### Human-in-the-Loop UI (Conversation-style)

When the AI needs approval, it asks inside the chat. The user responds via the normal input field — no modal dialogs or inline buttons. While waiting for a response, the input field placeholder text changes to indicate the approval context.

---

## Package Structure

| Package | Contents |
|---------|---------|
| `AgenticBrowser-Core` | Domain model (AbTopic, AbTopicManager, AbMessage) |
| `AgenticBrowser-Handler` | ACP callback handler (AbTopicHandler) |
| `AgenticBrowser-UI` | Spec2 presenters |
| `BaselineOfAgenticBrowser` | Metacello baseline |

Class prefix: **`Ab`**

---

## Domain Layer (AgenticBrowser-Core)

### AbTopicManager

Image-level singleton. Manages the collection of topics. Because it lives in the Pharo image, the topic list (including chat history and status) is preserved across sessions by saving the image.

```smalltalk
AbTopicManager class >> uniqueInstance
AbTopicManager >> topics          "OrderedCollection of AbTopic"
AbTopicManager >> addTopic: anAbTopic
AbTopicManager >> removeTopic: anAbTopic
AbTopicManager >> topicsDo: aBlock
```

### AbTopic

Represents one topic. Holds an ACP client session and a SState state machine.

**Instance variables:**

| Variable | Type | Description |
|----------|------|-------------|
| `title` | String | Topic title |
| `agentCommand` | Array | Agent launch command (e.g. `#('claude-agent-acp')`) |
| `messages` | OrderedCollection | Chat messages (AbMessage) |
| `client` | ACPClient | Non-nil only while connected |
| `sessionId` | String | ACP session ID |
| `stateMachine` | SsStateMachine | State management |
| `watchedPackages` | OrderedCollection | Package names to watch for changes (Phase 2) |

**State transitions (SState):**

```
#idle ──promptSent──▶ #working ──permissionRequested──▶ #waitingForHuman
                          ▲                                      │
                          └──────────humanResponded──────────────┘
                          │
                       ended
                          │
                          ▼
                        #done ──promptSent──▶ #working
```

SState configuration:

```smalltalk
initializeStateMachine
    stateMachine := SsStateMachine new.
    (stateMachine addStateNamed: #idle)
        when: #promptSent to: #working.
    (stateMachine addStateNamed: #working)
        entryAction: [ self announceStatusChanged ];
        when: #permissionRequested to: #waitingForHuman;
        when: #ended to: #done.
    (stateMachine addStateNamed: #waitingForHuman)
        entryAction: [ self announceStatusChanged ];
        when: #humanResponded to: #working.
    (stateMachine addStateNamed: #done)
        entryAction: [ self announceStatusChanged ];
        when: #promptSent to: #working.
    stateMachine setStartStateTo: #idle.
    stateMachine start.
```

**Key methods:**

```smalltalk
AbTopic >> status                    "^ stateMachine currentState name"
AbTopic >> sendPrompt: aString
AbTopic >> resolveApproval: aString  "Parse user text, set approvalResponse, signal semaphore"
AbTopic >> addAiTextChunk: aString
AbTopic >> addApprovalRequest: aDescription  "^ AbMessage with approvalSemaphore"
AbTopic >> disconnect
```

### AbMessage

One chat message.

| Variable | Type | Description |
|----------|------|-------------|
| `sender` | Symbol | `#human / #ai / #system` |
| `text` | String | Message text |
| `timestamp` | DateAndTime | When the message was sent/received |
| `isApprovalRequest` | Boolean | Whether this message requires a human response |
| `approvalSemaphore` | Semaphore | Non-nil only while waiting for approval |
| `approvalResponse` | Symbol | `#allow / #deny / #allowAlways` (set by UI before signal) |

---

## Handler Layer (AgenticBrowser-Handler)

### AbTopicHandler

Subclass of `ACPClientHandler`. One handler per topic.

**Streaming AI output:**

```smalltalk
sessionUpdate: anACPSessionUpdate
    (anACPSessionUpdate isAgentMessageChunk
        or: [ anACPSessionUpdate isAgentThoughtChunk ]) ifFalse: [ ^ self ].
    topic addAiTextChunk: anACPSessionUpdate content text.
```

**Permission request (conversation-style, Semaphore block):**

```smalltalk
requestPermission: anACPRequestPermission
    | msg |
    msg := topic addApprovalRequest: anACPRequestPermission description.
    topic stateMachine handleEvent: #permissionRequested.
    msg approvalSemaphore wait.    "blocks handler thread until UI signals"
    ^ msg approvalResponse asACPPermissionResponse
```

---

## UI Layer (AgenticBrowser-UI)

### AbBrowserPresenter

Main window. References `AbTopicManager` and manages the two-pane layout.

```smalltalk
AbBrowserPresenter class >> open
AbBrowserPresenter >> initializePresenters   "builds topicList + chat panes"
AbBrowserPresenter >> selectedTopicChanged: anAbTopic
```

### AbTopicListPresenter

Left sidebar. `SpListPresenter`-based with status icons.

```smalltalk
AbTopicListPresenter >> refresh              "redraw topic list"
AbTopicListPresenter >> onNewTopicRequest    "open AbNewTopicDialog"
```

Topic status changes arrive via `Announcements` and trigger a list refresh.

### AbChatPresenter

Right chat pane. Displays messages for the selected topic and handles input.

```smalltalk
AbChatPresenter >> topic: anAbTopic         "switch display target"
AbChatPresenter >> appendMessage: anAbMessage
AbChatPresenter >> onSendInput: aString
AbChatPresenter >> enterApprovalMode: anAbMessage   "update inputField placeholder"
AbChatPresenter >> exitApprovalMode
```

**Approval flow (UI side):**

```
1. AbTopicHandler calls addApprovalRequest:
2. AbMessage(isApprovalRequest: true) is added to topic messages
3. AbChatPresenter receives notification → displays message + enterApprovalMode:
4. User types response → sendButton
5. AbChatPresenter → topic resolveApproval: userText
6. topic resolveApproval: sets approvalResponse and signals approvalSemaphore
7. AbTopicHandler wait: unblocked → returns approvalResponse
8. stateMachine handleEvent: #humanResponded → transitions back to #working
```

### AbNewTopicDialog

Topic creation dialog.

- Title input field
- Agent selection: `claude-agent-acp` / `gemini --acp` / `opencode acp` / `copilot --acp --stdio` / `codex-acp` / custom

---

## Announcements

| Announcement | Publisher | Subscribers |
|---|---|---|
| `AbTopicStatusChanged` | `AbTopic` | `AbTopicListPresenter`, `AbChatPresenter` |
| `AbMessageAdded` | `AbTopic` | `AbChatPresenter` |

---

## Phase 2: Image Watch Mechanism (AbImageWatcher)

Detects when the user edits source directly inside the Pharo image (outside the AI workflow) and triggers a re-export of the affected packages.

### Approach A: SystemAnnouncer (event-driven)

Subscribe to `SystemAnnouncer uniqueInstance` for:

- Method changes: `MethodAdded`, `MethodModified`, `MethodRemoved`
- Class changes: `ClassAdded`, `ClassModified`, `ClassRemoved`, `ClassRenamed`

When the changed class belongs to a package listed in `AbTopic >> watchedPackages`, trigger re-export.

**Pros**: Real-time detection  
**Cons**: Many event types to subscribe to

### Approach B: MCWorkingCopy Polling

```smalltalk
MCWorkingCopy registry asArray
    select: [ :e | e modified ]
```

Gets modified working copies; use `package name` to identify changed packages.

**Pros**: Simple implementation  
**Cons**: Requires a polling interval. Monticello is considered legacy in Pharo, so long-term viability is uncertain.

Both approaches share the `AbTopic >> watchedPackages` design. The implementation choice is deferred to Phase 2.

---

## Phase 2: Working Directory Management

- AI identifies relevant existing packages from the user's request
- Exports those packages to a topic-specific directory (Tonel format)
- AI works on the exported files
- AI imports them back into Pharo and runs tests

Export/import uses the smalltalk-dev-plugin skills (`/st-export`, `/st-import`).

---

## Dependencies

| Library | Purpose |
|---------|---------|
| pharo-acp | ACP client (connection, session, prompt) |
| SState | Topic state machine |
| Spec2 | UI framework (Pharo built-in) |

---

## Implementation Phases

### Phase 1 (current)

1. `AgenticBrowser-Core`: AbTopicManager / AbTopic (with SState) / AbMessage
2. `AgenticBrowser-Handler`: AbTopicHandler
3. `AgenticBrowser-UI`: AbBrowserPresenter / AbTopicListPresenter / AbChatPresenter / AbNewTopicDialog
4. `BaselineOfAgenticBrowser`

### Phase 2 (future)

- AbImageWatcher (change detection)
- Working directory management (package export/import workflow)
