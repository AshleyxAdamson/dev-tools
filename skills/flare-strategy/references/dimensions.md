# FLARE Dimensions Reference

All five dimensions with options, tradeoffs, and when to use each.

---

## Dimension 1: Retrieval Trigger
*When does the agent decide to retrieve?*

| Option | How it works | Best when | Requires |
|---|---|---|---|
| **Token probability** | Retrieves when generated tokens fall below a confidence threshold | Base/completion models with logprob access | Raw logprobs — NOT available in most chat APIs |
| **FLARE-Instruct** | Model outputs `[Search: query]` when it needs info | Instruction-tuned models (Claude, GPT-4, etc.) | Prompt instruction only — recommended default |
| **Uncertainty markers** | Detect hedging language ("I'm not sure", "this may depend") | When model is verbose about uncertainty | Simple string matching or classifier |
| **Fixed interval** | Retrieve every N steps regardless of confidence | Short, structured tasks with predictable info needs | Nothing — simplest to implement |
| **Explicit checkpoint** | Retrieve at defined points in a plan (e.g., before each subtask) | Multi-step planning agents with known decision points | Plan structure defined upfront |

**Default recommendation:** FLARE-Instruct unless the user has logprob access.

---

## Dimension 2: Lookahead Depth
*How far ahead does the agent look before deciding to retrieve?*

| Option | Scope | Best when |
|---|---|---|
| **Single sentence** | Predicts one sentence ahead | Factual, dense generation (original FLARE use case) |
| **Paragraph** | Predicts a full paragraph or reasoning block | Long-form generation, explanations, documentation |
| **Single step** | One action/subtask ahead in a plan | Step-by-step agent execution |
| **Multi-step (3–5)** | Simulates several steps ahead before committing | Complex planning where early steps constrain later ones |
| **Full horizon** | Simulates entire task completion path | High-stakes decisions; expensive but thorough |

**Tradeoff:** Deeper lookahead = better decisions, more token cost, more latency.

---

## Dimension 3: Retrieval Source
*Where does the agent retrieve from?*

| Source | Best for | Notes |
|---|---|---|
| **Web search** | Current facts, external context, unknown APIs | Use when the agent might be working with outdated info |
| **Local codebase / files** | Code agents, refactoring, understanding existing structure | Index or use grep/AST tools; most useful for opencode agents |
| **Memory / past chats** | Personalized agents, continuity across sessions | Requires memory tool or summarized history |
| **External docs / knowledge base** | Domain-specific agents (design systems, APIs, legal docs) | Works well with embeddings + vector search |
| **Multi-source** | Complex tasks spanning multiple knowledge types | Retrieve from multiple sources; merge or rank results |

**Note:** Multiple sources can be combined — the skill should ask which are available.

---

## Dimension 4: Post-Retrieval Action
*What does the agent do with retrieved content?*

| Option | Behavior | Best when |
|---|---|---|
| **Regenerate** | Discard uncertain sentence, regenerate with retrieved docs injected | Original FLARE — tight factual accuracy needed |
| **Inject and continue** | Insert retrieved content into context, keep going | Less disruptive; good for planning agents |
| **Prune branches** | Use retrieved content to eliminate infeasible plan branches | Tree of Thoughts style; goal-directed planning |
| **Replan** | Trigger a full replanning step when retrieval reveals a contradiction | Long-horizon agents that need to adapt mid-task |
| **Annotate** | Tag the uncertain output with retrieved evidence, surface to user | Human-in-the-loop workflows |

**Tradeoff:** Regenerate is most accurate but most expensive. Inject-and-continue is fastest.

---

## Dimension 5: Planning Direction
*Which direction does the agent plan?*

| Option | Approach | Best when |
|---|---|---|
| **Forward** | Generate from current state toward goal (default) | Most tasks; simple sequential workflows |
| **Backward** | Start from desired end state, retrieve what must be true at each prior step | Goal is crystal clear; current state is ambiguous |
| **Bidirectional** | Plan forward and backward simultaneously, meet in the middle | Complex constraint-heavy tasks |
| **Opportunistic** | No fixed direction; pursue whichever subgoal is most retrievable/feasible | Exploratory tasks with unclear sequencing |

**Note:** Backward planning pairs especially well with branch pruning — define the goal,
enumerate paths to it, retrieve to test feasibility, cut the impossible ones.

---

## Quick Combination Patterns

These are battle-tested starting points:

| Name | Trigger | Lookahead | Source | Post-retrieval | Direction |
|---|---|---|---|---|---|
| **Classic FLARE** | Token prob | Single sentence | Web | Regenerate | Forward |
| **FLARE-Instruct (recommended default)** | FLARE-Instruct | Paragraph | Web or docs | Inject + continue | Forward |
| **Goal-pruning** | Explicit checkpoint | Multi-step | Codebase + docs | Prune branches | Backward |
| **Adaptive replanner** | Uncertainty markers | Single step | Multi-source | Replan | Forward |
| **Deep planner** | Explicit checkpoint | Full horizon | Docs + memory | Prune branches | Bidirectional |
