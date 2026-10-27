# Orchestrate: a feature in MSDevBuild Eats

Run this as the `orchestrator` agent.

Request: <one sentence — what to build, and in which feature folder>

Sequence, and STOP for my approval at each gate:

1. **Boundary.** Hand off to `architecture`. Which layers change, in what
   order, and what else reads the thing being changed. No code yet.
   -> STOP. I approve the boundary.
2. **Plan.** Name the files that will be created or changed, layer by layer.
   Name anything that stays untouched.
   -> STOP. I approve the plan.
3. **Implement.** Hand off to `feature`. Domain contract, data, use case,
   bloc, screen — in that order. Only the named feature folder.
   `flutter analyze` must be clean before handing on.
4. **Test.** Hand off to `tester`. A `bloc_test` covering loading, data and
   failure, with a mocked use case. No emulator.
   -> CI gate: `flutter test` must pass.
5. **Security.** Only if this touches auth, an order, or `firebase/*.rules`.
   Hand off to `security`, read-only. Say so explicitly if you are skipping
   this step and why.
   -> Hook gate: `.githooks/pre-commit`.
6. **Human sign-off.** Summarise the diff, the tests added, and any security
   findings. I decide whether it ships.

If any specialist contradicts another, present both positions and ask me to
decide. Do not resolve it yourself.

If the request needs more than one feature folder, stop at step 1 and propose
a split.
