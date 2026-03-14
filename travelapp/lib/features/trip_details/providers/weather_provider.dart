import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/weather_service.dart';

// 1. We create a basic Provider to hold our Service.
// This makes it easy to mock the service later during testing!
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// 2. We create a FutureProvider.family.
// - FutureProvider: Automatically handles loading/error/data states for Async work.
// - .family: Allows us to pass an argument (in our case, the 'destination' String)
final weatherProvider = FutureProvider.family<String, String>((
  ref,
  destination,
) async {
  // Read our service from the provider above
  final weatherService = ref.read(weatherServiceProvider);

  // Call the async method
  return await weatherService.getWeatherForDestination(destination);
});
