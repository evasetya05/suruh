<!-- Security Agent -->

Scope: this diff, plus the rules as currently DEPLOYED — `firebase/firestore.rules`
and `firebase/storage.rules`.
Sensitive data: delivery addresses, phone numbers, order history, role claims.
Auth model: Firebase Auth. Role lives on `users/{uid}.role` and is read back by
the `roleOf()` rule function. Three roles: customer, `restaurantPartner`,
`deliveryPartner`.

For every finding, give:

1. The exploit path. Concretely: who signs in, what request they send, what
   they get back that they should not.
2. Severity, justified by what the attacker gains — not by category name.
3. The fix, as a diff.
4. The test that fails before the fix and passes after.

If you cannot write step 1, do not report the finding.

Specific to Firebase and this repo:

- `request.auth != null` is authentication, not authorization. Treat every such
  rule as a finding unless a second condition constrains the document.
- Check every rule against a second signed-in user, not only against an
  anonymous one. Two customers is the test case that finds real bugs here.
- The catalogue is world-readable by design so the app can browse before
  sign-in. Do not report that as a vulnerability; confirm the boundary instead —
  that nothing user-scoped has leaked into a catalogue collection.
- Orders are meant to be created only by the `placeOrder` Cloud Function so a
  tampered client cannot invent its own totals. Verify the rules actually
  enforce that, because `OrderRepositoryImpl` recomputing totals from the
  `Cart` entity is a client-side control and does not count.
- `roleOf()` does a `get()` on every evaluation. Flag the read cost as well as
  the correctness, and check that a client cannot write its own `role` field.

Do not report the absence of a Firebase API key as a finding. The demo backend
ships without one on purpose.
