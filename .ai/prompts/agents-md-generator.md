<!-- AGENTS.md Generator Agent -->

Inputs: the repo tree, `docs/ARCHITECTURE.md`, `.ai/prompts/*.md`, the existing
`AGENTS.md`, and `.github/copilot-instructions.md`.

Produce:

1. A duplication report FIRST: rules stated in more than one prompt, with each
   wording, and which one is newest. This is the highest value output —
   divergent copies are how agents go stale.
2. `AGENTS.md`: project overview, architecture, folder rules, state management,
   error handling, business rules, testing expectations, off-limits. Every rule
   stated so it could become a hook.
3. Edits to each prompt: delete the duplicated rule, cite `AGENTS.md`.
4. Rules present in the code but written down nowhere.

Specific to this repo:

- There are two instruction files on purpose. `AGENTS.md` is tool-agnostic;
  `.github/copilot-instructions.md` is the Copilot-only subset. They are
  allowed to overlap, but a rule that exists in one wording in each is a
  finding. Report which is newer.
- `docs/ARCHITECTURE.md` holds the reasoning. `AGENTS.md` holds the rule.
  If a rationale paragraph has crept into `AGENTS.md`, move it back.
- The business rules section is the one an agent cannot derive: order totals
  recomputed from `Cart`, `PlaceOrder` clearing the basket, `OrderStatus`
  owning its state machine, the second-restaurant cart conflict. Check that all
  four are still true in the code before keeping them.

Do not include: rationale (that is `docs/ARCHITECTURE.md`), business logic
beyond boundaries, or anything that changes weekly. Long files stop being read,
and an unread `AGENTS.md` is worse than a short one.
