# The agent roster

Prompt files for the AI agents that work on this repository, plus the git hooks
that enforce the rules a script can actually check.

These accompany the [AI coding agent team series](https://blog.msdevbuild.com/blog/ai-coding-agent-team-software-project)
on MSDevBuild. Each file here is the real, runnable version of an agent
described in that series — the paths, package names and rules refer to this
codebase, not to a generic example.

## How to run one

Paste the prompt into Copilot Chat, Claude Code, or whatever agent you use,
fill in the `{placeholders}` at the top, and give it the files it asks for.
Nothing here is magic; the value is that the job is scoped and the refusal
conditions are written down.

## The roster

| Prompt | Job | Paired hook |
|---|---|---|
| `dependencies.md` | Classify the manifest — what each package is for and what removing it costs | `pre-commit`: a new package needs a line in `docs/dependencies.md` |
| `license-review.md` | The obligations a deny-list cannot check | `pre-push`: denied licences in the resolved tree |
| `copyright.md` | Asset provenance and attribution | `pre-commit`: no asset without an `ATTRIBUTIONS.md` entry |
| `privacy.md` | Data inventory and the store declaration derived from it | `pre-commit`: a personal field needs an inventory entry |
| `security-review.md` | Exploit paths in a diff, against the deployed Firestore rules | `pre-commit`: new Android permission needs a justification |
| `cybersecurity.md` | Credentials ranked by blast radius, CI attack surface | `pre-commit`: `pull_request_target` checking out fork code |
| `pentest.md` | Executable authorization tests against the emulator | — |
| `devops.md` | Flavours, workflows, secret mapping | `pre-commit`: no credential or platform config in git |
| `release.md` | Version bump, store notes, rollout and rollback | `pre-push`: tag matches `pubspec.yaml` and `CHANGELOG.md` |
| `monitoring.md` | The questions an incident will ask, and the signals that answer them | `pre-commit`: no empty catch block |
| `analytics.md` | The event spec in `analytics/events.yaml` | `pre-commit`: no undefined event logged |
| `prompt-engineer.md` | Fix a prompt that returns the wrong shape | `pre-commit`: every prompt states a refusal condition |
| `skill-builder.md` | Turn repeated review comments into a SKILL.md | `pre-commit`: a skill citing a dead path |
| `hooks-generator.md` | Turn a rule into a checkable hook, or say it is not checkable | `pre-push`: hooks are fast and have fixtures |
| `agents-md-generator.md` | Find rules duplicated across prompts and move them up | `pre-commit`: a rule repeated in three prompts |

## Install the hooks

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

They are not installed automatically. Read them first — several of them will
fail a commit, which is the point.

## An honest note on scope

Some of these agents produce specs for things this app does not yet do.
`analytics/events.yaml` is a specification; no analytics SDK is wired up.
`privacy/data-inventory.md` describes the fields the demo backend holds and the
ones a Firebase deployment would add. They are here because the agent that
writes them is the point of the exercise, and a spec written before the code is
cheaper than one reverse-engineered after.
