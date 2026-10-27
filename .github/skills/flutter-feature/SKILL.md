---
name: flutter-feature
description: >
  Use when adding or changing a feature screen in the MSDevBuild Eats Flutter
  app. Enforces the layered structure (pure-Dart lib/domain, lib/data,
  lib/features/{feature}/{bloc,presentation}), state in a Bloc or Cubit, and
  Firebase reached only through a repository. Every bloc gets a bloc_test.
  Trigger phrases: "add screen", "new feature", "add page", "Firestore",
  "cubit", "bloc", "list from Firebase".
---

# Building a Flutter feature the way we build it

## Purpose

Add or change a feature screen so it matches our architecture on the first try:
a pure-Dart domain contract, a repository implementation in `lib/data`, a use
case, a Cubit or Bloc for state, a screen that only renders, and a test.

## When to use

- Adding a new screen or page tied to data (a list, a detail view, a form).
- Adding a Cubit or Bloc for a feature's state.
- Wiring a screen to Firestore through a repository.

## When NOT to use

- Pure package or build config work (`pubspec.yaml`, Gradle, iOS pods).
- App-wide theming, routing setup, or localisation.
- Anything in `lib/app/` — that is the composition root, and it is reviewed
  differently.

## Inputs required

Before generating code, confirm you know:

- Feature name (e.g. Orders, Cart, Profile).
- Does it need Firebase/Firestore? If yes, which collection.
- The entity fields and their types.
- The screen type: list, detail, or form.
- Loading, empty, and error states the UI must show.

If any of these is unclear, ask one short question before writing code.

## Rules (non-negotiable)

- Entities, repository interfaces and use cases in `lib/domain` — pure Dart,
  no `package:flutter/` import.
- Implementations in `lib/data`. Screens and blocs in
  `lib/features/{feature}/{bloc,presentation}`.
- Nothing in `lib/features` imports from `lib/data`. It talks to use cases.
- The UI never calls `FirebaseFirestore` directly.
- Repositories and use cases return `Result<T>`, never throw. Data sources
  throw `AppException`; the repository maps it through `guard()`.
- State lives in a Bloc or Cubit, never `setState`.
- Orchestration lives in a use case, not the bloc. A bloc asks for one thing.
- Blocs are NOT registered in `get_it`. They resolve use cases from it and are
  created by `BlocProvider` at the screen that owns them.
- State classes extend `Equatable` and list every field in `props`.
- `build()` stays cheap. `ListView.builder` for anything long.
- Every bloc ships with a `bloc_test` covering loading, data and failure.

## Workflow

1. `lib/domain/entities` — the immutable entity.
2. `lib/domain/repositories` — the interface method, returning `Result<T>`.
3. `lib/data` — the model with JSON mapping and the repository implementation,
   wrapped in `guard()`.
4. `lib/domain/usecases` — the use case the screen needs.
5. `lib/features/{feature}/bloc` — the Cubit/Bloc and its state class.
6. `lib/features/{feature}/presentation` — `BlocProvider` at the top,
   `BlocBuilder` rendering loading / data / error.
7. `test/bloc` — a `bloc_test` with a mocked use case. No emulator.
8. Run the validation checklist below.

## The pattern to copy

Read these before writing anything. They are the reference implementation:

- `lib/domain/repositories/order_repository.dart` — contract shape
- `lib/data/repositories/order_repository_impl.dart` — `guard()` usage
- `lib/features/orders/bloc/orders_cubit.dart` — `fold` over both paths
- `lib/features/orders/presentation/orders_screen.dart` — provider + builder
- `test/bloc/cart_bloc_test.dart` — `blocTest` with mocked use cases

## Validation checklist

Before finishing, confirm every item:

- [ ] No `package:flutter/` import anywhere in `lib/domain`.
- [ ] No file in `lib/features` imports from `lib/data`.
- [ ] Repository and use case return `Result<T>`; nothing throws upward.
- [ ] State is a Bloc/Cubit, not `setState`, and is not in `get_it`.
- [ ] The state class extends `Equatable` and lists every field in `props`.
- [ ] `build()` has no queries or heavy work.
- [ ] A `bloc_test` covers loading, data and failure with a mocked use case.
- [ ] `flutter analyze` is clean.

## Expected output

A correct result for a new "Orders" feature produces:

- `lib/domain/entities/order.dart`
- `lib/domain/repositories/order_repository.dart`
- `lib/domain/usecases/order_usecases.dart`
- `lib/data/models/order_model.dart`
- `lib/data/repositories/order_repository_impl.dart`
- `lib/features/orders/bloc/orders_cubit.dart` (+ `orders_state.dart`)
- `lib/features/orders/presentation/orders_screen.dart`
- `test/bloc/orders_cubit_test.dart`
