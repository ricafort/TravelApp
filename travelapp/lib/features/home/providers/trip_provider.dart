import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../models/trip.dart';

// TUTORIAL: We provide the StorageService via a Riverpod Provider
// so it can be easily swapped out for testing or replaced with a cloud backend later.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// TUTORIAL: We switched from Notifier to AsyncNotifier because loading from
// shared_preferences is an async operation. AsyncNotifier's build() method
// returns a Future, which Riverpod handles by automatically providing
// loading/error/data states — just like FutureProvider did for weather.
class TripNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    // TUTORIAL: On first app launch, load any previously saved trips.
    // If none exist, fall back to mock data so the app isn't empty.
    final storage = ref.read(storageServiceProvider);
    final hasSaved = await storage.hasSavedTrips();

    if (hasSaved) {
      return await storage.loadTrips();
    } else {
      // First launch: use mock data and save it for next time
      await storage.saveTrips(mockTrips);
      return mockTrips;
    }
  }

  // Action: Add a new trip and persist the updated list
  Future<void> addTrip(Trip newTrip) async {
    final currentTrips = state.value ?? [];
    // TUTORIAL: We create a brand new list (immutable pattern) and auto-save.
    final updatedTrips = [newTrip, ...currentTrips];
    state = AsyncData(updatedTrips);
    await ref.read(storageServiceProvider).saveTrips(updatedTrips);
  }

  // Action: Remove a trip by its ID and persist
  Future<void> removeTrip(String id) async {
    final currentTrips = state.value ?? [];
    final updatedTrips = currentTrips.where((trip) => trip.id != id).toList();
    state = AsyncData(updatedTrips);
    await ref.read(storageServiceProvider).saveTrips(updatedTrips);
  }

  // Action: Update an existing trip and persist
  Future<void> updateTrip(Trip updatedTrip) async {
    final currentTrips = state.value ?? [];
    final updatedTrips = [
      for (final trip in currentTrips)
        if (trip.id == updatedTrip.id) updatedTrip else trip,
    ];
    state = AsyncData(updatedTrips);
    await ref.read(storageServiceProvider).saveTrips(updatedTrips);
  }
}

// TUTORIAL: Changed from NotifierProvider to AsyncNotifierProvider
// because our TripNotifier now returns a Future in build().
final tripProvider = AsyncNotifierProvider<TripNotifier, List<Trip>>(() {
  return TripNotifier();
});
