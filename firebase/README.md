# Firebase configuration

Rules and indexes for the optional Firebase backend. None of this is needed to
run the app — it ships on a local demo backend by default. See
[../docs/SETUP.md](../docs/SETUP.md) for the full walkthrough.

## Files

| File | Purpose |
|---|---|
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Composite and collection-group indexes |
| `storage.rules` | Cloud Storage rules for dish photos and avatars |
| `functions/` | Cloud Functions — see SETUP.md for the implementations |

## Deploying

From the repository root, with `firebase.json` pointing at this directory:

```json
{
  "firestore": {
    "rules": "firebase/firestore.rules",
    "indexes": "firebase/firestore.indexes.json"
  },
  "storage": {
    "rules": "firebase/storage.rules"
  },
  "functions": {
    "source": "firebase/functions"
  },
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
firebase deploy --only functions
firebase deploy --only hosting        # after `flutter build web --release`
```

## Testing rules locally

```bash
firebase emulators:start --only firestore,auth,storage
```

Point the app at the emulators in `bootstrap.dart`, after
`Firebase.initializeApp`:

```dart
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```
