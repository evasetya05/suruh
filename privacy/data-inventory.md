# Data inventory

Every field this app holds, why it exists, where it goes, and whether it is
personal data.

The store data safety declaration is derived from this file, so the two cannot
disagree. `.githooks/pre-commit` fails a commit that marks an analytics event
field `personal: true` without an entry here.

Produced and maintained with [`.ai/prompts/privacy.md`](../.ai/prompts/privacy.md).

## Demo backend (the default)

Everything below lives in memory for the life of the process, except the four
`shared_preferences` keys. Nothing leaves the device.

| Field | Why | Where it goes | Retention | Personal data |
|---|---|---|---|---|
| Display name | Greeting, order record | Memory + session key | Until sign-out | Yes |
| Email | Sign-in identity | Memory + session key | Until sign-out | Yes |
| Phone | Attached to an order for the rider | Memory | Process lifetime | Yes |
| Delivery addresses | Checkout and tracking | Memory | Process lifetime | Yes |
| Cart contents | Basket restore across launches | `shared_preferences` | Until cleared or ordered | No |
| Theme choice | Light / dark / system | `shared_preferences` | Indefinite | No |
| Onboarding seen | Skip the intro on relaunch | `shared_preferences` | Indefinite | No |
| Order history | The orders tab | Memory | Process lifetime | Yes — contains address and phone |

## Firebase backend (opt-in via `AppConfig.backend`)

The same fields, plus what the platform adds. These findings apply only when
the Firebase backend is switched on.

| Field | Why | Where it goes | Retention | Personal data |
|---|---|---|---|---|
| Firebase Auth UID | Identity, and the key for every rule check | Firebase Auth + Firestore | Until account deletion | Pseudonymous, but linkable |
| `users/{uid}.role` | Which dashboard the user reaches | Firestore | Until account deletion | No |
| Order documents | The partner and rider need them | Firestore | **Open question** — see below | Yes |
| Dish photography | Partner uploads | Cloud Storage | Until deleted by the partner | No |
| FCM device token | Order status pushes | Firebase Messaging | **Should be deleted at sign-out** | Yes — a device identifier |

## Open questions

1. **Order retention.** Orders carry a delivery address and a phone number and
   currently have no retention policy. A real deployment needs one before
   launch, not after.
2. **FCM token at sign-out.** The token outlives the session unless it is
   explicitly deleted. It should be deleted, and today nothing does it.
3. **Consent.** No consent gate exists, because the demo backend collects
   nothing that leaves the device. Switching on the Firebase backend changes
   that, and the consent path has to exist before it ships.

## The rule

No personal identifier goes into an analytics event or an error report. Error
reports carry the build number, the flavour, the screen and `AppConfig.backend`,
and nothing that identifies a person.
