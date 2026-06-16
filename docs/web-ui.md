# Agentic Browser — Web UI

The Web UI provides a browser-based interface to Agentic Browser running inside a Pharo image. Multiple browser tabs can connect simultaneously; each tab sees live topic updates via WebSocket push.

## Architecture

```
Browser tab  ←──WebSocket──→  AbTopicManagerRipple (Pharo)
                                     │
                               AbTopicManager
                               AbTopic × N
```

`AbTopicManagerRipple` is a [Ripple](https://github.com/mumez/Ripple) room that handles one WebSocket connection per browser tab. It subscribes to all topic announcements on connect and broadcasts events (`messageAdded`, `statusChanged`, etc.) to every connected tab.

## Installation

### 1. Load the WebUI package

```smalltalk
Metacello new
    baseline: 'AgenticBrowser';
    repository: 'github://mumez/pharo-agentic-browser:main/src';
    load: 'WebUI'.
```

### 2. Build the client

```sh
git clone https://github.com/mumez/pharo-agentic-browser-web-ui
cd pharo-agentic-browser-web-ui
npm install
npm run build
```

### 3. Deploy client assets

`RpServer` serves static files from `<imageDir>/assets/` by default (overridable with the `PHARO_RIPPLE_ASSETS_DIR` environment variable).

The build outputs to `assets/agentic-browser/`. Symlink `assets` directory (recommended during development), or copy it:

```sh
# symlink
ln -s /path/to/pharo-agentic-browser-web-ui/assets /path/to/pharo/image/assets

# or copy
cp -r test-assets /path/to/pharo/image/assets
```

### 4. Start the server

```smalltalk
AgenticBrowser startWebUI
```

Open `http://yourhost:8080/assets/agentic-browser/` in a browser.

To change the port or bind address, configure `RpServerSettings` before starting:

```smalltalk
RpServer default settings port: 9090.
RpServer default settings bindAddress: #[0 0 0 0].  "listen on all interfaces"
AgenticBrowser startWebUI.
```

## Usage

### Topic list

The left panel lists all topics with their current status icons (matching the Spec2 UI):

| Icon | Status |
|------|--------|
| (blank) | `initial` |
| ❇️ | `working` |
| ? | `waitingForHuman` |
| ● | `endTurn` |
| ✓ | `goalAchieved` |

### Creating a topic

Click **+ New Topic**, enter a title, and optionally select an agent from the dropdown (populated from `AbSettings`). The topic appears in the list immediately. No working directory can be set from the browser — use an existing topic or set the directory via the Spec2 UI or the image Playground.

### Chat

Select a topic to open the chat pane. Messages are loaded in chunks. Type a prompt and press **Send**.

When the agent requests approval, the pending message shows action buttons (e.g. **Allow once** / **Deny**). Click a button to resolve the approval.

### Model and mode selection

Once an agent connects, dropdowns for model and mode appear in the toolbar. Selections are sent back to the agent.

### Multi-tab behavior

All tabs receive push events for all topics. If one tab creates, renames, or deletes a topic, other tabs receive a `topicsUpdated` publish and re-fetch the topic list. Tabs that were inactive (backgrounded) can call `/messages/getAll` after `statusChanged: endTurn` to catch up.

There is no exclusive locking — two tabs can send prompts to the same topic. This is intentional for the single-user scenario.

## WebSocket API

The full WebSocket API reference is in [web-ui-api.md](web-ui-api.md).

**Connection:**

```
ws://localhost:8080/ws/agentic-browser?token=<client-generated-uuid>
```

**Registration (send immediately after connect):**

```json
{ "type": "register", "address": "serverEventPushed" }
{ "type": "register", "address": "topicsUpdated" }
```

## Server Configuration

| Setting | Default | Override |
|---------|---------|---------|
| Port | `8080` | `RpServer default settings port: N` or `PHARO_RIPPLE_PORT` env |
| Bind address | `127.0.0.1` | `RpServer default settings bindAddress: #[0 0 0 0]` or `PHARO_RIPPLE_BIND_ADDRESS` env |
| Assets directory | `<imageDir>/assets` | `RpServer default settings assetsDir: '/my/path'` or `PHARO_RIPPLE_ASSETS_DIR` env |

## Stopping the server

```smalltalk
RpServer default stop.
```

## Related

- [web-ui-api.md](web-ui-api.md) — Full WebSocket API reference
- [pharo-agentic-browser-web-ui](https://github.com/mumez/pharo-agentic-browser-web-ui) — Client source
- [Ripple](https://github.com/mumez/Ripple) — WebSocket framework used by the server
