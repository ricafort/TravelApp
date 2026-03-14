# Phase 4: Device Hardware & Native Features — Educational Guide

Phase 4 broke our app out of the sandbox. We gave it three native superpowers: **persistent local storage**, **camera/file access**, and **GPS geolocation**.

---

## 1. Persistent Storage (`shared_preferences`)

### What We Did
Trips now survive browser refreshes and app restarts. We created a `StorageService` that serializes trips to JSON and stores them in the browser's `localStorage`.

### How to Replicate

```bash
flutter pub add shared_preferences
```

Create `lib/core/services/storage_service.dart`:
```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tripsKey = 'saved_trips';

  Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(trips.map((t) => t.toJson()).toList());
    await prefs.setString(_tripsKey, jsonString);
  }

  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tripsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => Trip.fromJson(j)).toList();
  }
}
```

### Why We Did It
- **`shared_preferences`** maps to `localStorage` on web, `NSUserDefaults` on iOS, and `SharedPreferences` on Android — one API, three platforms.
- We serialize using Freezed's auto-generated `toJson()`/`fromJson()`, so we didn't write any manual parsing.
- The `StorageService` class keeps persistence logic isolated from the UI (Separation of Concerns).

---

## 2. Sync → Async Notifier Migration

### What We Did
Because loading from `shared_preferences` is asynchronous, we migrated `TripNotifier` from `Notifier<List<Trip>>` to `AsyncNotifier<List<Trip>>`. This required updating all screens to handle `AsyncValue` with `.when()`.

### Key Difference
| Before (Phase 2) | After (Phase 4) |
|---|---|
| `Notifier<List<Trip>>` | `AsyncNotifier<List<Trip>>` |
| `build()` returns `List<Trip>` | `build()` returns `Future<List<Trip>>` |
| `ref.watch()` → `List<Trip>` | `ref.watch()` → `AsyncValue<List<Trip>>` |
| Direct list access | Must use `.when(loading, error, data)` |

### Why We Did It
The `build()` method now `await`s `StorageService.loadTrips()`. Since this is a `Future`, Riverpod needs `AsyncNotifier` to automatically provide loading/error/data states while the storage is being read. Every mutation (`addTrip`, `removeTrip`) now also calls `saveTrips()` to auto-persist.

---

## 3. Image Picker (`image_picker`)

### What We Did
Added a photo picker to the Add Trip form. Users tap a grey placeholder area → file chooser opens → selected image appears as the trip's cover photo.

### How to Replicate

```bash
flutter pub add image_picker
```

Key code in `AddTripScreen`:
```dart
final picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 1200,
  imageQuality: 75,
);

if (image != null) {
  final bytes = await image.readAsBytes();
  _pickedImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
}
```

### Why Base64?
On Flutter Web, you can't save file paths to `localStorage` — the browser sandbox blocks file system access. Instead, we encode the image bytes as a **base64 data URI** string (e.g., `data:image/jpeg;base64,/9j/4AAQ...`). This string can be stored in `shared_preferences` and later rendered with `Image.memory()`.

> **Trade-off**: Base64 increases storage size by ~33%. For a production app, you'd upload images to cloud storage (Phase 5). For local-first learning, this works perfectly.

---

## 4. Geolocation (`geolocator`)

### What We Did
Added a GPS button (📍) next to the destination field. Clicking it triggers the browser's location permission dialog, then auto-fills latitude/longitude coordinates.

### How to Replicate

```bash
flutter pub add geolocator
```

Key permission flow in `LocationService`:
```dart
// 1. Check if GPS is enabled
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

// 2. Check (and request) permission
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}

// 3. Get position
return await Geolocator.getCurrentPosition();
```

### Why We Did It
The `geolocator` package abstracts away platform differences:
- **Web**: Uses the browser's `navigator.geolocation` API
- **Android**: Uses `FusedLocationProviderClient`
- **iOS**: Uses `CLLocationManager`

One Dart API handles all three, including the permissions flow.

---

## Quality Assurance
- `flutter analyze` — **0 issues found**
- Tested persistence: added trip → closed browser → reopened → trips persisted ✅
- Tested image picker: chose a local photo → appeared on Home Screen card ✅
- Tested geolocation: browser prompted for permission → coordinates auto-filled ✅
- Tested error path: denied GPS permission → graceful SnackBar error ✅

---

## Testing Native Hardware (Android Emulator)

Because Phase 4 introduces features that interact directly with the operating system (Camera, GPS, Secure Storage), testing them in the Chrome web sandbox is limited. To fully test these features natively, use the Android Emulator.

**How to boot into Android:**

1. **Find an Emulator:**
   ```bash
   flutter emulators
   ```
2. **Launch the Emulator:**
   Look for the ID in the list (e.g., `Medium_Phone_API_36.1`) and launch it:
   ```bash
   flutter emulators --launch Medium_Phone_API_36.1
   ```
3. **Run the App Natively:**
   Wait for the Android home screen to appear, then run:
   ```bash
   flutter run
   ```
   *Flutter will compile the code to an Android APK and install it directly onto the virtual device.*
