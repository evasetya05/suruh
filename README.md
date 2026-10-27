<p align="center">
  <img src="assets/logo/logo-256.png" width="112" height="112" alt="MSDevBuild Eats logo">
</p>

<h1 align="center">MSDevBuild Eats</h1>

<p align="center">
  <strong>A portfolio-quality Flutter food delivery demo</strong><br>
  Built by <a href="https://blog.msdevbuild.com/">MSDevBuild</a> for the article at
  <a href="https://blog.msdevbuild.com/">blog.msdevbuild.com</a>
</p>

<p align="center">
  <a href="https://jssuthahar.github.io/food-delivery-app/"><strong>▶ Live demo</strong></a> ·
  <a href="https://appdistribution.firebase.dev/i/00432c5aa60de58b"><strong>📱 Download for Android</strong></a> ·
  <a href="docs/ARCHITECTURE.md">Architecture</a> ·
  <a href="docs/SETUP.md">Setup</a> ·
  <a href="docs/DEPLOYMENT.md">Deployment</a>
</p>

---

> **This project accompanies an article.** It was built as a worked example for
> **https://blog.msdevbuild.com/** — the write-up walks through the Clean
> Architecture layering, the BLoC patterns and the trade-offs behind the code
> you are reading. The app links back to it from the login screen, the profile
> tab and the about dialog.

A Flutter food delivery app modelled on the Malaysian Grab super-app experience.
It runs on **web, Android, iOS and tablet** from one codebase, and ships all
three sides of a delivery marketplace: the **customer** app, the **restaurant
partner** dashboard, and the **delivery rider** dashboard.

It runs with **zero configuration** — no Firebase project, no API keys, no
network. A seeded in-memory backend with 20 restaurants, 100 dishes, ~160
reviews and a live order simulation stands in for the server.

```bash
flutter pub get
flutter run -d chrome      # or any connected device
```

Sign in with any demo persona on the login screen, or use
`customer@msdevbuild.com` / `demo1234`.

---

## Try it without building

| Platform | Link |
|---|---|
| **Web** | <https://jssuthahar.github.io/food-delivery-app/> |
| **Android** | <https://appdistribution.firebase.dev/i/00432c5aa60de58b> |

The Android build is distributed through Firebase App Distribution — open the
link on the device, accept the tester invitation, and install from there. It is
the same APK CI produces, running the offline demo backend, so it needs no
account and no network beyond the download.

All three personas share the password `demo1234`. Routing is hash-based, so
once you are signed in as the matching role you can deep-link straight to a
dashboard:

