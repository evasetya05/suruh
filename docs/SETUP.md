# Setup

- [Prerequisites](#prerequisites)
- [Running the demo](#running-the-demo)
- [Configuration](#configuration)
- [Switching to Firebase](#switching-to-firebase)
- [Firestore data model](#firestore-data-model)
- [Security rules](#security-rules)
- [Cloud Functions](#cloud-functions)
- [Firebase Storage](#firebase-storage)
- [Push notifications](#push-notifications)
- [Seeding a Firestore project](#seeding-a-firestore-project)
- [Building for release](#building-for-release)
- [Troubleshooting](#troubleshooting)
- [Shipping it](#shipping-it)

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.35 or newer (stable) |
| Dart | 3.5+ (bundled with Flutter) |
| Xcode | 15+ — iOS only |
| Android Studio / SDK | API 21+ — Android only |

```bash
flutter --version
flutter doctor
```

---

## Running the demo

No configuration, no accounts, no network.

```bash
git clone <your-fork-url>
cd food-delivery-app
flutter pub get
flutter run -d chrome
```

Other targets:

```bash
flutter devices                 # list what is connected
flutter run -d macos
flutter run -d <android-id>
flutter run -d <ios-simulator-id>
```

Sign in with a persona card on the login screen, or type credentials:

| Role | Email | Password |
|---|---|---|
| Customer | `customer@msdevbuild.com` | `demo1234` |
| Restaurant partner | `partner@msdevbuild.com` | `demo1234` |
| Delivery rider | `rider@msdevbuild.com` | `demo1234` |

Verify the build:

```bash
flutter analyze     # expect: No issues found!
flutter test        # expect: All tests passed!
```

---

## Configuration

Everything tunable lives in `lib/core/config/app_config.dart`:

| Field | Default | What it does |
|---|---|---|
| `backend` | `Backend.demo` | `demo` or `firebase` |
| `appName` | `MSDevBuild Eats` | Shown in title bar, splash, about dialog |
| `tagline` | `Everyday everything` | Splash subtitle |
| `publisher` | `MSDevBuild` | Byline on the splash screen and about dialog |
| `articleUrl` | `https://blog.msdevbuild.com/` | The write-up this demo accompanies; linked from login, profile and about |
| `currencySymbol` | `RM` | Prefix on every price |
| `simulatedLatency` | `450 ms` | Artificial delay so loading states are visible. `Duration.zero` in tests |
| `orderStageDuration` | `8 s` | How long each delivery stage lasts in the simulation |

To change one without editing the file — for a flavour, a demo build, or a
screenshot run — pass an override to `bootstrap`:

```dart
// lib/main_fast.dart
import 'bootstrap.dart';
import 'core/config/app_config.dart';

void main() => bootstrap(
      config: const AppConfig(
        simulatedLatency: Duration.zero,
        orderStageDuration: Duration(seconds: 2),
      ),
    );
```

```bash
flutter run -t lib/main_fast.dart -d chrome
```

---

## Switching to Firebase

The Firebase integration is written and wired; it is off by default so a fresh
clone runs without a project. Four steps to turn it on.

### 1. Create the project

<https://console.firebase.google.com> → **Add project**. Then enable:

- **Authentication** → Sign-in method → **Email/Password**
- **Firestore Database** → Create database
- **Storage** → Get started
- **Cloud Functions** (needs the Blaze plan)
- **Cloud Messaging** — on by default

### 2. Generate `firebase_options.dart`

```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
flutterfire configure
```

This overwrites the placeholder `lib/firebase_options.dart` with your real
values and sets `isConfigured = true`. Pick every platform you intend to ship.

It also drops `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist` into place.

### 3. Flip the switch

```dart
// lib/core/config/app_config.dart
static AppConfig instance = const AppConfig(
  backend: Backend.firebase,
);
```

### 4. Deploy rules and functions

See the two sections below, then:

```bash
firebase deploy --only firestore:rules,storage:rules,functions
```

> `bootstrap.dart` refuses to initialise Firebase while
> `DefaultFirebaseOptions.isConfigured` is `false`, logs a warning, and falls
> back to the demo backend. If you flip the enum but skip `flutterfire
> configure`, the app still runs — check the console for the reason.

---

## Firestore data model

`FirestoreDataSource` expects this layout:

```
users/{uid}
  id, name, email, phone, role, avatarEmoji, photoUrl,
  addresses[], favouriteRestaurantIds[], loyaltyPoints,
  memberTier, createdAt, managedRestaurantId

restaurants/{restaurantId}
  id, name, cuisines[], emoji, rating, reviewCount,
  deliveryFeeMyr, minOrderMyr, etaMinMinutes, etaMaxMinutes,
  distanceKm, address{}, imageUrl, coverImageUrl, description,
  isOpen, isPromoted, promoText, priceLevel, tags[],
  openingTime, closingTime, ownerId, phone

  └── menu/{foodItemId}
        id, restaurantId, restaurantName, name, description,
        priceMyr, discountPriceMyr, categoryId, emoji, rating,
        reviewCount, imageUrl, ingredients[], allergens[],
        isVegetarian, isSpicy, spiceLevel, calories,
        prepMinutes, isAvailable, isPopular, servingSize

orders/{orderId}
  id, userId, restaurantId, restaurantName, restaurantEmoji,
  lines[], status, placedAt, deliveryAddress{}, paymentMethod,
  subtotal, deliveryFee, serviceFee, discount, total,
  customerName, customerPhone, rider{}, timeline[],
  etaMinutes, deliveredAt, riderNote, isRated

reviews/{reviewId}
  id, restaurantId, foodItemId, userId, userName,
  userAvatarEmoji, rating, comment, createdAt, likes, orderedItems[]

promos/{promoId}
  id, code, title, subtitle, discountPercent, maxDiscountMyr,
  minSpendMyr, emoji, badge, expiresAt, active
```

Field names match the `toJson()` output of the models in `lib/data/models/`, so
whatever the demo backend produces can be uploaded as-is.

### Required indexes

`getFoods()` uses a collection-group query over `menu`, and several reads sort
by a field they also filter on. Firestore will print a console link the first
time each is needed, or declare them up front in `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "menu",
      "queryScope": "COLLECTION_GROUP",
      "fields": [{ "fieldPath": "isAvailable", "order": "ASCENDING" }]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "placedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "restaurantId", "order": "ASCENDING" },
        { "fieldPath": "placedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "restaurantId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "foodItemId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Security rules

`firebase/firestore.rules` — the catalogue is world-readable, everything else is
scoped to its owner, and prices are never trusted from the client.

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn()      { return request.auth != null; }
    function isSelf(uid)     { return signedIn() && request.auth.uid == uid; }
    function roleOf()        { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role; }
    function isPartner()     { return signedIn() && roleOf() == 'restaurantPartner'; }
    function isRider()       { return signedIn() && roleOf() == 'deliveryPartner'; }
    function ownsRestaurant(rid) {
      return isPartner() &&
        get(/databases/$(database)/documents/restaurants/$(rid)).data.ownerId == request.auth.uid;
    }

    // A user reads and edits only their own profile. Role is set at sign-up and
    // cannot be escalated from the client.
    match /users/{uid} {
      allow read:   if isSelf(uid);
      allow create: if isSelf(uid) && request.resource.data.role in ['customer', 'restaurantPartner', 'deliveryPartner'];
      allow update: if isSelf(uid) && request.resource.data.role == resource.data.role;
      allow delete: if false;
    }

    // Catalogue: public to read, owner-only to write.
    match /restaurants/{rid} {
      allow read: if true;
      allow write: if ownsRestaurant(rid);

      match /menu/{itemId} {
        allow read: if true;
        allow write: if ownsRestaurant(rid);
      }
    }

    match /promos/{promoId} {
      allow read:  if true;
      allow write: if false;                 // seeded/administered server-side
    }

    // Orders are created by the placeOrder function only, so the client cannot
    // invent its own totals. Status changes are limited to the parties involved.
    match /orders/{orderId} {
      allow read: if signedIn() && (
        resource.data.userId == request.auth.uid ||
        ownsRestaurant(resource.data.restaurantId) ||
        isRider()
      );
      allow create: if false;
      allow update: if signedIn() && (
        ownsRestaurant(resource.data.restaurantId) ||
        isRider() ||
        // The customer may only cancel, or mark an order rated.
        (resource.data.userId == request.auth.uid &&
         request.resource.data.diff(resource.data).affectedKeys()
           .hasOnly(['status', 'timeline', 'isRated']))
      );
      allow delete: if false;
    }

    // One review per user per restaurant, written as yourself, never edited.
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5;
      allow update, delete: if false;
    }
  }
}
```

---

## Cloud Functions

`FirestoreDataSource` calls two callables. Minimal implementations:

```javascript
// firebase/functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

const SERVICE_FEE_RATE = 0.10;
const SERVICE_FEE_CAP  = 3;
const SMALL_ORDER_FEE  = 2;

/**
 * Creates an order with server-computed totals.
 *
 * Prices are re-read from the menu rather than trusted from the client, so a
 * tampered payload cannot buy a RM 40 dish for RM 1.
 */
exports.placeOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
  }

  const { restaurantId, lines, deliveryAddress, paymentMethod, riderNote } = data;

  const restaurantSnap = await db.doc(`restaurants/${restaurantId}`).get();
  if (!restaurantSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Restaurant not found.');
  }
  const restaurant = restaurantSnap.data();
  if (!restaurant.isOpen) {
    throw new functions.https.HttpsError('failed-precondition', 'Restaurant is closed.');
  }

  let subtotal = 0;
  const priced = [];

  for (const line of lines) {
    const itemSnap = await db.doc(`restaurants/${restaurantId}/menu/${line.item.id}`).get();
    if (!itemSnap.exists) {
      throw new functions.https.HttpsError('not-found', `Dish ${line.item.id} not found.`);
    }
    const item = itemSnap.data();
    if (!item.isAvailable) {
      throw new functions.https.HttpsError('failed-precondition', `${item.name} is sold out.`);
    }
    const unit = item.discountPriceMyr && item.discountPriceMyr < item.priceMyr
      ? item.discountPriceMyr
      : item.priceMyr;

    subtotal += unit * line.quantity;
    priced.push({ item, quantity: line.quantity, notes: line.notes || '' });
  }

  const serviceFee   = Math.min(subtotal * SERVICE_FEE_RATE, SERVICE_FEE_CAP);
  const smallOrder   = subtotal < restaurant.minOrderMyr ? SMALL_ORDER_FEE : 0;
  const deliveryFee  = restaurant.deliveryFeeMyr;
  const total        = subtotal + deliveryFee + serviceFee + smallOrder;

  const now = admin.firestore.Timestamp.now();
  const ref = db.collection('orders').doc();

  await ref.set({
    id: ref.id,
    userId: context.auth.uid,
    restaurantId,
    restaurantName: restaurant.name,
    restaurantEmoji: restaurant.emoji,
    lines: priced,
    status: 'placed',
    placedAt: now,
    deliveryAddress,
    paymentMethod,
    subtotal,
    deliveryFee,
    serviceFee: serviceFee + smallOrder,
    discount: 0,
    total,
    timeline: [{ status: 'placed', at: now }],
    etaMinutes: restaurant.etaMaxMinutes,
    riderNote: riderNote || null,
    isRated: false,
  });

  // Tell the restaurant a new order landed.
  await admin.messaging().send({
    topic: `restaurant_${restaurantId}`,
    notification: { title: 'New order', body: `Order for ${restaurant.name}` },
    data: { orderId: ref.id },
  });

  return { orderId: ref.id };
});

/** Recomputes a restaurant's aggregate rating. Racy if done client-side. */
exports.recomputeRestaurantRating = functions.https.onCall(async (data) => {
  const { restaurantId } = data;

  const reviews = await db.collection('reviews')
    .where('restaurantId', '==', restaurantId)
    .get();

  if (reviews.empty) return { rating: 0, reviewCount: 0 };

  const total = reviews.docs.reduce((sum, d) => sum + d.data().rating, 0);
  const rating = Math.round((total / reviews.size) * 10) / 10;

  await db.doc(`restaurants/${restaurantId}`).update({
    rating,
    reviewCount: reviews.size,
  });

  return { rating, reviewCount: reviews.size };
});

/** Pushes status changes to the customer's per-order topic. */
exports.onOrderStatusChanged = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    if (before.status === after.status) return null;

    const copy = {
      confirmed:      'Your order was accepted',
      preparing:      'Your food is being prepared',
      readyForPickup: 'Waiting for a rider',
      outForDelivery: 'Your rider is on the way',
      delivered:      'Delivered. Enjoy your meal!',
      cancelled:      'Your order was cancelled',
    };

    return admin.messaging().send({
      topic: `order_${context.params.orderId}`,
      notification: {
        title: after.restaurantName,
        body: copy[after.status] || 'Order updated',
      },
      data: { orderId: context.params.orderId, status: after.status },
    });
  });
```

Deploy:

```bash
cd firebase/functions
npm install firebase-admin firebase-functions
cd ../..
firebase deploy --only functions
```

---

## Firebase Storage

`FirestoreDataSource.uploadDishImage` writes to
`restaurants/{restaurantId}/menu/{foodItemId}.jpg` and returns a download URL.
Matching rules:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /restaurants/{restaurantId}/menu/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*')
        && firestore.get(/databases/(default)/documents/restaurants/$(restaurantId)).data.ownerId == request.auth.uid;
    }
  }
}
```

Once dishes carry real URLs, `AppImage` switches from the generated gradient
plate to `CachedNetworkImage` automatically — no widget changes.

---

## Push notifications

`PushNotificationService` (`lib/core/notifications/`) requests permission,
resolves the FCM token, keeps it fresh, subscribes to the `promotions` topic,
and exposes foreground messages, notification taps and the cold-start message.
`bootstrap.dart` registers the background handler.

**Android** — works after `flutterfire configure`. For a custom notification
icon, add it to `android/app/src/main/res/drawable/` and reference it in
`AndroidManifest.xml`.

**iOS** — enable *Push Notifications* and *Background Modes → Remote
notifications* in Xcode, then upload an APNs key in the Firebase console under
Project settings → Cloud Messaging.

**Web** — add a VAPID key pair (Project settings → Cloud Messaging → Web
configuration) and pass it:

```dart
_token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_PUBLIC_KEY');
```

Then create `web/firebase-messaging-sw.js` for background messages.

Topics used:

| Topic | Subscribers |
|---|---|
| `promotions` | Every signed-in customer |
| `order_{orderId}` | The customer and rider on that order |
| `restaurant_{restaurantId}` | The merchant, for incoming orders |

---

## Seeding a Firestore project

The seed corpus is plain Dart with `toJson()` on every model, so you can push it
straight up. Create `tool/seed_firestore.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_foods.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_promos.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_restaurants.dart';
import 'package:food_delivery_app/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Firestore batches cap at 500 writes; the seed fits comfortably.
  final WriteBatch batch = db.batch();

  for (final r in kSeedRestaurants) {
    batch.set(db.collection('restaurants').doc(r.id), r.toJson());
  }
  for (final f in buildSeedFoods()) {
    batch.set(
      db.collection('restaurants').doc(f.restaurantId).collection('menu').doc(f.id),
      f.toJson(),
    );
  }
  for (final p in kSeedPromos) {
    batch.set(db.collection('promos').doc(p.id), <String, dynamic>{
      ...p.toJson(),
      'active': true,
    });
  }

  await batch.commit();
}
```

Run it against an emulator first:

```bash
firebase emulators:start --only firestore,auth
flutter run -t tool/seed_firestore.dart -d chrome
```

Create the three demo accounts in Authentication → Users with password
`demo1234`, then add a matching `users/{uid}` document for each, setting `role`
and (for the partner) `managedRestaurantId: 'r-06'`.

---

## Building for release

```bash
# Web
flutter build web --release
# output: build/web/  — deploy with `firebase deploy --only hosting`

# Android
flutter build appbundle --release
flutter build apk --release --split-per-abi

# iOS
flutter build ipa --release
```

Signing: create `android/key.properties` and reference it from
`android/app/build.gradle.kts` for Android; set your team and bundle identifier
in Xcode for iOS.

---

## Troubleshooting

**`No issues found!` from analyze but the IDE shows errors** — restart the Dart
analysis server, or run `flutter clean && flutter pub get`.

**`include_file_not_found` for `flutter_lints`** — the include path is
`package:flutter_lints/flutter.yaml` in v4+, not `flutter_lints.yaml`.

**Firebase initialisation logs a warning and the demo backend loads anyway** —
`DefaultFirebaseOptions.isConfigured` is still `false`. Run `flutterfire
configure`.

**`PERMISSION_DENIED` on Firestore reads** — rules are not deployed, or the
signed-in user has no `users/{uid}` document (role lookups in the rules will
fail without one).

**`FAILED_PRECONDITION: The query requires an index`** — click the link in the
error, or deploy `firestore.indexes.json`.

**Web build succeeds but the page is blank** — check the browser console.
Serving `build/web` from `file://` will not work; use `flutter run -d chrome`
or any static server.

**Tests hang or report a pending timer** — the demo backend runs delivery
simulations on timers. Call `DemoDataSource.instance.pauseSimulations()` in
`tearDown`.

**Everything looks stale after changing seed data** — the catalogue is cached in
`SharedPreferences`. Use *Account → Reset demo data*, or uninstall the app /
clear site data.

**Pages deploy shows a white screen with 404s on every asset** — the `--base-href`
does not match the repository name. See [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Shipping it

Publishing the web build to GitHub Pages and the APK to Firebase App
Distribution is covered separately in **[DEPLOYMENT.md](DEPLOYMENT.md)**.
