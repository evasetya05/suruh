# Architecture

How MSDevBuild Eats is put together, and why.

- [The dependency rule](#the-dependency-rule)
- [Layers](#layers)
- [The error contract](#the-error-contract)
- [Result instead of throwing](#result-instead-of-throwing)
- [Why use cases exist](#why-use-cases-exist)
- [State management](#state-management)
- [Dependency injection](#dependency-injection)
- [Navigation and route guarding](#navigation-and-route-guarding)
- [Offline-first data flow](#offline-first-data-flow)
- [Swapping the backend](#swapping-the-backend)
- [Theming and responsiveness](#theming-and-responsiveness)
- [Trade-offs](#trade-offs)

---

## The dependency rule

Dependencies point **inward only**. The domain layer is the centre and knows
nothing about anything else — it does not even import Flutter.

```
       ┌──────────────────────────────────────┐
       │           PRESENTATION               │
       │   lib/features/<feature>/            │
       │   screens · widgets · blocs          │
       └──────────────┬───────────────────────┘
                      │  depends on
       ┌──────────────▼───────────────────────┐
       │              DOMAIN                  │
       │   lib/domain/                        │
       │   entities · contracts · use cases   │
       │   (pure Dart)                        │
       └──────────────▲───────────────────────┘
                      │  implements
       ┌──────────────┴───────────────────────┐
       │               DATA                   │
       │   lib/data/                          │
       │   models · data sources · repo impls │
       └──────────────────────────────────────┘
```

Concretely, this means:

- No file under `lib/domain/` imports `package:flutter/*`, Firebase, or
  `shared_preferences`.
- No file under `lib/features/` imports anything from `lib/data/`, except two
  deliberate exceptions noted under [Trade-offs](#trade-offs).
- `lib/data/` implements interfaces declared in `lib/domain/repositories/`.

You can verify the first rule at any time:

```bash
grep -rn "package:flutter/" lib/domain/     # expect no matches
```

---

## Layers

### Domain — `lib/domain/`

Pure Dart. Three kinds of thing:

**Entities** (`entities/`) — `User`, `Address`, `Restaurant`, `FoodItem`,
`FoodCategory`, `Cart`/`CartItem`, `Order`, `Review`, `Promo`. All `Equatable`,
all immutable, all with `copyWith`.

Entities carry the business rules that belong to them:

- `Cart` computes subtotal, service fee, small-order fee, promo discount and
  total. `PricingPolicy` holds the fee constants next to it.
- `OrderStatus` owns its own state machine — `next`, `isTerminal`,
  `trackingStages`. The partner's "advance order" button, the customer's
  timeline and the rider's job card all read from that one definition.
- `Promo.discountFor(subtotal)` applies percentage, cap and minimum spend.
- `RatingSummary.fromReviews` aggregates a star distribution.

This is why `test/domain/` can test the app's most consequential logic — every
number the customer is charged — with no mocks, no widgets and no I/O.

**Repository interfaces** (`repositories/`) — seven contracts: `AuthRepository`,
`CatalogRepository`, `CartRepository`, `OrderRepository`, `ReviewRepository`,
`UserRepository`, `PartnerRepository`. Each returns `Result<T>` or a `Stream`.

**Use cases** (`usecases/`) — 40+, grouped by feature. See
[Why use cases exist](#why-use-cases-exist).

### Data — `lib/data/`

**Models** (`models/`) — `RestaurantModel extends Restaurant`, and so on. Models
*extend* their entity rather than duplicating fields, so data flows straight
through without a mapping step, while JSON concerns stay out of the domain.

**Data sources** (`datasources/`):

- `local/demo_data_source.dart` — the seeded in-memory backend. Mutable stores,
  simulated latency, broadcast streams, and a timer that advances live orders.
- `local/seed/` — the seed corpus: 20 restaurants, 100 dishes, 11 categories,
  3 personas, 5 promos, plus deterministic generators for ~160 reviews and ~22
  orders.
- `remote/firestore_data_source.dart` — Firestore, Storage and Cloud Functions.

**Repository implementations** (`repositories/`) — eight classes that translate
between data sources and domain contracts, apply caching policy, and convert
exceptions into failures.

### Presentation — `lib/features/`

One folder per feature, each with `bloc/` and `presentation/` (and
`presentation/widgets/` for screen-specific pieces).

`features/shared/widgets/` holds entity-aware widgets used by four or more
screens — `RestaurantCard`, `DishCard`, `CategoryTile`, `PromoCarousel`. These
live outside `core/widgets/` precisely because they know about domain entities,
and `core/` should not.

---

## The error contract

There are two error hierarchies, and they never mix.

```
 Data source                Repository                Bloc / UI
 ───────────                ──────────                ─────────
 throws AppException  ──►   guard() catches      ──►  Result.failure(Failure)
   NetworkException           mapErrorToFailure         renders failure.message
   ServerException            translates once
   CacheException
   AuthException
   NotFoundException
```

`AppException` (`core/error/exceptions.dart`) is infrastructure-level and is
thrown by data sources. `Failure` (`core/error/failures.dart`) is domain-level
and is *returned*, never thrown, with a message that is safe to show a user.

The translation happens in exactly one function, `mapErrorToFailure`
(`core/utils/error_mapper.dart`), used by the `guard` helper that wraps every
repository method:

```dart
Future<Result<List<Restaurant>>> getRestaurants([RestaurantFilter filter = …]) {
  return guard<List<Restaurant>>(() async {
    final List<RestaurantModel> all = await _loadRestaurants();
    return _applyFilter(all, filter, foods);
  });
}
```

`FirestoreDataSource` maps `FirebaseException` codes onto the same
`AppException` types (`unavailable` → `NetworkException`, `permission-denied` →
`ServerException`, and so on), which is what lets the repositories work against
either backend unchanged.

---

## Result instead of throwing

```dart
sealed class Result<T> {
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;
}
```

Sealed, so `switch` over it is exhaustive. Every repository method and every use
case returns one. The benefit is that a failure path is part of the type
signature — you cannot call a use case and forget that it can fail, the way you
can with an exception.

Blocs consume it with `fold`:

```dart
result.fold(
  (Failure failure) => emit(state.copyWith(errorMessage: failure.message)),
  (HomeFeed feed) => emit(state.copyWith(feed: feed, status: HomeStatus.success)),
);
```

---

## Why use cases exist

A use case that only forwards to a repository is ceremony. Most of these do
real work:

**`GetHomeFeed`** fans six repository calls out in parallel with `Future.wait`,
fails fast if any of them fail, and hands back one `HomeFeed`. `HomeBloc` asks
for "the home feed" and never learns it was six calls.

**`GetRestaurantDetail`** loads the restaurant, then its menu, reviews and the
category taxonomy concurrently, then **groups the menu into sections** in
catalogue order, dropping sections the restaurant has no dishes for. That
grouping is business logic, not layout, so it belongs here rather than in a
widget's `build`.

**`PlaceOrder`** validates the basket, creates the order, and **then clears the
cart** — only on success. Clearing the cart is deliberately part of the use case
rather than the UI, because an order that exists with a stale basket behind it is
a real bug class.

**`AddToCart`** refuses sold-out dishes and closed restaurants before the
repository is involved.

**`ApplyPromoCode`** resolves a typed string against the promo catalogue,
checks expiry, loads the cart to check minimum spend, and only then applies it —
four steps the UI would otherwise have to sequence itself.

**`SubmitReview`** writes the review *and* flags the order as rated, so the
"Rate your order" prompt disappears.

**`UpdateCartQuantity`** routes quantity 0 to `removeLine`, which is what makes
the stepper's minus button turn into a delete at quantity 1.

Validation lives here too: `SignIn` and `Register` check input with
`Validators` before spending a network round-trip.

---

## State management

BLoC, with three blocs hoisted to the app root in `app.dart` because more than
one screen depends on them:

| Bloc | Why it is global |
|---|---|
| `AuthBloc` | The router reads it to guard routes; every screen reads the user |
| `CartBloc` | The badge, menu rows, cart, checkout and restaurant bar all read one basket |
| `ThemeCubit` | Applies to `MaterialApp` itself |
| `ConnectivityCubit` | Drives the shell's offline banner |

Everything else is created by `BlocProvider` at the screen that owns it, so the
bloc's lifetime matches the route's.

**Blocs are not registered in the service locator.** They resolve their use
cases from it in their constructor call. That keeps every dependency visible in
one place and makes them trivial to construct in tests with mocks.

Cubit vs Bloc is decided by surface area: `FoodDetailCubit` and `OrdersCubit`
have one action each, so event classes would be noise. `CartBloc`,
`PartnerBloc`, `SearchBloc` and `AuthBloc` have several distinct events and use
the full pattern.

### Patterns worth pointing at

**Optimistic updates with rollback** — `RestaurantBloc` flips the favourite
heart immediately and reverts only if the write fails. `PartnerBloc` does the
same for the sold-out switch. Waiting on a round-trip for a heart tap feels
broken.

**Debounced, restartable search** — `SearchBloc` uses `restartable()` from
`bloc_concurrency` plus a 320 ms delay, so only the newest query is ever in
flight and a fast typist cannot get an earlier keystroke's results landing last.

**Conflict as state, not a dialog side-effect** — adding a dish from a second
restaurant emits `pendingConflict` carrying the original event. The UI turns
that into a confirm dialog; confirming dispatches `CartCleared`, which clears
and then **replays the stored event**. The rule lives in the bloc; the dialog is
just a view of it.

**Refresh without flicker** — `HomeBloc` distinguishes `HomeRequested` (show
skeletons) from `HomeRefreshed` (keep the current feed, set `isRefreshing`). A
failed refresh keeps the stale feed and surfaces a message rather than blanking
the screen.

**Derived state on the state object** — `PartnerState.liveTodayRevenue` is
computed from the live order stream rather than the fetched stats snapshot, so a
new order updates the tile immediately.

---

## Dependency injection

`get_it`, wired in `lib/app/di/service_locator.dart`. Registration order mirrors
the dependency direction: services → data sources → repositories → use cases.

```dart
sl
  ..registerSingleton<LocalStorage>(storage)
  ..registerLazySingleton<ConnectivityService>(ConnectivityService.new);

sl.registerLazySingleton<CatalogRepository>(
  () => CatalogRepositoryImpl(
    remote: sl<DemoDataSource>(),
    storage: sl<LocalStorage>(),
    connectivity: sl<ConnectivityService>(),
  ),
);

sl.registerFactory(() => GetHomeFeed(sl<CatalogRepository>()));
```

Repositories are lazy singletons (one instance, created on first use). Use cases
are factories — they are stateless and cheap.

`ServiceLocator.reset()` tears the graph down, which is what lets the widget
tests boot the whole app repeatedly with a clean backend each time.

---

## Navigation and route guarding

`GoRouter`, configured in `lib/app/router/app_router.dart`. Every path lives in
`route_paths.dart`, so no navigation call contains a string literal that can
drift.

The router is constructed *with* the `AuthBloc` rather than reading it from
context, so `redirect` can run synchronously:

```dart
redirect: (context, state) {
  final AuthState auth = authBloc.state;
  final String location = state.matchedLocation;

  // Hold on splash until the session is resolved.
  if (!auth.isResolved) return location == Routes.splash ? null : Routes.splash;

  if (!auth.isAuthenticated) {
    if (Routes.isPublic(location) && location != Routes.splash) return null;
    return hasSeenOnboarding ? Routes.login : Routes.onboarding;
  }

  // Signed in: keep each persona inside its own section.
  return switch (auth.role) {
    UserRole.restaurantPartner when !isPartnerRoute => roleHome,
    UserRole.deliveryPartner    when !isRiderRoute  => roleHome,
    UserRole.customer when isPartnerRoute || isRiderRoute => roleHome,
    _ => null,
  };
}
```

This gives three properties for free: deep-linking to `/checkout` while signed
out lands on `/login`; the splash screen never navigates on a timer (which
avoids the classic race where a slow session restore flashes the login screen);
and a partner cannot reach the customer tabs by typing a URL.

`_BlocRefreshListenable` bridges the bloc stream to `Listenable` so the router
re-evaluates `redirect` whenever the session changes.

The four customer tabs sit inside a `ShellRoute` with a cross-fade transition;
detail screens are pushed above it on the root navigator.

---

## Offline-first data flow

`CatalogRepositoryImpl` reads remote-first with a cache fallback:

```
   read
    │
    ├─ offline?  ──yes──►  cached data (if any)
    │
    └─ try remote
         ├─ success ──►  write to LocalStorage, stamp, return
         └─ throws  ──►  cached data, or NetworkFailure if the cache is cold
```

`LocalStorage` wraps `SharedPreferences` and owns every storage key and all
JSON encoding, so there is one place that knows how persistence works.

What survives a restart: the session, the cart (written on every mutation), the
catalogue cache, favourites, addresses, recent searches, the onboarding flag and
the theme choice. On web that means a browser refresh loses nothing.

`ConnectivityService` probes with an 800 ms timeout and assumes online on
failure. That timeout is not cosmetic — without it an unresponsive platform
channel leaves the future hanging and every catalogue read blocked behind it.

---

## Swapping the backend

The repository interface is the swap point, and `AuthRepository` demonstrates it
with two live implementations:

```dart
sl.registerLazySingleton<AuthRepository>(
  () => useFirebase
      ? FirebaseAuthRepository(remote: sl<FirestoreDataSource>(), storage: sl<LocalStorage>())
      : AuthRepositoryImpl(remote: sl<DemoDataSource>(), storage: sl<LocalStorage>()),
);
```

`useFirebase` comes from `AppConfig.instance.backend`. No screen, bloc or use
case changes.

`FirestoreDataSource` mirrors `DemoDataSource`'s surface — same method names,
same return types, same exception types — which is what makes the remaining
repositories portable. Firestore collection layout is documented in
[SETUP.md](SETUP.md).

`bootstrap.dart` guards the switch: if `Backend.firebase` is selected but
`firebase_options.dart` still holds placeholders, it logs and falls back to the
demo backend rather than failing to start.

---

## Theming and responsiveness

**Theme.** `AppTheme.light` / `AppTheme.dark` define every component theme —
buttons, inputs, cards, chips, dialogs, snackbars, tabs. Screens never hard-code
a colour; everything resolves through `Theme.of(context)`, which is why dark
mode needed no per-widget branching. `AppColors` holds the palette (Grab green
`#00B14F`), `AppSpacing` a 4pt scale, `AppRadius` the corner radii.

**Responsive.** `lib/core/responsive/responsive.dart` provides a `DeviceType`
bucket and a `context.responsive(mobile:, tablet:, desktop:)` helper, plus
`context.gutter` and `context.gridColumns`. `ContentContainer` centres and
width-caps content at 1180 px so the app reads well maximised in a browser while
staying edge-to-edge on phones.

Text scaling is clamped to 0.85–1.35 in `app.dart`. Several layouts use `Wrap`
rather than `Row` specifically so they survive the upper end of that range —
those were not guesses, they were overflows the widget tests caught.

---

## Trade-offs

**`kSeedCategories` is imported by two presentation files.** The partner menu
screen and the menu editor read the category taxonomy directly from
`lib/data/`, which breaks the dependency rule. The clean fix is a
`GetCategories` use case injected into `PartnerBloc`. It is called out here
rather than hidden.

**Filtering and sorting happen client-side.** The demo catalogue is 20 records,
so `_applyFilter` sorts in memory. Against Firestore this maps to composite
`where` clauses plus an `orderBy`; the `CatalogRepository` contract does not
change.

**`DemoDataSource` is a singleton.** Convenient for a demo — state persists
across screens without a server — but it means tests share mutable state and
must call `reset()` in `setUp`.

**Blocs are not in the service locator.** Deliberate: their lifetime should
follow the widget tree, not the process. The cost is a little more wiring at
each `BlocProvider`.

**One `Cart` per restaurant.** Enforced in `CartRepositoryImpl`, mirroring how
Grab behaves. Multi-restaurant baskets would need a cart-per-restaurant model
and a merged checkout.
