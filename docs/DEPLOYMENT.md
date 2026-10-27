# Deployment

Two pipelines ship this project, both defined under [.github/workflows/](../.github/workflows/):

| Workflow | Trigger | Output | Published at |
| --- | --- | --- | --- |
| [`deploy-web.yml`](../.github/workflows/deploy-web.yml) | push to `main`, or manual | GitHub Pages site | <https://jssuthahar.github.io/food-delivery-app/> |
| [`android-distribute.yml`](../.github/workflows/android-distribute.yml) | push to `main`, or manual | Release APK to Firebase App Distribution testers | <https://appdistribution.firebase.dev/i/00432c5aa60de58b> |

The Android link is the App Distribution tester invitation — share it with
anyone who should get builds. It is tied to the tester group, not to a single
release, so it keeps pointing at the newest build without being reissued.

Both gate on `flutter analyze` and `flutter test` before building, so a red suite
never reaches testers.

---

## 1. Web → GitHub Pages

**Live URL:** <https://jssuthahar.github.io/food-delivery-app/>

### One-time setup

**This must be done by hand once, before the first run:**

1. Repository **Settings → Pages**.
2. **Build and deployment → Source**: select **GitHub Actions** (not "Deploy from a branch").

There is no way around it in the workflow. `actions/configure-pages` accepts an
`enablement: true` flag, but creating a Pages site is a repo-admin operation that
`GITHUB_TOKEN` is not granted, so it fails with:

```text
HttpError: Resource not accessible by integration
Create Pages site failed.
```

After the toggle is set, no secrets and no `gh-pages` branch are needed. The app
runs on the seeded offline demo backend, so the published site is fully
functional without Firebase.

Two related failure messages, both meaning the same thing — Pages is not enabled
yet:

```text
Error: Get Pages site failed. Please verify that the repository has Pages
enabled and configured to build using GitHub Actions
```

### How it works

- `--base-href "/<repo-name>/"` is derived from `github.event.repository.name`,
  so forks and renames keep working without editing the workflow. Getting this
  wrong is the classic Pages failure: a white screen with 404s on every asset.
- The app uses Flutter's default hash-based URL strategy (`/#/home`), which
  needs no server rewrites. `404.html` is copied anyway as insurance in case
  someone later switches to `usePathUrlStrategy()`.
- `.nojekyll` stops Pages from running the bundle through Jekyll.
- `--build-number ${{ github.run_number }}` makes each deploy traceable.

### Deploying manually

```bash
flutter build web --release --base-href "/food-delivery-app/"
# serve build/web with any static host
```

---

## 2. Android → Firebase App Distribution

**Firebase Android app ID:** `1:846777623577:android:8fefdbc82283d5ec6a7688`
**Package name:** `com.msdvbuild.food` — must match the Firebase app exactly, or the upload is rejected

The app ID is committed in the workflow's `env` block and in
[`lib/firebase_options.dart`](../lib/firebase_options.dart). It is not a secret —
an app ID identifies an app, it does not authorise anything.

**Firebase project:** `msdevbuild-demo`

### Required secret

`FIREBASE_SERVICE_ACCOUNT` — the full JSON key for a service account allowed to
publish releases.

> **Do not reuse the Firebase Admin SDK key** (the
> `<project>-firebase-adminsdk-*.json` the console offers on the Service
> Accounts tab). It does not work for App Distribution anyway — the Admin SDK
> Service Agent role covers Firestore and Storage but not `firebaseappdistro.*`,
> so the CLI fails with:
>
> ```text
> Error: Request to https://cloudresourcemanager.googleapis.com/v1/projects/<id>
> had HTTP Error: 403, The caller does not have permission
> ```
>
> Create a separate account whose only role is *Firebase App Distribution
> Admin*. It is both the credential that works and the one with the smallest
> blast radius if it leaks.

```bash
# Google Cloud console, in the project that owns the Firebase app:
#   IAM & Admin → Service Accounts → Create service account
#   Role: "Firebase App Distribution Admin"
#   Keys → Add key → JSON → download
gh secret set FIREBASE_SERVICE_ACCOUNT < ~/Downloads/service-account.json
```

Paste the file's entire contents — the workflow writes it back out verbatim and
points `GOOGLE_APPLICATION_CREDENTIALS` at it, then deletes it in an `always()`
step.

> The older `FIREBASE_TOKEN` / `firebase login:ci` flow is deprecated and stops
> working on newer CLI versions. Use the service account.

### Tester groups

The workflow distributes to the group `testers` by default. Create it under
**Firebase console → App Distribution → Testers & Groups**, and make sure the
group alias matches — distributing to a group that does not exist fails the run.

To send a build to a different group, use **Actions → Android distribute → Run
workflow** and fill in the `groups` and `release_notes` inputs.

### Optional: release signing

Without these secrets the APK is signed with the debug keystore. App Distribution
accepts that for internal testers, but installs will not upgrade over a
previously release-signed install, and it is not suitable for Play.

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

gh secret set ANDROID_KEYSTORE_BASE64 < <(base64 -i upload-keystore.jks)
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS          # "upload"
gh secret set ANDROID_KEY_PASSWORD
```

CI writes these into `android/key.properties`;
[`android/app/build.gradle.kts`](../android/app/build.gradle.kts) picks the file
up when it exists and falls back to debug signing when it does not. Keep the
`.jks` and `key.properties` out of git — both are in `.gitignore`.

### Distributing manually

```bash
flutter build apk --release
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:846777623577:android:8fefdbc82283d5ec6a7688 \
  --release-notes "Manual build" \
  --groups testers
```

---

## Running the app against Firebase

Distribution does not require the app to *use* Firebase — the shipped APK runs
the offline demo backend. To point it at a real project:

1. `flutterfire configure` (overwrites `lib/firebase_options.dart`, including the
   placeholder API keys and project id).
2. Set `backend: Backend.firebase` in
   [`lib/core/config/app_config.dart`](../lib/core/config/app_config.dart).
3. Deploy the rules and indexes under [firebase/](../firebase/).

Full walkthrough in [SETUP.md](SETUP.md).
