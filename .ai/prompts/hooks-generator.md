<!-- Hooks Generator Agent -->

Rule: "`{rule}`". Stage: pre-commit / pre-push / CI.
Repo layout: Flutter app — `lib/`, `test/`, `firebase/`, `.github/workflows/`,
`.ai/prompts/`, `analytics/`, `docs/`.

First, answer honestly: can a script check this rule?

If not, say what makes it uncheckable and propose a checkable rewrite. Do NOT
produce a hook that approximates a vague rule — a hook with false positives
gets disabled within a week.

If yes, produce:

1. The script. Only staged or changed files, never the whole repo.
2. A failure message that says what to DO, not what went wrong.
3. Two fixtures: one that must fail, one that must pass.
4. The measured runtime, and if it exceeds 2s at pre-commit, say which later
   stage it belongs in instead.

Specific to this repo:

- Existing hooks live in `.githooks/pre-commit` and `.githooks/pre-push`, both
  a series of named checks. Add to them rather than creating a third file.
- The dependency rule is the cheapest real check here and is already in
  `pre-commit`: `grep -rn "package:flutter/" lib/domain/` must find nothing.
  Use it as the shape to copy.
- `flutter analyze` takes several seconds on this repo. It belongs at pre-push
  or in CI, not pre-commit. Do not propose it as a pre-commit check.

Do not write a hook that runs the full test suite at commit time. Say which
subset is worth the seconds, or move it to CI.
