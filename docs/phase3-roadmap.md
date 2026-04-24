# Phase 3 Roadmap Ideas

Candidate features for the next phase, noted after Phase 2 completion (2026-04-24).

---

## 1. Session Persistence

Save and restore topic sessions to a file, independent of Pharo image save.

**Motivation:** Image save is coarse-grained and image-specific. File-based persistence allows backup, sharing sessions across images, and recovery from image crashes.

**Options:**
- **Fuel** (preferred) — Pharo's built-in binary serializer; handles object graphs natively with minimal setup
- **STON** — human-readable Smalltalk object notation; good if inspectability matters
- **JSON** — widest interoperability, but requires custom mapping; user notes this need is low

**Sketch:**
```smalltalk
"Save"
AbTopicManager uniqueInstance saveSessionTo: '/path/to/session.fuel'.

"Restore"
AbTopicManager loadSessionFrom: '/path/to/session.fuel'.
```

---

## 2. Code Mentions in Chat (@Class / @Class>>method)

Allow chat input to reference Pharo classes or methods inline:

```
@QueryClass @DBAdapter>>connect please refactor this
```

The referenced class definition or method source is attached as ACP **text resources** alongside the prompt, giving the AI agent precise code context without copy-paste.

**Implementation sketch:**
- Parse `@Foo` and `@Foo>>bar` tokens in `AbChatPresenter` before sending
- Resolve via `Smalltalk globals` / `RPackageOrganizer`
- Attach resolved source as ACP text resources in `AbTopic>>sendPrompt:`

---

## 3. Screenshot Attachment

Select a Pharo window and send its screenshot to the AI agent as an ACP **binary resource**.

**Motivation:** Visual context (UI bugs, unexpected output) is often the fastest way to communicate a problem to the AI.

**Implementation sketch:**
- Add a window-picker UI (list of open windows/morphs)
- Capture via `Display screenshot` or morph rendering
- Encode as PNG
- Attach as ACP binary resource in the prompt
