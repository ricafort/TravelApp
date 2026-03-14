import 'dart:convert';
import 'package:http/http.dart' as http;

// TUTORIAL: We isolate ALL network logic inside a Service class.
// This follows the "Separation of Concerns" principle — the UI never
// touches HTTP directly. If we swap to a different weather API tomorrow,
// only this single file needs to change.
class WeatherService {
  // Free geocoding API to turn "Paris" into lat/long
  final String _geocodeUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  // Free weather API
  final String _weatherUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<String> getWeatherForDestination(String destination) async {
    try {
      // TUTORIAL: Destinations like "Paris, France" contain commas.
      // The geocoding API works best with just the city name, so we split
      // at the comma and take only the first part. This is a common
      // data-sanitization pattern when dealing with user-generated input.
      final citySearch = destination.split(',').first.trim();

      final geoResponse = await http.get(
        Uri.parse(
          '$_geocodeUrl?name=$citySearch&count=1&language=en&format=json',
        ),
      );

      if (geoResponse.statusCode != 200) {
        throw Exception('Failed to fetch coordinates');
      }

      final geoData = jsonDecode(geoResponse.body);

      // If no valid city found, throw an error
      if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
        throw Exception('Location not found');
      }

      final lat = geoData['results'][0]['latitude'];
      final lon = geoData['results'][0]['longitude'];

      // 2. Get Weather using those coordinates
      final weatherResponse = await http.get(
        Uri.parse(
          '$_weatherUrl?latitude=$lat&longitude=$lon&current_weather=true',
        ),
      );

      if (weatherResponse.statusCode != 200) {
        throw Exception('Failed to fetch weather');
      }

      final weatherData = jsonDecode(weatherResponse.body);
      final current = weatherData['current_weather'];

      final tempC = current['temperature'];
      // Also show Fahrenheit for US users
      final tempF = (tempC * 9 / 5) + 32;
      final code = current['weathercode'];

      final emoji = _getWeatherEmoji(code);

      // Return both units so everyone is happy!
      return '${(tempC as num).round()}°C / ${tempF.round()}°F $emoji';
    } catch (e) {
      // TUTORIAL: We re-throw instead of returning a fallback string.
      // This is intentional! By throwing, Riverpod's FutureProvider
      // automatically transitions to the .error state, and the UI
      // renders "Weather unavailable" via the .when() handler.
      throw Exception('Could not load weather: $e');
    }
  }

  // TUTORIAL: WMO Weather Interpretation Codes are an international standard.
  // Instead of returning raw numbers to the UI, we map them to emojis here
  // in the service layer, keeping the UI code clean and readable.
  String _getWeatherEmoji(int code) {
    if (code == 0) return '☀️'; // Clear sky
    if (code >= 1 && code <= 3) return '⛅'; // Partly cloudy
    if (code >= 45 && code <= 48) return '🌫️'; // Fog
    if (code >= 51 && code <= 67) return '🌧️'; // Drizzle / Rain
    if (code >= 71 && code <= 77) return '❄️'; // Snow
    if (code >= 80 && code <= 82) return '🌦️'; // Rain showers
    if (code >= 85 && code <= 86) return '🌨️'; // Snow showers
    if (code >= 95) return '⛈️'; // Thunderstorm
    return '☁️'; // Default
  }
}
