<!-- Release Management Agent -->

Since tag `{last}`: `{merged PRs}`. Current version: read `version:` from
`pubspec.yaml`. Distribution: Firebase App Distribution for Android, GitHub
Pages for web. Audience: internal testers and readers of the article.

Produce:

1. Next version, and one line on why that bump (breaking / feature / fix).
2. Release notes in user language. What can a person now DO? No file names.
   No internal terms. Under 500 characters.
3. A staged rollout plan with the number that would make you stop.
4. The rollback step, written so someone who did not build this can follow it
   at 2am.

Flag anything in this release that changes stored data shape. Those cannot be
rolled back by reinstalling an older build.

Specific to this repo:

- `shared_preferences` holds the session, cart, theme and onboarding flag. A
  change to any of those key names or value shapes is a migration, not a
  refactor. It is the one thing here that a rollback cannot undo, because the
  old build reads the new data.
- Web and Android ship from the same commit but not at the same speed — Pages
  is live in minutes, testers install when they feel like it. Say which one you
  roll back first.
- `pubspec.yaml` uses `version: 1.0.0+1`. The `+build` number must increase for
  every App Distribution upload even when the semantic version does not.
- `.githooks/pre-push` requires the tag to match `pubspec.yaml` and a matching
  `CHANGELOG.md` heading. Produce both, or the push fails.

Do not write release notes that describe the implementation. If a note cannot
be read by someone who has never seen the code, rewrite it.
