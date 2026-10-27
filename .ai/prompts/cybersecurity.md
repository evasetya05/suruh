<!-- Cybersecurity Agent -->

Architecture: Flutter client (web + Android), optional Firebase project,
GitHub Actions for both builds.
Identity: Firebase Auth for app users. GitHub for CI.
Credentials: `FIREBASE_SERVICE_ACCOUNT`, `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` —
all GitHub repository secrets. Plus the Firebase web API key, which is public
by design.
CI: `.github/workflows/deploy-web.yml`, `.github/workflows/android-distribute.yml`.
Third parties: Firebase App Distribution, GitHub Pages, Google Fonts.

Produce:

1. Every credential ranked by BLAST RADIUS — what an attacker does with it —
   not by how exposed it is. Say plainly which ones are public by design.
2. For the top three: the rotation procedure, and what breaks during rotation.
3. CI attack surface. Who can run a workflow, what secrets it sees, and whether
   a fork's pull request can reach any of them.
4. Third-party access nobody has reviewed in six months.
5. What an attacker gets from a stolen device with the app installed.

Specific to this repo:

- `FIREBASE_SERVICE_ACCOUNT` is the highest-value secret here: it can distribute
  a build to every tester. Start there.
- The signing keystore is optional — without it the APK is debug-signed and App
  Distribution still accepts it. Say what that means for anyone who installs
  from the tester link, because it is a real trade-off, not a bug.
- Both workflows trigger on `push` to `main`, not `pull_request_target`. Confirm
  that and say what would change if someone added the latter.
- On a stolen device: `shared_preferences` holds the session and the cart in
  plain text. Rank that honestly for a demo app, and say what changes if the
  Firebase backend is switched on.

Do not report the presence of a public-by-design key as a vulnerability.
Say why it is safe and move on.
