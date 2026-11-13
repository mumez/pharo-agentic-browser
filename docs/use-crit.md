# Code Review with crit

## What is crit?

[crit](https://github.com/tomasz-tomczyk/crit) is a local tool for reviewing the changes made by AI coding agents in a web browser. You comment on specific lines, and the agent receives those comments and can reply to them.

AgenticBrowser starts crit for you from a topic's menu (or a button in the Web UI), and the agent's work on your comments flows into the topic's conversation.

## Installation

Install the `crit` command and make sure it is on your `PATH`. For example:

```bash
# Homebrew
brew install crit

# Go
go install github.com/tomasz-tomczyk/crit/cmd/crit@latest
```

See the [crit repository](https://github.com/tomasz-tomczyk/crit) for other options, including prebuilt binaries.

crit review is disabled by default. To enable it, check **Use crit review** in the Settings dialog (or set `useCrit` to `true` in `ab-settings.json`). See [Settings](../README.md#settings) for the other crit settings.

## Review Flow

### 1. Start the review

The topic's working directory must be a git repository. When the agent's turn has ended, right-click the topic and choose **Review by crit**. The item is disabled while the agent is working.

![Review by crit in the topic's context menu](screenshots/crit/review-by-crit-menu.png)

### 2. Add comments

crit opens in your web browser. Review the changed files and add comments to the relevant lines.

![Adding a comment in crit](screenshots/crit/crit-add-comment.png)

### 3. Send the review to the agent

Press **Finish Review**. AgenticBrowser sends your review to the topic's agent once its turn has ended (it checks every `monitoringIntervalSeconds`).

The first time, crit asks you to trust the project's hooks. AgenticBrowser needs these hooks to receive the review result. Usually, choose **Trust until prompts change**.

![crit asking to trust the project's prompts](screenshots/crit/crit-trust-project-prompts.png)

### 4. Check the agent's response

The agent's replies to your comments appear in crit, and the changes are shown as a new review round.

![The agent's reply to a comment in crit](screenshots/crit/crit-codex-reply.png)

If more changes are needed, add comments and press **Finish Review** again.

### 5. Approve the review

When you are satisfied, approve the review. Once crit shows **Approved**, you can close the browser tab.

![The approved review in crit](screenshots/crit/crit-approved.png)

### 6. Resume the conversation

The agent's response to the review is also shown in the topic's conversation in AgenticBrowser. You can continue the conversation from there.

![The review result in the topic's conversation](screenshots/crit/review-session-done.png)

## Notes

- AgenticBrowser adds `on_finish_unresolved` / `on_finish_approved` hooks to the working directory's `.crit.config.json`. If the file already defines its own hook for either of them, AgenticBrowser leaves it unchanged and does not deliver the first result.
- AgenticBrowser delivers only the first Finish after a review starts. The hook saves the result under `<imageDir>/agentic-browser/_crit-results/`, and the prompt sent to the agent ends with `crit --session <id>`, so the agent receives later rounds from crit itself.

## Upgrading from v1.9.1 or earlier

In v2.0.0, AgenticBrowser's internal crit directories were renamed with a `_` prefix: `crit-results` became `_crit-results`, and `crit-logs` became `_crit-logs`.

- **Hooks**: A `.crit.config.json` written by an earlier version still has hooks that point to `<imageDir>/agentic-browser/crit-results/`. AgenticBrowser treats them as your own hooks, so it leaves them unchanged and does not deliver the review result. In each working directory, either change `crit-results` to `_crit-results` in the `on_finish_unresolved` / `on_finish_approved` paths, or, if the file has no settings of your own, delete `.crit.config.json` so that AgenticBrowser creates it again on the next review.
- **Old directories**: `<imageDir>/agentic-browser/crit-results/` is no longer used, so delete it. `<imageDir>/agentic-browser/crit-logs/` can stay, but new logs go to `_crit-logs/`.
