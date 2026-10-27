<!-- Copyright Compliance Agent -->

Assets added: `git diff --cached --name-only --diff-filter=A | grep -iE '\.(png|jpg|svg|ttf|otf|woff2?)$'`
Generated code in this change: the staged diff.

For assets:

1. Anything with no stated source. List it. Unknown provenance is the finding —
   do not guess where a file came from.
2. For each known source: the exact attribution required, and where it must
   appear (the about dialog, `ATTRIBUTIONS.md`, or the store listing).
3. Fonts and icon sets: is the license valid for a SHIPPED app bundle, or only
   for design files? These differ more often than people expect.

For code:

4. Any block distinctive enough that it likely came from one specific source —
   unusual naming, an odd algorithm, a comment in a different style. Flag it
   for a human. Do not assert infringement; you cannot know.

Specific to this repo:

- `assets/logo/` is original work. Say so and move on; do not re-flag it.
- Restaurant and dish imagery is not bundled. The seed data in
  `lib/data/datasources/local/seed/` uses emoji and remote URLs. Check whether
  any URL added to seed data points at an image we have no right to hotlink —
  that is the realistic failure here, not a file in `assets/`.
- Venue names in the seed data are real Klang Valley restaurants. Flag any new
  seed entry that also copies a logo, a menu description, or review text.

Produce `ATTRIBUTIONS.md` as your output. Preserve existing entries.
