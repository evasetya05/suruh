# Custom agents

Role agents for MSDevBuild Eats, in the shape described in
[Designing a Multi-Agent GitHub Copilot Orchestrator](https://blog.msdevbuild.com/blog/github-copilot-multi-agent-orchestrator-legacy-teams).

These are a **design**, not an autonomous team. Every arrow between two agents
is a human clicking a handoff, a git hook running, or CI passing. Every handoff
here is `send: false` on purpose: the orchestrator pre-fills the next prompt,
and a person reads it before it goes.

> Copilot's custom agent, handoff and hook features move between preview and
> general availability, and the frontmatter keys change. Handoffs are an
> IDE-side feature and are not supported for the cloud agent on GitHub.com.
> Confirm against current GitHub documentation before relying on any of it.

## The role map

| Agent | Responsibility | Tools | Must NOT do | Hands off to |
|---|---|---|---|---|
| `orchestrator` | Interpret, sequence, surface decisions | read, search | Edit code; skip a human gate | Architecture, then specialists |
| `architecture` | Which layer, and what the blast radius is | read, search | Implement; block without a trade-off | Human, then feature |
| `feature` | Implement the approved plan | read, edit, run tests | Touch another feature; test its own work | Tester |
| `tester` | `bloc_test` against mocked use cases | read, edit, run tests | Edit `lib/`; approve its own change | Human |
| `security` | Exploit paths against the deployed rules | read, search | Fix code; sign off | Human |

The column that matters is **Must NOT do**. Only `feature` can edit `lib/`.
That one constraint removes most of the ways agents step on each other.

## The shared source of truth

Every agent reads the same standards, so they cannot contradict each other:

- [`AGENTS.md`](../../AGENTS.md) — the rules
- [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) — the reasoning
- [`.github/copilot-instructions.md`](../copilot-instructions.md) — the Copilot-only subset

## The deterministic glue

Agents advise and act. These enforce:

- [`.github/hooks/copilot-hooks.json`](../hooks/copilot-hooks.json) — a
  `preToolUse` hook that denies a tool call which would violate the layering or
  stage a credential.
- [`.githooks/pre-commit`](../../.githooks/pre-commit) and `pre-push` — the same
  checks at the git boundary, for humans and agents alike.

## Longer-form agents

The five here are role agents for driving a change. The fifteen job-specific
prompts — dependencies, licences, privacy, release, monitoring, analytics and
the rest — are in [`.ai/prompts/`](../../.ai/prompts).

## Start with one

Do not wire up all five. Pick the one that removes the most friction for you —
on this codebase that is `feature`, because the layering is the thing people
get wrong — prove it earns its keep, then add a second.
