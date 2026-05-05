# AGENTS.md

## Cursor Cloud specific instructions

This is a **pure Pharo Smalltalk** project (no npm/pip/Makefile/Docker). The entire lifecycle — dependency loading, compilation, testing, and running — happens inside a **Pharo VM/image** managed by [smalltalkCI](https://github.com/hpi-swa/smalltalkCI).

### Running tests

```bash
export PATH="/opt/smalltalkCI/bin:$PATH"
cd /workspace && smalltalkci -s Pharo64-13 .smalltalk.ston
```

This downloads/caches a Pharo 13 image + VM, loads the project and all Metacello dependencies from GitHub, and runs the full SUnit test suite (137 tests). The first run takes ~20s; subsequent cached runs are faster.

### Evaluating Smalltalk expressions headlessly

After a successful `smalltalkci` run, a built image exists under `/opt/smalltalkCI/_builds/*/TravisCI.image`. Use the cached VM to evaluate arbitrary Smalltalk:

```bash
BUILD_DIR=$(ls -d /opt/smalltalkCI/_builds/*/ | head -1)
PHARO="/opt/smalltalkCI/_cache/vms/Pharo64-13/pharo"
"$PHARO" --headless "${BUILD_DIR}TravisCI.image" eval "<your Smalltalk expression>"
```

### Headless investigation via REST (PharoSmalltalkInteropServer / SisServer)

For Cloud/headless debugging, it is often easier to inspect the image through REST endpoints than repeatedly running one-off `eval` snippets.

This project already loads `PharoSmalltalkInteropServer` as a baseline dependency, so you can use `SisServer` directly:

```bash
BUILD_DIR=$(ls -d /opt/smalltalkCI/_builds/*/ | head -1)
PHARO="/opt/smalltalkCI/_cache/vms/Pharo64-13/pharo"

# First, check whether SisServer is already reachable (usually auto-started)
curl "http://localhost:8086/list-packages"

# If curl fails, start it explicitly and retry
"$PHARO" --headless "${BUILD_DIR}TravisCI.image" eval "SisServer current start"
curl "http://localhost:8086/list-packages"

# examples
curl "http://localhost:8086/search-classes-like?class_name_query=AbMessagesPresenter"
curl -X POST "http://localhost:8086/eval/" \
  -H "Content-Type: application/json" \
  -d '{"code":"AbMessagesPresenter selectors"}'
```

Avoid calling `start` unconditionally; if the server is already running, unnecessary starts can trigger port conflicts.

When done (only if you explicitly started it for this session):

```bash
"$PHARO" --headless "${BUILD_DIR}TravisCI.image" eval "SisServer current stop"
```

Reference: https://github.com/mumez/PharoSmalltalkInteropServer

### Key gotchas

- **No `addHumanMessage:`** — to add a human message manually use `AbMessage sender: #human text: '...'` and add it to `topic messages`. The real entry point for sending a prompt is `topic sendPrompt:` which also connects to an ACP agent.
- **`agentArguments:` not `agentName:`** — `AbTopic` stores agent CLI args as an array (e.g. `#('gemini' '--acp')`), not a name string.
- **GUI requires X11/display** — `AbBrowserPresenter open` needs a display server. In headless Cloud Agent VMs, test domain logic via `eval` instead.
- **smalltalkCI is installed at `/opt/smalltalkCI`** — added to `PATH` via the update script; no need to reinstall.
- **Test isolation** — use `AbTopicManager forTest` (not `default`) to avoid polluting the singleton.
