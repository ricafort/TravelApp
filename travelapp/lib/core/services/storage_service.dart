import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/models/trip.dart';

// TUTORIAL: StorageService encapsulates all local persistence logic.
// By using shared_preferences (which maps to localStorage on web and
// NSUserDefaults/SharedPreferences on iOS/Android), our trips survive
// browser refreshes and app restarts without needing a backend server.
class StorageService {
  static const String _tripsKey = 'saved_trips';

  /// Save the entire list of trips as a JSON string to local storage.
  Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert each Trip to a Map, then the whole list to a JSON string
    final jsonString = jsonEncode(trips.map((t) => t.toJson()).toList());
    await prefs.setString(_tripsKey, jsonString);
  }

  /// Load trips from local storage. Returns an empty list if nothing is saved.
  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tripsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return []; // No saved data yet
    }

    // Decode the JSON string back into a List of Trip objects
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => Trip.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Check if any trips have been saved before (first-launch detection)
  Future<bool> hasSavedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tripsKey);
  }
}
