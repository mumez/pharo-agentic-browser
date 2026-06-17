## Scripting API for Dynamic Multi-Topic Orchestration in AgenticBrowser

### Goal

Enable AI agents to programmatically create and coordinate multiple topics without a UI (headless usage).

### Example Usage (executed via `st-eval`)

```smalltalk
orchestration := AbTopicOrchestration build: [:builder |
	builder seq: {
		builder topicBy: [:t | t title: 'Create plan of feature XXX'].
		builder topicBy: [:t | t title: 'Create spec of feature XXX']
	} with: builder agentBy: [:a | a claude; planMode ];
	para: {
		builder topicBy: [:t | t title: 'Implement feature XXX'].
		builder topicBy: [:t | t title: 'Write tests feature XXX'; goal: 'pass all tests']
	} with: builder agent codex;
	seq: {
		builder topicBy: [:t | t title: 'Review implementation of XXX']
		builder topicBy: [:t | t title: 'create PR of XXX']
	}
].
orchestration run.
```

### Notes

- In `seq:`, if the previous topic produced a result, it is automatically injected into the next topic's initial prompt.
- `para:` runs topics concurrently; all must complete before the next step begins.
- Completion is determined by `goalAchieved` when a goal is set, or by an `endTurn → initial` transition when no goal is specified.
- If no agent is specified, the default agent configuration is used. `AbTopicOrchestration` holds its own default that can override the global setting.
- See `scripting-feasibility.md` for the design and feasibility analysis.
