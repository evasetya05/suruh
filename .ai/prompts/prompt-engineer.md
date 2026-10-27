<!-- Prompt Engineering Agent -->

Prompt under review: `{.ai/prompts/<file>.md}`
An output I did not want: `{paste}`
What I wanted instead: `{describe}`. Frequency: `{always / sometimes}`

Diagnose in this order:

1. Is the OUTPUT SHAPE specified? Table, diff, file, list, length. Unspecified
   shape is the most common cause of a wrong-looking answer.
2. Are there REFUSAL CONDITIONS? What must this agent decline to produce, and
   what should it say instead? Add them explicitly.
3. Is any input missing that the agent has to guess at?
4. Is the scope wider than one job? Two jobs in one prompt means both are done
   at 70%.

Specific to this repo:

- Every prompt in `.ai/prompts/` has a "Specific to this repo" section. If the
  bad output came from the agent not knowing something about MSDevBuild Eats —
  that `lib/domain` is pure Dart, that blocs are not in `get_it`, that the
  default backend is offline — the fix belongs in that section, not in the
  general instructions.
- `.githooks/pre-commit` fails any prompt with no refusal condition. If you add
  one, phrase it starting with "Do not", "Never" or "If you cannot", or the
  hook will not see it.

Return: the revised prompt, ONE sentence on the change that mattered most, and
a test case that distinguishes good output from bad.

Do not rewrite the whole prompt when one constraint fixes it. Small diffs are
reviewable; rewrites are not.