| Persona | Sign in as | Deep link |
|---|---|---|
| Customer | `customer@msdevbuild.com` | [`/#/home`](https://jssuthahar.github.io/food-delivery-app/#/home) |
| Restaurant partner | `partner@msdevbuild.com` | [`/#/partner`](https://jssuthahar.github.io/food-delivery-app/#/partner) |
| Delivery rider | `rider@msdevbuild.com` | [`/#/rider`](https://jssuthahar.github.io/food-delivery-app/#/rider) |

Each persona is fenced into its own section of the app, so these links redirect
to the login screen — or to your own role's home — unless you are signed in as
that persona.

---

## Contents

- [What's in the box](#whats-in-the-box)
- [Demo accounts](#demo-accounts)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [State management](#state-management)
- [The demo backend](#the-demo-backend)
- [Firebase backend](#firebase-backend)
- [Deployment](#deployment)
- [Responsive design](#responsive-design)
- [Testing](#testing)
- [Screenshots](#screenshots)
- [A note on the brief](#a-note-on-the-brief)

---

## What's in the box

### Customer app

| Feature | Notes |
|---|---|
| Splash | Branded, waits on real session restore rather than a timer |
| Onboarding | Three pages, skippable, remembered across launches |
| Login / Register | Validation, error states, password reset, one-tap demo personas |
| Home | Greeting + address, search entry, category tiles, auto-playing promo carousel, featured / popular / offers rails, full nearby list |
| Browse | Category filter, sort (recommended, rating, ETA, fee, distance), free-delivery / open-now / min-rating / price-level filters |
| Search | 320 ms debounced, restaurants + dishes, recent searches, trending suggestions |
| Restaurant page | Collapsing hero, info strip, Menu / Reviews / Info tabs, in-menu search, rating breakdown |
| Dish page | Image, description, ingredients, allergens, calories, prep time, dish-level reviews |
| Cart | Add / remove / swipe-to-delete, quantity stepper, per-item notes, promo codes, full price breakdown, minimum-order nudge |
| Checkout | Saved address picker, four payment methods, rider note, order summary |
| Order tracking | Live animated timeline, rider card, receipt, cancel, rate, reorder |
| Profile | Identity card, personal info editor, saved addresses (CRUD + default), favourites, order history, theme switcher |

### Restaurant partner
Merchant dashboard with live revenue tiles, a 7-day sales chart, open/closed
storefront toggle, three order queues (incoming / in kitchen / completed),
one-tap status advancement, and full menu CRUD with sold-out switches.

### Delivery rider
Online/offline toggle, earnings and delivery counters, available job pool,
pickup → drop-off legs with customer notes, and status updates that flow
straight back to the customer's tracking screen.

### Cross-cutting
Light/dark/system themes · offline support with cached catalogue · loading
skeletons · empty states · error states with retry · form validation ·
responsive phone/tablet/desktop layouts · smooth animations throughout.

---

## Demo accounts

All three share the password **`demo1234`**, or tap the persona card on the
login screen.

| Role | Email | Lands on |
|---|---|---|
| Customer | `customer@msdevbuild.com` | Home feed, full ordering flow |
| Restaurant partner | `partner@msdevbuild.com` | Merchant dashboard for *Din Tai Dumpling House* |
| Delivery rider | `rider@msdevbuild.com` | Rider job queue |

**Try this:** sign in as the customer, place an order, then sign out and sign
back in as the partner — the order is sitting in the *Incoming* queue. Accept
it, mark it ready, and the rider's dashboard picks it up.

Promo codes: `MSDEV30`, `NEWBITE`, `LUNCH20`, `SWEET10` (and `EXPIRED5` to
see the rejection path).

---

## Architecture

Clean Architecture with three layers and a strict inward dependency rule.
Nothing in an inner layer knows anything about an outer one.

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION            lib/features/<f>/               │
│  Screens · Widgets · BLoCs / Cubits                      │
│  Knows: domain entities + use cases                      │
└───────────────────────────┬─────────────────────────────┘
                            │ calls
┌───────────────────────────▼─────────────────────────────┐
│  DOMAIN                  lib/domain/                     │
│  Entities · Repository interfaces · Use cases            │
│  Knows: nothing. Pure Dart, no Flutter import.           │
└───────────────────────────▲─────────────────────────────┘
                            │ implements
┌───────────────────────────┴─────────────────────────────┐
│  DATA                    lib/data/                       │
│  Models (JSON) · Data sources · Repository impls         │
│  Knows: domain contracts + infrastructure                │
└─────────────────────────────────────────────────────────┘
```

Full write-up, including the error contract and the offline-first caching
policy: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**.

### Key decisions

**`Result<T>` instead of exceptions.** Every repository and use case returns
`Result<T>` — either `Success<T>` or `FailureResult<T>`. Failure handling is
part of the type signature, so the UI cannot forget an error path.

**Exceptions never cross the repository boundary.** Data sources throw
`AppException`s; repositories translate them into domain `Failure`s in exactly
one place (`mapErrorToFailure`). The domain and presentation layers never
import Firebase, http or sqlite types.

**Use cases carry the orchestration.** `GetHomeFeed` fans six repository calls
out in parallel; `PlaceOrder` creates the order *and* clears the cart, because
an order that exists with a stale basket behind it is a real bug class;
`GetRestaurantDetail` loads the restaurant, then its menu and reviews, and
groups the menu into sections. The bloc asks for one thing and stays unaware.

**The repository interface is the swap point.** `AuthRepository` has two live
implementations — `AuthRepositoryImpl` (demo) and `FirebaseAuthRepository` —
selected by one line in `AppConfig`. No screen changes.

---

## Project structure

```
lib/
├── main.dart                    # entry point
├── bootstrap.dart               # config → chrome → Firebase → DI → runApp
├── firebase_options.dart        # placeholder until `flutterfire configure`
│
├── app/                         # composition root
│   ├── app.dart                 # MaterialApp.router + global bloc providers
│   ├── di/service_locator.dart  # get_it graph
│   ├── router/                  # GoRouter, route table, auth redirect
│   └── cubit/                   # ThemeCubit, ConnectivityCubit
│
├── core/                        # shared, feature-agnostic
│   ├── config/                  # AppConfig (backend switch, currency, timings)
│   ├── theme/                   # colours, spacing scale, light/dark themes
│   ├── error/                   # AppException + Failure hierarchies
│   ├── usecase/                 # UseCase / StreamUseCase base types
│   ├── utils/                   # Result, error mapper, formatters, validators
│   ├── responsive/              # breakpoints, ContentContainer, extensions
│   ├── storage/                 # LocalStorage (SharedPreferences wrapper)
│   ├── network/                 # ConnectivityService
│   ├── notifications/           # FCM service
│   ├── observer/                # BlocObserver
│   └── widgets/                 # AppButton, AppCard, AppImage, skeletons, …
│
├── domain/                      # pure Dart — no Flutter imports
│   ├── entities/                # User, Restaurant, FoodItem, Cart, Order, …
│   ├── repositories/            # 7 abstract interfaces
│   └── usecases/                # 40+ use cases grouped by feature
│
├── data/
│   ├── models/                  # *Model extends Entity, with JSON mapping
│   ├── datasources/
│   │   ├── local/               # DemoDataSource + seed/
│   │   └── remote/              # FirestoreDataSource
│   └── repositories/            # 8 implementations
│
└── features/                    # one folder per feature
    ├── splash/ onboarding/ auth/ home/ browse/ search/
    ├── restaurant/ food/ cart/ checkout/ orders/ profile/
    ├── partner/ rider/
    ├── shell/                   # bottom nav / navigation rail
    └── shared/widgets/          # entity-aware reusable cards
```

Each feature folder holds `bloc/` and `presentation/` (with its own
`widgets/`). Entities and repository contracts are shared at `lib/domain/`
rather than duplicated per feature.

---

## State management

**BLoC / Cubit** (`flutter_bloc`), with `bloc` for the pure logic and
`bloc_concurrency` for event transformers.

Three blocs are hoisted to the app root because more than one screen depends on
them — the session (`AuthBloc`), the basket (`CartBloc`) and the theme
(`ThemeCubit`). Everything else is created by `BlocProvider` at the screen that
owns it, so its lifetime matches the route.

Blocs are **not** registered in the service locator. They resolve their use
cases from it, which keeps their dependencies explicit and their construction
testable.

Cubits are used where a screen has one action (`FoodDetailCubit`,
`OrdersCubit`); full blocs where there are several distinct events
(`CartBloc`, `PartnerBloc`, `SearchBloc`).

Notable patterns in here:

- **Optimistic updates** — the favourite heart and the sold-out switch flip
  immediately and revert only if the write fails.
- **Debounced, restartable search** — `restartable()` plus a 320 ms delay means
  only the newest query is ever in flight.
- **Cart conflict as state** — adding a dish from a second restaurant emits a
  `pendingConflict` rather than silently replacing the basket; confirming
  replays the original event.
- **Refresh without flicker** — pull-to-refresh keeps the previous feed on
  screen instead of dropping back to skeletons.

---

## The demo backend

`DemoDataSource` is a real backend as far as the rest of the app is concerned:
it holds mutable state, applies configurable latency so loading states are
actually visible, emits change streams, and **drives orders forward on a
timer**. Place an order and watch it walk through confirmed → preparing → out
for delivery → delivered on its own, with a rider assigned the moment the
kitchen hands it over.

Seed data (`lib/data/datasources/local/seed/`):

| Data | Count | Notes |
|---|---|---|
| Restaurants | 20 | Real Klang Valley venues, cuisines, fees, ETAs, opening hours |
| Dishes | 100 | 5 per restaurant, with ingredients, allergens, calories, spice level |
| Categories | 11 | Malaysian, Pizza, Burger, Indian, Chinese, Japanese, Thai, Korean, Desserts, Drinks, Healthy |
| Reviews | ~160 | Generated from a fixed seed, so identical on every launch |
| Orders | ~22 | Customer history, one live order, partner queues, rider jobs |
| Users | 3 | One per role |
| Promos | 5 | Including one expired, to demo the rejection path |

Prices are in MYR and the whole catalogue is deliberately Malaysian — Kampung
Baru nasi lemak, Jalan Alor char kuey teow, Bangsar banana leaf, Pavilion dim
sum.

Since the demo ships without bundled photography and must work offline,
`AppImage` renders a **deterministic gradient plate with the dish's emoji** when
no URL is available — same input, same artwork, every time. Supply real URLs
(or point it at Firebase Storage) and the same widget switches to
`CachedNetworkImage` with a shimmer placeholder.

**Offline support:** the catalogue repository is offline-first. It tries the
remote source, writes what came back to `SharedPreferences`, and falls back to
that cache when the device is offline or the call throws. The cart, session,
favourites and addresses are persisted too, so a browser refresh or app kill
loses nothing.

---

## Firebase backend

Firebase is **wired but off by default**, so a fresh clone runs without a
project. The code is real, not a stub:

| File | Covers |
|---|---|
| `lib/data/datasources/remote/firestore_data_source.dart` | Firestore reads/writes, collection-group queries, Storage uploads, callable Cloud Functions, error translation |
| `lib/data/repositories/firebase_auth_repository.dart` | Firebase Auth + a Firestore `users/{uid}` profile document |
| `lib/core/notifications/push_notification_service.dart` | FCM permissions, token refresh, topics, foreground/background handlers |
| `lib/firebase_options.dart` | Placeholder until `flutterfire configure` overwrites it |

To switch over:

```bash
dart pub global activate flutterfire_cli
flutterfire configure          # regenerates lib/firebase_options.dart
```

then set `backend: Backend.firebase` in `lib/core/config/app_config.dart`.

`bootstrap.dart` refuses to initialise with placeholder credentials and falls
back to the demo backend with a log line, so a half-finished setup degrades
gracefully instead of showing a black screen.

Full walkthrough — Firestore collection layout, security rules, the Cloud
Functions the app calls, and FCM setup per platform:
**[docs/SETUP.md](docs/SETUP.md)**.

---

## Deployment

Two GitHub Actions pipelines, both gated on `flutter analyze` and `flutter test`
so a red suite never ships.

| Workflow | Trigger | Ships to |
|---|---|---|
| [`deploy-web.yml`](.github/workflows/deploy-web.yml) | push to `main` | **GitHub Pages** → https://jssuthahar.github.io/food-delivery-app/ |
| [`android-distribute.yml`](.github/workflows/android-distribute.yml) | push to `main` | **Firebase App Distribution** → tester group `testers` |

**Web** needs no secrets — set *Settings → Pages → Source* to **GitHub Actions**
and push. The base href is derived from the repository name, so forks work
unchanged, and the app uses hash-based routing, so no server rewrites are needed.

**Android** ships to Firebase app
`1:846777623577:android:8fefdbc82283d5ec6a7688`. It needs one secret,
`FIREBASE_SERVICE_ACCOUNT` (a service-account JSON with the *Firebase App
Distribution Admin* role). Release signing is optional — supply
`ANDROID_KEYSTORE_BASE64` and friends and the build is properly signed;
omit them and it falls back to the debug keystore, which App Distribution still
accepts for internal testers.

Both are also runnable from the **Actions** tab, and the Android one takes
release notes and a tester group as inputs.

Full instructions, including how to mint each secret:
**[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)**.

---

## Responsive design

One codebase, three layouts, driven by `lib/core/responsive/`:

| Breakpoint | Width | Layout |
|---|---|---|
| Mobile | < 720 | Bottom navigation, single-column lists, 2-up grids |
| Tablet | 720–1100 | Navigation rail, 3-up grids, wider gutters |
| Desktop web | > 1100 | Navigation rail, 4-up grids, content capped at 1180 px |

`ContentContainer` centres and width-caps content so the app reads well in a
maximised browser window while staying edge-to-edge on phones. Text scaling is
clamped to 0.85–1.35 so a large accessibility setting cannot break dense price
rows.

---

## Testing

87 tests across five suites, all green:

```bash
flutter test
flutter analyze     # zero issues
```

| Suite | Covers |
|---|---|
| `test/domain/` | Cart pricing (fees, caps, discounts, promo eligibility), order status machine |
| `test/data/seed_data_test.dart` | Seed integrity — counts, unique ids, referential integrity, reconciled totals, determinism |
| `test/data/demo_backend_test.dart` | Repositories against the real demo backend: filtering, search, cart persistence, order placement, partner flow |
| `test/bloc/` | `CartBloc` — conflict handling, replay-after-clear, promo rejection |
| `test/widget/` | Reusable widgets, plus full app smoke tests and an end-to-end order journey |

The widget tests boot the **real** app — real DI graph, real router, real blocs,
real backend — and walk the primary flows. They earned their keep: writing them
surfaced eight genuine defects that the compiler, the analyzer and a successful
web build had all missed, including a `Material` assertion in `AppCard` that
crashed nearly every screen, a `RangeError` in the order-number formatter, an
`AnimationController` being constructed inside `dispose()`, a connectivity probe
that could hang the entire catalogue load, and four layout overflows.

---

## Screenshots

Not included. Generating them requires running the app against a device or
browser and capturing frames, which this build has not done — so rather than
ship placeholder images, here is how to produce them:

```bash
flutter run -d chrome                       # then use your OS screenshot tool
flutter run -d <device-id>                  # or a real device / simulator
```

For automated capture, add `integration_test` and use
`binding.takeScreenshot()`; the smoke tests in `test/widget/app_smoke_test.dart`
already navigate to every screen worth capturing and can be adapted directly.

---

## A note on the brief

The brief asked for **BLoC** in its opening line and **Riverpod** in the
technical requirements. This build uses **BLoC** (`flutter_bloc`), taking the
direct instruction as the intent. The architecture is state-management-agnostic
below the presentation layer — the domain and data layers have no idea which is
in use — so a Riverpod port would touch only `lib/features/*/bloc/` and the
providers in `app.dart`.

Two smaller judgement calls worth flagging:

- **Firebase is off by default.** Making it the default would mean the project
  does not run without a Firebase project, API keys and a `flutterfire
  configure` run — which is a poor first impression for a portfolio piece. The
  integration is written and documented; flipping one enum turns it on.
- **Images are generated, not bundled.** See [the demo backend](#the-demo-backend)
  above for the reasoning.

---

## Tech stack

`flutter_bloc` · `bloc_concurrency` · `equatable` · `get_it` · `go_router` ·
`google_fonts` · `cached_network_image` · `shimmer` · `intl` ·
`shared_preferences` · `connectivity_plus` · `firebase_core` / `auth` /
`cloud_firestore` / `storage` / `functions` / `messaging` · `bloc_test` ·
`mocktail` · `flutter_lints`

## Licence

MIT — see [LICENSE](LICENSE).
