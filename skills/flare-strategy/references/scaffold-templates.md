# FLARE Prompt Scaffold Templates

Each template is a ready-to-use prompt scaffold. Fill in `[BRACKETED]` placeholders
before handing to the user. All templates are framework-agnostic (plain prompt instructions).

---

## Template 1: FLARE-Instruct (Recommended Default)

Best for: instruction-tuned models, most agent runtimes, paragraph-level generation.

```
## Agent Instructions

You are working on the following task:
[TASK DESCRIPTION]

Your goal state is:
[DESIRED OUTPUT / END STATE]

### Retrieval Protocol

As you work through this task, you will sometimes need information you don't have.
When this happens, output a search query in this exact format on its own line:

  [Search: your query here]

Then stop and wait. Retrieved results will be injected into the conversation.
Resume generation only after you receive the results.

**Trigger a search when:**
- You are about to make a factual claim you're not confident about
- You need to understand something about [RETRIEVAL SOURCE: codebase / docs / web] 
  before proceeding
- You realize the next paragraph depends on information you don't currently have

**Do not trigger a search when:**
- You are reasoning, planning, or structuring — only when you need specific facts
- You have already retrieved this information in the current session

### Retrieval Sources Available
[LIST AVAILABLE SOURCES — e.g., "web search", "local codebase at /path/to/repo",
"knowledge base: [name]", "memory: past conversation context"]

### Output Format
[DESCRIBE EXPECTED OUTPUT FORMAT]
```

---

## Template 2: Goal-Pruning (Backward + Branch Elimination)

Best for: planning agents, goal-directed tasks, eliminating infeasible paths upfront.

```
## Agent Instructions

### Phase 1: Define the Goal State

Before taking any action, state the desired end state clearly and completely:
- What does success look like?
- What constraints must be satisfied?
- What would make a path invalid?

### Phase 2: Enumerate Paths

Generate [N: 3–5] distinct approaches to reach the goal state. For each path:
- Name it
- Describe the key steps
- Identify the key assumption it depends on

### Phase 3: Retrieve to Prune

For each path, identify what you need to verify to know if it's feasible.
Output retrieval queries in this format:

  [Search: query to verify assumption for Path N]

Wait for results. Then eliminate any path where retrieval reveals a blocking constraint.
Mark eliminated paths with [INFEASIBLE: reason].

### Phase 4: Execute the Surviving Path

Proceed with the highest-confidence feasible path. If multiple paths survive,
choose the one with [SELECTION CRITERION: fewest steps / lowest risk / fastest].

If you hit a blocking constraint mid-execution, return to Phase 2 and replan.

### Retrieval Sources Available
[LIST AVAILABLE SOURCES]

### Goal
[TASK DESCRIPTION AND DESIRED END STATE]
```

---

## Template 3: Adaptive Replanner (Uncertainty-Triggered + Forward)

Best for: long-horizon tasks, agents that encounter unexpected states mid-execution.

```
## Agent Instructions

You are executing a multi-step task. Proceed step by step. After each step:

1. **Check:** Does the result of this step match what you expected?
2. **Check:** Do you have enough information to confidently execute the next step?

If either answer is NO, output:
  [Replan: brief description of what changed or what you're missing]

Then stop, retrieve the necessary information, and produce a revised plan before continuing.

### Uncertainty Signals — stop and replan if you notice:
- Phrases forming in your output like "I'm not sure", "this may vary", "depending on"
- A next step that requires knowledge about [DOMAIN] you haven't verified
- A contradiction between retrieved information and your current plan

### Retrieval Sources Available
[LIST AVAILABLE SOURCES]

### Task
[TASK DESCRIPTION]

### Initial Plan (revise as needed)
[OPTIONAL: seed with an initial plan or leave blank for agent to generate]
```

---

## Template 4: Deep Planner (Bidirectional + Full Horizon)

Best for: high-stakes, constraint-heavy tasks where both current state and goal state
need to be fully understood before execution.

```
## Agent Instructions

Before executing anything, complete this planning protocol:

### Forward Pass
Starting from the current state, generate a step-by-step path toward the goal.
At each step, note what information you'd need to be confident.

### Backward Pass
Starting from the goal state, work backwards. For each step, ask:
"What must be true in the prior step for this step to be achievable?"
Note any assumptions.

### Convergence Check
Compare the forward and backward paths. Identify:
- Where they agree (high confidence steps)
- Where they diverge or conflict (uncertainty zones)

### Retrieve on Uncertainty Zones
For each uncertainty zone, output:
  [Search: query to resolve this uncertainty]

Wait for results, then finalize the plan.

### Execute
Proceed with the finalized plan. If new uncertainty zones appear mid-execution,
pause and repeat the retrieve step for that zone only.

### Retrieval Sources Available
[LIST AVAILABLE SOURCES]

### Current State
[DESCRIBE CURRENT STATE]

### Goal State
[DESCRIBE DESIRED END STATE AND SUCCESS CRITERIA]
```

---

## Filling In the Templates

When assembling a scaffold for the user, replace all `[BRACKETED]` items:

| Placeholder | Where to get it |
|---|---|
| `[TASK DESCRIPTION]` | User's scenario description |
| `[DESIRED OUTPUT / END STATE]` | What the agent is trying to produce |
| `[RETRIEVAL SOURCE]` | Which sources the user confirmed are available |
| `[LIST AVAILABLE SOURCES]` | Full list from the consult session |
| `[N: 3–5]` | Recommend 3 for speed, 5 for thoroughness |
| `[SELECTION CRITERION]` | Ask the user what they optimize for |
| `[DOMAIN]` | The specific knowledge domain relevant to the task |
| `[DESCRIBE CURRENT STATE]` | Starting conditions for the agent |
