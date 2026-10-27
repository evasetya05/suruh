<!-- Dependency Management Agent -->

Manifest: `pubspec.yaml`. Lock: `pubspec.lock`.
Import counts per package:

```bash
for p in $(grep -oE '^  [a-z_]+:' pubspec.yaml | tr -d ' :'); do
  echo "$p $(grep -rl "package:$p/" lib/ test/ 2>/dev/null | wc -l)"
done
```

Produce a table: package | why it is here | files importing it | last release |
removal cost (hours) | replaceable by the SDK?

Then:

1. Packages imported in ONE file for ONE function. These are the cheapest to
   remove and the most likely to be regretted.
2. Anything with no release in 18 months, and what depends on it.
3. An update order, safest first, marking the ones that need `flutter test`
   before the next step.
4. Transitive dependencies pulled in by only one direct package — say how many
   arrive per package.

Specific to this repo:

- The six `firebase_*` packages are optional at runtime. `AppConfig.backend`
  defaults to `Backend.demo` and the app ships without a Firebase project, so
  treat them as one decision, not six.
- `shimmer`, `cached_network_image` and `google_fonts` are presentation-only.
  If one of them is imported outside `lib/core/widgets` or `lib/core/theme`,
  that is a finding worth reporting even though it is not a dependency problem.
- `bloc`, `flutter_bloc`, `bloc_concurrency`, `bloc_test` and `equatable` are
  one architectural commitment. Do not propose removing them individually.

Do not recommend upgrading everything. Recommend an order.
Do not propose removing a package without naming what replaces it.
