<!-- Skill Builder Agent -->

Evidence: review comments repeated 3+ times: `{file or paste}`
Good examples: `lib/features/orders/`, `lib/features/cart/`
Code we would not repeat: `{paths}`

Produce a `SKILL.md` where every rule is:

- Stated as an instruction, not a principle. "No Firestore call outside
  `lib/data/`" — not "separate concerns".
- Backed by a SHORT right/wrong pair from the real files above.
- Traceable: which review comment or bug caused this rule to exist.

Constraints:

- Cut anything not supported by the evidence. An aspiration in a skill file
  makes the whole file less trusted.
- Keep it short enough to be loaded in full. If it is growing past that, split
  by topic rather than trimming the examples — the examples are what make it
  work.

Specific to this repo:

- The architecture rules are already written down in `AGENTS.md` and
  `.github/copilot-instructions.md`. A skill that repeats them is a copy that
  will drift. Cite them, and spend the skill on the thing they do not cover:
  the step-by-step of building one feature.
- Cite real paths. `.githooks/pre-commit` fails a skill that references a file
  which no longer exists, so `lib/features/orders/bloc/orders_cubit.dart` is a
  valid citation and `lib/features/orders/presentation/state/` is not.
- The one rule nobody infers: blocs are not registered in `get_it`. If the
  evidence supports it, it goes first.

Do not produce a skill for a job that a hook can check deterministically.
Say "this is a hook, not a skill" and hand it to the hooks generator.
