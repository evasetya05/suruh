## Summary
<!-- What does this PR do, in one or two plain sentences? -->

## Why
<!-- Why is this change needed? Link the issue.
     This is the part the diff can NOT tell the reviewer. -->
Closes #

## Changes
<!-- The key changes, grouped. Copilot can draft this section —
     see the PR summary guidance in .github/copilot-instructions.md. -->

## Risk & rollback
<!-- Blast radius. Anything that touches:
       - the shape of a shared_preferences key (session, cart, theme,
         onboarding) — a rollback CANNOT undo this, the old build reads
         the new data
       - firebase/firestore.rules or storage.rules
       - OrderStatus, PricingPolicy, or anything in lib/domain/entities
         that three features read
     How do we roll back? Web is live in minutes; testers install when
     they feel like it. -->

## Testing
<!-- flutter analyze clean? flutter test green?
     Which bloc_test covers the new path — loading, data AND failure?
     Screenshots for anything visual, web and mobile width.
     "Trust me" is not testing. -->

## Reviewer focus
<!-- Where should the reviewer spend their attention?
     e.g. "The cart conflict path in CartBloc — I changed when
     pendingConflict is emitted." -->
