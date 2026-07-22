# Skills

Agent skills for use with coding agents (Claude Code, etc.) by anyone who has AgenticBrowser installed in their Pharo image, to help build features in their own project using AgenticBrowser's Scripting DSL.

## ab-scripting-feature-dev

Turns a feature request into a runnable AgenticBrowser [Scripting DSL](../docs/scripting.md) orchestration targeting the user's own project. It plans the work (if needed), follows TDD for implementation, adds a test phase, and adds a lint/style-guide review pass. The generated orchestration is previewed as `docs/scripting-features/feature-<name>.scripting.md` before anything runs, and only executes against the target codebase (via `st-eval`) after explicit user approval.

Use it whenever you want to build or automate a feature in your own project "using the scripting DSL", or to orchestrate coding agents (Claude, Codex, etc.) to implement something end-to-end via AgenticBrowser.

### Installation

The easiest way to install is with the [GitHub CLI `gh skill install`](https://cli.github.com/) command:

```
gh skill install mumez/pharo-agentic-browser ab-scripting-feature-dev
```

For Claude Code with a user-scoped install:

```
gh skill install mumez/pharo-agentic-browser ab-scripting-feature-dev --agent claude-code --scope user
```
