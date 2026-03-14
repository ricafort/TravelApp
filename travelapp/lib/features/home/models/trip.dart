import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
abstract class ItineraryItem with _$ItineraryItem {
  const factory ItineraryItem({
    required String id,
    required String day,
    required String activity,
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemFromJson(json);
}

@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String description,
    required double amount,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

@freezed
abstract class AudioJournal with _$AudioJournal {
  const factory AudioJournal({
    required String id,
    required String title,
    required String filePath,
    required DateTime timestamp,
  }) = _AudioJournal;

  factory AudioJournal.fromJson(Map<String, dynamic> json) =>
      _$AudioJournalFromJson(json);
}

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String imageUrl,
    @Default([]) List<ItineraryItem> itinerary,
    @Default([]) List<Expense> expenses,
    @Default([]) List<AudioJournal> audioLogs,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

// Temporary Mock Data for initial state loading
final List<Trip> mockTrips = [
  Trip(
    id: '1',
    destination: 'Kyoto, Japan',
    startDate: DateTime(2026, 4, 15),
    endDate: DateTime(2026, 4, 25),
    imageUrl: 'https://picsum.photos/seed/kyoto/800/600',
  ),
  Trip(
    id: '2',
    destination: 'Santorini, Greece',
    startDate: DateTime(2026, 6, 10),
    endDate: DateTime(2026, 6, 18),
    imageUrl: 'https://picsum.photos/seed/santorini/800/600',
  ),
  Trip(
    id: '3',
    destination: 'Banff National Park, Canada',
    startDate: DateTime(2026, 9, 5),
    endDate: DateTime(2026, 9, 12),
    imageUrl: 'https://picsum.photos/seed/banff/800/600',
  ),
];
