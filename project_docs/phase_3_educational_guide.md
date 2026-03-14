# Phase 3: APIs & Networking Educational Guide

In Phase 3, we gave our Travel App the power to **talk to the internet**. We connected it to the free Open-Meteo weather API so that every trip destination now displays live, real-time weather data directly in the hero header.

---

## 1. What We Did: Added the `http` Package

We installed Dart's standard networking library to make HTTP requests.

### How to Replicate It

```bash
flutter pub add http
```

### Why We Did It

The `http` package is the official, lightweight way to make GET/POST requests in Dart. It returns raw JSON strings that we decode with `dart:convert`. Unlike heavier alternatives (like `dio`), `http` keeps our dependency footprint tiny while teaching the fundamentals of REST API communication.

---

## 2. What We Did: Created a `WeatherService`

We built a dedicated service class (`lib/core/services/weather_service.dart`) that handles all API communication. It does two things in sequence:

1. **Geocoding**: Converts a city name (e.g., "Paris") into latitude/longitude coordinates using the Open-Meteo Geocoding API.
2. **Weather Fetching**: Sends those coordinates to the Open-Meteo Forecast API and gets back the current temperature and a weather condition code.

### How to Replicate It

Create the file `lib/core/services/weather_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _geocodeUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  final String _weatherUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<String> getWeatherForDestination(String destination) async {
    // Step 1: Get coordinates from city name
    final citySearch = destination.split(',').first.trim();
    final geoResponse = await http.get(
      Uri.parse('$_geocodeUrl?name=$citySearch&count=1&language=en&format=json'),
    );
    final geoData = jsonDecode(geoResponse.body);
    final lat = geoData['results'][0]['latitude'];
    final lon = geoData['results'][0]['longitude'];

    // Step 2: Get weather from coordinates
    final weatherResponse = await http.get(
      Uri.parse('$_weatherUrl?latitude=$lat&longitude=$lon&current_weather=true'),
    );
    final current = jsonDecode(weatherResponse.body)['current_weather'];
    final tempC = current['temperature'];
    final tempF = (tempC * 9 / 5) + 32;

    return '${(tempC as num).round()}°C / ${tempF.round()}°F ☀️';
  }
}
```

### Why We Did It

**Separation of Concerns**: We put all API logic inside a dedicated `Service` class instead of directly inside the UI widget. This is a fundamental software engineering pattern. If Open-Meteo shuts down tomorrow and we need to switch to a different weather API, we only change *one file* — the service — without touching any UI code.

**Two-Step API Chain**: Open-Meteo's weather endpoint requires coordinates, but our users type city names. This is extremely common in real-world development — you almost always need to chain multiple API calls together.

---

## 3. What We Did: Created a Riverpod `FutureProvider`

We created `lib/features/trip_details/providers/weather_provider.dart` to bridge the gap between our service and our UI.

### How to Replicate It

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/weather_service.dart';

// Makes the service injectable and testable
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// FutureProvider.family: async provider that takes an argument
final weatherProvider = FutureProvider.family<String, String>((ref, destination) async {
  final weatherService = ref.read(weatherServiceProvider);
  return await weatherService.getWeatherForDestination(destination);
});
```

### Why We Did It

**`FutureProvider`** is one of Riverpod's most powerful tools. It automatically manages three states for any async operation:
- **`loading`**: The API call is in progress → show a spinner
- **`data`**: The API call succeeded → show the result
- **`error`**: The API call failed → show a fallback message

Without `FutureProvider`, you would need to manually write `setState`, track a `bool isLoading`, handle `try/catch`, and manage the lifecycle yourself. Riverpod does all of this in **zero boilerplate**.

The **`.family`** modifier lets us pass the destination string as an argument, so each trip gets its own cached weather result.

---

## 4. What We Did: Wired the UI with `.when()`

We updated `TripDetailsScreen` to consume the weather provider and elegantly render all three async states.

### How to Replicate It

```dart
final weatherAsync = ref.watch(weatherProvider(trip.destination));

// Inside the FlexibleSpaceBar title:
weatherAsync.when(
  data: (weather) => Text(weather),           // "13°C / 55°F ⛅"
  loading: () => CircularProgressIndicator(), // Tiny white spinner
  error: (e, s) => Text('Weather unavailable'), // Graceful fallback
),
```

### Why We Did It

The `.when()` method is the **declarative** way to handle async states. Instead of writing imperative `if (isLoading) { ... } else if (hasError) { ... } else { ... }` chains, we simply declare what widget to show for each state. Flutter's compiler enforces that we handle ALL three cases, making it impossible to forget error handling.

---

## Quality Assurance

- Ran `flutter analyze` — **0 issues found**.
- Tested with real cities (Kyoto, Paris) — live weather data appeared correctly with temperature and emoji.
- Tested with a fictitious destination ("uhghghg") — the app gracefully showed "Weather unavailable" instead of crashing.
- Verified the loading spinner appears briefly while the API responds.
