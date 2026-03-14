# Phase 4: Device Hardware & Native Features — Implementation Plan

## Current Objective
Give the app access to device-level capabilities: the camera/photo library, persistent local storage, and GPS geolocation. After this phase, trips will survive app restarts and users can attach custom photos.

## Web Compatibility Note
> [!IMPORTANT]
> Since we are testing on **Flutter Web (Chrome)**, some native features behave differently than on mobile:
> - `image_picker` works on web (opens a file chooser dialog instead of a camera).
> - `shared_preferences` works on web (uses `localStorage` under the hood).
> - `geolocator` works on web (uses the browser's Geolocation API with a permission prompt).
> - `google_maps_flutter` does **not** work on web. We will skip the Google Maps step for now and revisit it at the mobile deployment stage.

## Proposed Changes

### Step 1 — Dependencies
Install `image_picker`, `shared_preferences`, and `geolocator` packages.

### Step 2 — Local Persistence (`shared_preferences`)
#### [NEW] `lib/core/services/storage_service.dart`
- Create a `StorageService` class that serializes the `List<Trip>` to JSON and saves it to `shared_preferences`.
- Methods: `saveTrips(List<Trip>)`, `loadTrips() → List<Trip>`.

#### [MODIFY] `lib/features/home/providers/trip_provider.dart`
- Update `TripNotifier.build()` to load saved trips from `StorageService` on app start.
- Update `addTrip()` to automatically persist the new list after every change.

### Step 3 — Image Picker (Custom Trip Photos)
#### [MODIFY] `lib/features/add_trip/screens/add_trip_screen.dart`
- Add an image picker button at the top of the form.
- On web: opens a file chooser. On mobile: offers camera or gallery.
- Store the picked image as a base64 string (for web compatibility) or file path.

#### [MODIFY] `lib/features/home/models/trip.dart`
- The `imageUrl` field already exists. We'll use it to store either a network URL or a base64 data URI.

### Step 4 — Geolocation (Tag Current Location)
#### [NEW] `lib/core/services/location_service.dart`
- Create a `LocationService` that wraps the `geolocator` package.
- Method: `getCurrentPosition() → (latitude, longitude)`.
- Handle permissions gracefully.

#### [MODIFY] `lib/features/add_trip/screens/add_trip_screen.dart`
- Add a "📍 Tag My Location" button that auto-fills the destination field with reverse-geocoded coordinates (or simply shows lat/lon).

## Verification Plan
1. Add a trip, close the browser tab entirely, reopen the app → the trip should still be there! (Persistence)
2. Add a trip with a custom image from the file picker → the image should display on the Home Screen card.
3. Click "Tag My Location" → the browser should prompt for location permission, then auto-fill coordinates.
