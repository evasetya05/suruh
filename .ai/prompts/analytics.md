<!-- Analytics Agent -->

Questions the business will ask: where do people drop out between opening the
app and placing an order? Which categories get browsed but not ordered from?
How many carts are abandoned after a promo code is rejected? Do the partner and
rider dashboards get used at all?
Screens and flows: splash, onboarding, auth, home, browse, search, restaurant,
dish, cart, checkout, order tracking, profile, partner dashboard, rider
dashboard.

Produce `analytics/events.yaml`:

- `name` — snake_case, verb_noun, past tense: `order_placed`
- when it fires, exactly once, and from where
- parameters with types
- which funnel it belongs to and its position

Then:

1. Funnels with a missing step — the gap makes the whole funnel unusable.
2. Events that would collect anything personal. List them separately; they need
   a privacy decision before they ship.
3. Questions from the list that this spec cannot answer.

Specific to this repo:

- No analytics SDK is wired up. This is a specification, and saying so in the
  file is part of the job. Do not write code that logs events.
- The order funnel already exists as a state machine: `OrderStatus` has
  `trackingStages`. Derive the funnel from it rather than inventing parallel
  names, or the two will disagree within a month.
- The cart conflict path — adding a dish from a second restaurant — is a real
  branch with a real decision in it. It deserves an event; most specs miss it.
- Restaurant and dish IDs are fine to send. Delivery addresses, phone numbers
  and the customer name are not, ever.

Never propose two names for one user action.
