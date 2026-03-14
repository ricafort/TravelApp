// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItineraryItem _$ItineraryItemFromJson(Map<String, dynamic> json) =>
    _ItineraryItem(
      id: json['id'] as String,
      day: json['day'] as String,
      activity: json['activity'] as String,
    );

Map<String, dynamic> _$ItineraryItemToJson(_ItineraryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day': instance.day,
      'activity': instance.activity,
    };

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'amount': instance.amount,
};

_AudioJournal _$AudioJournalFromJson(Map<String, dynamic> json) =>
    _AudioJournal(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$AudioJournalToJson(_AudioJournal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'filePath': instance.filePath,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  destination: json['destination'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  imageUrl: json['imageUrl'] as String,
  itinerary:
      (json['itinerary'] as List<dynamic>?)
          ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  expenses:
      (json['expenses'] as List<dynamic>?)
          ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  audioLogs:
      (json['audioLogs'] as List<dynamic>?)
          ?.map((e) => AudioJournal.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'destination': instance.destination,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'imageUrl': instance.imageUrl,
  'itinerary': instance.itinerary,
  'expenses': instance.expenses,
  'audioLogs': instance.audioLogs,
};
