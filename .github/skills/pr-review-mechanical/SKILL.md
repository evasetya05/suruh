---
name: pr-review-mechanical
description: >
  Use when reviewing a pull request, diff, or set of changes in the MSDevBuild
  Eats Flutter app. Performs the mechanical, rule-based review layer only:
  Clean Architecture layer boundaries, BLoC conventions, Result<T> error
  handling, test coverage, secrets, lints. Trigger on "review this PR",
  "review this diff", "check these changes".
  Does NOT decide whether the design or the product behaviour is correct.
---

# Mechanical review for MSDevBuild Eats

This is the checking half of the pair. `flutter-feature` teaches Copilot to
*write* a feature our way; this one checks a diff against the same rules, so
writing and reviewing cannot disagree.

You review the mechanical layer only. Whether the feature is the right feature,
whether the pricing is correct, whether the UX makes sense — those are human
judgements and you do not make them.

## Flag as issues

1. **Layer boundaries.** No `package:flutter/` import in `lib/domain`. No
   import from `lib/data` inside `lib/features`. Blocking.
2. **Error handling.** Repositories and use cases return `Result<T>`. Anything
   throwing across a repository boundary is blocking. A `try/catch` inside a
   bloc means the error contract was bypassed — flag it.
3. **State.** State lives in a `Bloc` or `Cubit`. `setState` in a feature
   widget is blocking. A bloc registered in `get_it` is blocking.
4. **Equality.** A state class extending `Equatable` must list every field in
   `props`. A missing field means the UI silently stops rebuilding — blocking,
   because it does not fail a test either.
5. **Tests.** New bloc logic needs a `bloc_test` covering loading, data and
   failure with a mocked use case. Zero tests on new behaviour = blocking.
   A test that needs the emulator = blocking.
6. **Orchestration.** Multi-step work belongs in a use case, not a bloc. A bloc
   calling three use cases in sequence is a suggestion, not blocking, unless it
   also branches on their results.
7. **Secrets.** No keys, tokens, `google-services.json` or keystore in the
   diff. Blocking.
8. **Swallowed failures.** No empty `catch`. No `FailureResult` discarded
   without rendering something. Blocking.
9. **Lints.** Single quotes, `const` constructors, declared return types,
   `final` locals, no `print`. Suggestions, not blocking — `flutter analyze`
   already catches these and CI runs it.
10. **Entities.** Immutable, `Equatable`, with `copyWith`. Business rules that
    belong on the entity (pricing, status transitions) should not appear in a
    bloc or a widget.

## Do not flag

- The world-readable catalogue in `firebase/firestore.rules`. Deliberate.
- The absent Firebase API key. The demo backend ships without one.
- Emoji in seed data. That is the design, not a placeholder.

## Output format

Respond in exactly this order:

### 1. Blocking issues
(must fix before merge; "None" if clean — one line per issue, with the file and line)

### 2. Suggestions
(non-blocking; report AT MOST FIVE, highest impact first)

### 3. Questions for the author
(needs context you cannot infer from the diff)

Never write "Approved", "LGTM", or "ready to merge". Approval is a human
decision.

## Self-check before responding

- Blocking issues listed before suggestions.
- Suggestions capped at five. If there were more, the cap forced you to
  prioritise — that is the job.
- No approval language anywhere.
- Anything needing product context is a question, not a guess.
- Every blocking issue names a file and a line.
