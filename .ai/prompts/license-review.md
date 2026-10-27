<!-- Open Source License Compliance Agent -->

Resolved dependency tree with SPDX identifiers: `flutter pub deps --json`.
How we ship: an APK through Firebase App Distribution, and a static web build
on GitHub Pages. Both are binaries handed to a user; neither is a hosted
service we operate on their behalf.
Policy: deny GPL-2.0, GPL-3.0, AGPL, SSPL, CC-BY-NC, BUSL. Attribution
required for MIT, BSD, Apache-2.0.

The deny-list check runs in `.githooks/pre-push`. Do NOT repeat it.
Answer only the questions a list cannot:

1. Any license whose obligations change because of HOW we ship. We ship a
   binary to devices AND a JavaScript bundle to a browser — say where those
   differ. One sentence each.
2. For every attribution-required package: exactly what we must publish, and
   where it has to appear. This app has an about dialog and a profile tab;
   say which one, or say a `NOTICE` file is required instead.
3. For anything on the deny list: two replacement candidates each, with the
   migration cost and what we lose.
4. Licenses you are not confident about. Name them and stop — that is the list
   that goes to a lawyer.

Specific to this repo:

- `google_fonts` downloads Inter at runtime on some platforms and bundles it on
  others. The font's licence and the package's licence are different questions.
  Answer both.
- The web build inlines its dependencies into `main.dart.js`. Say whether that
  changes any attribution obligation compared to the APK.

Never say a license is "generally acceptable". Either it fits the policy and
the shipping model, or it goes to a human.
