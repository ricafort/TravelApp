import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TUTORIAL: tripProvider is now an AsyncNotifierProvider, so ref.watch()
    // returns an AsyncValue instead of a plain List. We use .when() to handle
    // the loading, error, and data states — just like we did for weather!
    final tripsAsync = ref.watch(tripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Journeys',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // Future feature
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (trips) => trips.isEmpty
            ? const Center(child: Text('No trips yet. Time to plan one!'))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return TripCard(trip: trip);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-trip'),
        tooltip: 'Add New Trip',
        child: const Icon(Icons.flight_takeoff),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy');

    // TUTORIAL: We check if the imageUrl starts with 'data:' to detect
    // base64-encoded images from the image picker (vs network URLs).
    final isBase64Image = trip.imageUrl.startsWith('data:');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/trip/${trip.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image — supports both network URLs and base64 data URIs
            SizedBox(
              height: 180,
              child: isBase64Image
                  ? Image.memory(
                      _decodeBase64(trip.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                    )
                  : Image.network(
                      trip.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                    ),
            ),
            // Trip Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destination,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${dateFormatter.format(trip.startDate)} - ${dateFormatter.format(trip.endDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decode a base64 data URI into bytes for Image.memory
  static Uint8List _decodeBase64(String dataUri) {
    // Strip the "data:image/...;base64," prefix
    final base64String = dataUri.split(',').last;
    return Uint8List.fromList(
      Uri.parse(
        'data:application/octet-stream;base64,$base64String',
      ).data!.contentAsBytes(),
    );
  }
}
