import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../home/models/trip.dart';
import '../../home/providers/trip_provider.dart';
import '../providers/weather_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../widgets/survival_phrases_card.dart';
import '../widgets/currency_card.dart';
import '../widgets/packing_list_card.dart';

class TripDetailsScreen extends ConsumerWidget {
  final String id;
  const TripDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // tripProvider is now async, so we get the current value or an empty list
    // TUTORIAL: We use 'ref.watch' inside the build method to automatically
    // rebuild this widget whenever the tripProvider's state changes.
    // This is the core of reactive UI programming in Riverpod.
    final tripsAsync = ref.watch(tripProvider);

    return tripsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (trips) => _buildDetailsScreen(context, ref, trips),
    );
  }

  Widget _buildDetailsScreen(
    BuildContext context,
    WidgetRef ref,
    List<Trip> trips,
  ) {
    // Find the current trip based on ID provided from the URL
    final trip = trips.firstWhere((t) => t.id == id, orElse: () => trips.first);

    // Fetch the live weather for this trip's destination
    final weatherAsync = ref.watch(weatherProvider(trip.destination));

    final dateFormatter = DateFormat('MMMM d, yyyy');

    return Scaffold(
      // TUTORIAL: We use a CustomScrollView and Slivers here instead of a standard
      // ListView. Slivers are mathematical portions of a scrollable area that can
      // dynamically change their layout as the user scrolls (like the collapsing header above).
      body: CustomScrollView(
        slivers: [
          // 1. the collapsing header
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Colors.black.withAlpha(
                  180,
                ), // Dark background for visibility
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  context.push('/edit-trip', extra: trip);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Trip?'),
                      content: const Text(
                        'Are you sure you want to delete this trip? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    ref.read(tripProvider.notifier).removeTrip(trip.id);
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                bottom: 16,
                right: 16,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0.0, 1.0),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Displaying the dynamic weather state!
                  weatherAsync.when(
                    data: (weather) => Text(
                      weather,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize:
                            12, // Keep it smaller than the destination title
                        shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    error: (error, stack) => const Text(
                      'Weather unavailable',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  trip.imageUrl.startsWith('data:')
                      ? Image.memory(
                          _decodeBase64(trip.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              ),
                        )
                      : Image.network(
                          trip.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              ),
                        ),
                  // Adds a subtle dark gradient so the white text is readable
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. The scrollable content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${dateFormatter.format(trip.startDate)} - ${dateFormatter.format(trip.endDate)}',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // NEW: Survival Phrases Card
                  SurvivalPhrasesCard(destination: trip.destination),

                  // NEW: Currency Conversion Card
                  CurrencyCard(destination: trip.destination),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Itinerary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () =>
                            _showItineraryDialog(context, ref, trip, null),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Dynamic Itinerary Timeline
                  if (trip.itinerary.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'No activities planned yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...trip.itinerary.map(
                      (item) => _buildItineraryRow(context, ref, trip, item),
                    ),

                  // NEW: Packing List Card
                  PackingListCard(trip: trip),

                  const SizedBox(height: 32),

                  // NEW: Trip Expenses Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip Expenses',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () => _showExpenseDialog(context, ref, trip),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Expense Warning or List
                  if (trip.expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No expenses logged yet.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...trip.expenses.map(
                      (expense) =>
                          _buildExpenseRow(context, ref, trip, expense),
                    ),

                  // Total Expense Calculation Row
                  if (trip.expenses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Total: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${trip.expenses.fold<double>(0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // NEW: Audio Journals Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voice Journals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic, color: Colors.blue),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) =>
                                _RecordAudioSheet(trip: trip, ref: ref),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),

                  // Audio Journal List
                  if (trip.audioLogs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No recordings yet.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...trip.audioLogs.map(
                      (log) =>
                          _AudioJournalTile(trip: trip, log: log, ref: ref),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryRow(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
    ItineraryItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Card(
        elevation: 0, // Flat look
        color: Colors.transparent, // Inherit background
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25), // ~10% opacity
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showItineraryDialog(context, ref, trip, item);
                    } else if (value == 'delete') {
                      final updatedItinerary = trip.itinerary
                          .where((i) => i.id != item.id)
                          .toList();
                      ref
                          .read(tripProvider.notifier)
                          .updateTrip(
                            trip.copyWith(itinerary: updatedItinerary),
                          );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
              child: Text(item.activity, style: const TextStyle(fontSize: 16)),
            ),
            const Divider(height: 24),
          ],
        ),
      ),
    );
  }

  void _showItineraryDialog(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
    ItineraryItem? existingItem,
  ) {
    final dayController = TextEditingController(text: existingItem?.day ?? '');
    final activityController = TextEditingController(
      text: existingItem?.activity ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingItem == null ? 'Add Activity' : 'Edit Activity'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dayController,
                    readOnly: true, // Prevents manual keyboard appearing
                    decoration: const InputDecoration(
                      labelText: 'Day / Time',
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () async {
                      // 1. Let the user pick a date within the Trip's range
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: trip.startDate,
                        firstDate: trip.startDate,
                        lastDate: trip.endDate,
                      );

                      if (selectedDate == null) return; // User canceled

                      if (!context.mounted) return;

                      // 2. Let the user pick a specific time
                      final selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (selectedTime == null) return; // User canceled
                      if (!context.mounted) return;

                      // 3. Format the result back into the text field
                      final dateStr = DateFormat('MMM d').format(selectedDate);
                      final timeStr = selectedTime.format(
                        context,
                      ); // e.g. "10:30 AM"

                      dayController.text = '$dateStr - $timeStr';
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: activityController,
                    decoration: const InputDecoration(labelText: 'Activity'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newItem = ItineraryItem(
                    id: existingItem?.id ?? const Uuid().v4(),
                    day: dayController.text,
                    activity: activityController.text,
                  );

                  List<ItineraryItem> updatedItinerary;
                  if (existingItem != null) {
                    updatedItinerary = trip.itinerary
                        .map((i) => i.id == existingItem.id ? newItem : i)
                        .toList();
                  } else {
                    updatedItinerary = [...trip.itinerary, newItem];
                  }

                  ref
                      .read(tripProvider.notifier)
                      .updateTrip(trip.copyWith(itinerary: updatedItinerary));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- NEW EXPENSE METHODS --- //

  Widget _buildExpenseRow(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
    Expense expense,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.attach_money, color: Colors.green),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showExpenseDialog(
                context,
                ref,
                trip,
                existingExpense: expense,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Expense?'),
                    content: Text(
                      'Remove "${expense.description}" for \$${expense.amount.toStringAsFixed(2)}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          final updatedExpenses = trip.expenses
                              .where((e) => e.id != expense.id)
                              .toList();
                          ref
                              .read(tripProvider.notifier)
                              .updateTrip(
                                trip.copyWith(expenses: updatedExpenses),
                              );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDialog(
    BuildContext context,
    WidgetRef ref,
    Trip trip, {
    Expense? existingExpense,
  }) {
    final isEditing = existingExpense != null;
    final descController = TextEditingController(
      text: isEditing ? existingExpense.description : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? existingExpense.amount.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (e.g. Dinner)',
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (\$)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (double.tryParse(val) == null) {
                      return 'Must be a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newExpense = Expense(
                    id: isEditing ? existingExpense.id : const Uuid().v4(),
                    description: descController.text.trim(),
                    amount: double.parse(amountController.text.trim()),
                  );

                  List<Expense> updatedExpenses;
                  if (isEditing) {
                    updatedExpenses = trip.expenses
                        .map((e) => e.id == existingExpense.id ? newExpense : e)
                        .toList();
                  } else {
                    updatedExpenses = [...trip.expenses, newExpense];
                  }

                  ref
                      .read(tripProvider.notifier)
                      .updateTrip(trip.copyWith(expenses: updatedExpenses));
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
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

// --- NEW AUDIO JOURNAL CLASSES --- //

class _AudioJournalTile extends StatefulWidget {
  final Trip trip;
  final AudioJournal log;
  final WidgetRef ref;

  const _AudioJournalTile({
    required this.trip,
    required this.log,
    required this.ref,
  });

  @override
  State<_AudioJournalTile> createState() => _AudioJournalTileState();
}

class _AudioJournalTileState extends State<_AudioJournalTile> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(1.0); // Explicitly ensure max software volume
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.log.filePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.purple,
            ),
            onPressed: _togglePlay,
          ),
        ),
        title: Text(
          widget.log.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy - h:mm a').format(widget.log.timestamp),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Journal?'),
                content: Text(
                  'Are you sure you want to delete "${widget.log.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      final updatedLogs = widget.trip.audioLogs
                          .where((l) => l.id != widget.log.id)
                          .toList();
                      widget.ref
                          .read(tripProvider.notifier)
                          .updateTrip(
                            widget.trip.copyWith(audioLogs: updatedLogs),
                          );
                      // Optional: Actually delete the file from the disk here using File(widget.log.filePath).delete()
                      final file = File(widget.log.filePath);
                      if (file.existsSync()) file.deleteSync();

                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecordAudioSheet extends StatefulWidget {
  final Trip trip;
  final WidgetRef ref;

  const _RecordAudioSheet({required this.trip, required this.ref});

  @override
  State<_RecordAudioSheet> createState() => _RecordAudioSheetState();
}

class _RecordAudioSheetState extends State<_RecordAudioSheet> {
  late AudioRecorder _record;
  bool _isRecording = false;
  String? _audioFilePath;

  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _record = AudioRecorder();
  }

  @override
  void dispose() {
    _record.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _record.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _audioFilePath = null;
        });
      }
    } catch (e) {
      debugPrint("Error starting record: \$e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _record.stop();
      setState(() {
        _isRecording = false;
        _audioFilePath = path;
      });
    } catch (e) {
      debugPrint("Error stopping record: \$e");
    }
  }

  void _saveJournal() {
    if (_titleController.text.isEmpty || _audioFilePath == null) return;

    final newLog = AudioJournal(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      filePath: _audioFilePath!,
      timestamp: DateTime.now(),
    );

    final updatedLogs = [...widget.trip.audioLogs, newLog];
    widget.ref
        .read(tripProvider.notifier)
        .updateTrip(widget.trip.copyWith(audioLogs: updatedLogs));

    Navigator.pop(context); // Close sheet
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New Voice Journal',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What is this about? (e.g. Louvre Thoughts)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _isRecording
                    ? Colors.red
                    : Colors.grey.shade300,
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 40,
                  color: _isRecording ? Colors.white : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording
                  ? 'Recording... Release to stop'
                  : (_audioFilePath != null
                        ? 'Recording saved! Tap Save below.'
                        : 'Hold mic to record'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isRecording ? Colors.red : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _audioFilePath != null && _titleController.text.isNotEmpty
                  ? _saveJournal
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Journal'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
