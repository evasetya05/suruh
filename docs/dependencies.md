# Dependencies

One line per package: why it is here, and what removing it would cost.

`.githooks/pre-commit` fails a commit that adds a package to `pubspec.yaml`
without a row in this table. That is the whole intervention — a written reason
at the moment of adding, while you still remember it.

Produced and maintained with [`.ai/prompts/dependencies.md`](../.ai/prompts/dependencies.md).

## Runtime

| Package | Why it is here | Imported in | Removal cost |
|---|---|---|---|
| `flutter_bloc` | State management for every feature | ~30 files | Very high — architectural |
| `bloc` | Pure logic layer under `flutter_bloc` | Indirect | Very high — comes with the above |
| `bloc_concurrency` | `restartable()` for debounced search | `search/bloc` | Low — hand-roll a debounce |
| `equatable` | Value equality on entities and states; `props` is what stops needless rebuilds | Everywhere in `domain` and `bloc` | High — hand-written `==` everywhere |
| `get_it` | The DI graph in `lib/app/di/service_locator.dart` | 1 file + call sites | Medium — constructor injection through the widget tree |
| `go_router` | Declarative routes and the auth redirect | `lib/app/router/` | Medium — `Navigator` 1.0 loses the redirect guard |
| `google_fonts` | Inter, via `app_theme.dart` | 1 file | Low — bundle the font and drop the package |
| `cached_network_image` | Dish and restaurant imagery with a disk cache | `core/widgets/app_image.dart` | Low — `Image.network` loses the cache |
| `shimmer` | Loading skeletons | `core/widgets/` | Low — an animated container does the same |
| `url_launcher` | The article and profile links out of the app | 1 file | Very low |
| `intl` | Currency and date formatting for MYR | `core/utils/formatters.dart` | Medium — locale-aware formatting is easy to get wrong by hand |
| `uuid` | IDs for demo-backend entities | `data/datasources/local/` | Very low — a counter would do |
| `collection` | `firstWhereOrNull` and friends | Several | Very low |
| `shared_preferences` | Session, cart, theme, onboarding flag | `core/storage/` | High — the only persistence the demo backend has |
| `connectivity_plus` | Offline detection for the cached catalogue | `core/network/` | Low — but the offline banner goes with it |

## Firebase (optional at runtime)

These six are one decision, not six. `AppConfig.backend` defaults to
`Backend.demo` and the app runs with no Firebase project at all.

| Package | Why it is here |
|---|---|
| `firebase_core` | Initialisation, guarded by the backend switch |
| `firebase_auth` | `FirebaseAuthRepository`, the second `AuthRepository` implementation |
| `cloud_firestore` | `FirestoreDataSource` |
| `firebase_storage` | Dish photography upload from the partner dashboard |
| `cloud_functions` | `placeOrder`, so a tampered client cannot invent its own totals |
| `firebase_messaging` | Order status push notifications |

## Dev

| Package | Why it is here |
|---|---|
| `flutter_test` | The SDK test harness |
| `bloc_test` | `blocTest` — the state-sequence assertions in `test/bloc/` |
| `mocktail` | Mocking use cases without code generation |
| `flutter_lints` | The lint baseline in `analysis_options.yaml` |
