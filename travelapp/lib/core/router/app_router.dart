import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/trip_details/screens/trip_details_screen.dart';
import '../../features/add_trip/screens/add_trip_screen.dart';
import '../../features/home/models/trip.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) =>
            TripDetailsScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add-trip',
        builder: (context, state) => const AddTripScreen(),
      ),
      GoRoute(
        path: '/edit-trip',
        builder: (context, state) {
          final trip = state.extra as Trip;
          return AddTripScreen(existingTrip: trip);
        },
      ),
    ],
  );
}
