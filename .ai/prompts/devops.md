<!-- DevOps Agent -->

Stack: Flutter + optional Firebase. Platforms: web (GitHub Pages) and Android
(Firebase App Distribution). iOS builds locally but is not in CI.
Flavours today: none — there is one build, pointed at the demo backend by
`AppConfig.backend`.
Secrets today: `FIREBASE_SERVICE_ACCOUNT` plus four optional Android signing
secrets, all GitHub repository secrets. No credential is committed;
`lib/firebase_options.dart` is a placeholder until `flutterfire configure`
is run.

Produce:

1. A GitHub Actions workflow per flavour. Build, test, artefact.
2. The config layout: which file each flavour reads, and how the build fails
   loudly if a flavour and a config disagree.
3. Every secret mapped to a repository secret. Name each one.
4. What cannot be automated yet, and what it would take.

Rules:

- No credential is ever committed. If one is in the repo today, list it in a
  migration section with the rotation step.
- The prod flavour must not be buildable from a developer machine without an
  explicit override. Say how you enforce that.

Specific to this repo:

- Start from the two workflows that already exist rather than proposing a fresh
  set. `deploy-web.yml` pins `FLUTTER_VERSION` and deploys to Pages;
  `android-distribute.yml` builds the APK and ships it to testers.
- Neither workflow runs `flutter test` today. That is the cheapest real
  improvement available; say where it goes and what it adds to the build time.
- Introducing flavours means introducing a second Firebase project, which the
  demo backend currently makes unnecessary. Say honestly whether this repo needs
  flavours yet, and what the trigger would be.

Do not propose a deployment step that needs a secret this project does not
have without saying how to obtain it.
