# Android permissions

Every permission this app declares, why it needs it, and what it exposes.

`.githooks/pre-commit` fails a commit that adds a `<uses-permission>` line to
`android/app/src/main/AndroidManifest.xml` without an entry here.

Produced and maintained with [`.ai/prompts/security-review.md`](../../.ai/prompts/security-review.md).

## Declared today

**None.**

That is not an oversight — it is the current state, and it is worth keeping.
The app runs against the seeded demo backend, so it needs no network permission
to function, no location permission to show a delivery address, and no storage
permission to render its own bundled assets.

Flutter's tooling adds `android.permission.INTERNET` to the debug and profile
manifests automatically. It is not in the release manifest, and it is not
listed here, because we do not declare it ourselves.

## What each future permission would cost

Filled in before the permission is added, not after.

| Permission | Would be needed for | What it exposes | Alternative |
|---|---|---|---|
| `INTERNET` | The Firebase backend, remote dish imagery | Everything the app sends, to anywhere | None, if the backend is switched on |
| `ACCESS_FINE_LOCATION` | Auto-filling the delivery address | Continuous precise location | Let the user pick a saved address — which is what the app does today |
| `POST_NOTIFICATIONS` | Order status pushes via `firebase_messaging` | Nothing by itself; the FCM token is the identifier that matters | In-app status polling while the tracking screen is open |
| `CAMERA` | Partner uploading a dish photo | Camera access whenever the app is foregrounded | Photo picker, which needs no permission |

## The rule

A permission is added in the same pull request as the feature that needs it,
with its row here filled in, and never "in advance because we might need it".
