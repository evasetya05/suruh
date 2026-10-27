# Attributions

Where every third-party asset and font in this repository came from, and what
each one obliges us to publish.

`.githooks/pre-commit` fails a commit that adds an image or font file with no
entry here. Record the source while you still remember it.

Produced and maintained with [`.ai/prompts/copyright.md`](.ai/prompts/copyright.md).

## Images

| File | Source | Licence | Attribution required |
|---|---|---|---|
| `assets/logo/logo.svg` | Original work, MSDevBuild | Part of this repository (MIT) | No |
| `assets/logo/logo-mark.svg` | Original work, MSDevBuild | Part of this repository (MIT) | No |
| `assets/logo/logo-256.png` | Original work, MSDevBuild | Part of this repository (MIT) | No |
| `assets/logo/logo-512.png` | Original work, MSDevBuild | Part of this repository (MIT) | No |

No restaurant or dish photography is bundled. The seeded catalogue in
`lib/data/datasources/local/seed/` uses emoji, and any remote image URL is
loaded at runtime rather than redistributed. Adding a bundled food photo means
adding a row here first.

## Fonts

| Font | Source | Licence | Attribution required |
|---|---|---|---|
| Inter | Google Fonts, via the `google_fonts` package | SIL Open Font License 1.1 | No attribution required for use; the licence text must not be removed |

The `google_fonts` package resolves Inter at runtime on some platforms and
bundles it on others. Both paths are covered by the OFL.

## Seed data

Restaurant names in `lib/data/datasources/local/seed/` refer to real Klang
Valley venues. Only the names are used — no logos, no menu copy, no review
text. Adding any of those would need permission and a row in this file.

## Code

No third-party source files are vendored into this repository. Everything under
`lib/` is original work under the repository's MIT licence.
