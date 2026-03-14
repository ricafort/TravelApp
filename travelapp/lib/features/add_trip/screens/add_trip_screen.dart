import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../home/models/trip.dart';
import '../../home/providers/trip_provider.dart';
import '../../../core/services/location_service.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  final Trip? existingTrip;

  const AddTripScreen({super.key, this.existingTrip});

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _locationService = LocationService();
  DateTime? _startDate;
  DateTime? _endDate;

  // Image picker state
  Uint8List? _pickedImageBytes;
  String? _pickedImageBase64;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTrip != null) {
      final trip = widget.existingTrip!;
      _destinationController.text = trip.destination;
      _startDate = trip.startDate;
      _endDate = trip.endDate;
      // Pre-load the image URL/Base64 if available (fallback to network later or handle Base64)
      if (trip.imageUrl.startsWith('data:image')) {
        _pickedImageBase64 = trip.imageUrl;
      }
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  /// Pick an image from the gallery (or file chooser on web)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // Limit size for base64 storage
      imageQuality: 75, // Compress a little
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        // TUTORIAL: On web, we can't save file paths. Instead, we encode the
        // image as a base64 data URI so it can be stored as a plain string
        // in shared_preferences (localStorage).
        _pickedImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  /// Use GPS to auto-fill the destination
  Future<void> _tagLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final formatted = await _locationService.getAddressFromPosition(position);
      _destinationController.text = formatted;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrip != null ? 'Edit Trip' : 'Add New Trip'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- Image Picker Section ----
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _pickedImageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_pickedImageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      _pickedImageBytes == null &&
                          _pickedImageBase64 == null &&
                          (widget.existingTrip?.imageUrl.startsWith(
                                'data:image',
                              ) !=
                              true)
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add a cover photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // ---- Destination Input + Location Button ----
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        hintText: 'e.g. Paris, France',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a destination';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // GPS "Tag My Location" button
                  IconButton.filled(
                    onPressed: _isLoadingLocation ? null : _tagLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    tooltip: 'Tag My Location',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---- Date Selectors ----
              Row(
                children: [
                  Expanded(
                    child: _DateSelectorCard(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                      formatter: dateFormatter,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateSelectorCard(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                      formatter: dateFormatter,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ---- Save Button ----
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_startDate == null || _endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select both dates'),
                        ),
                      );
                      return;
                    }

                    final imageUrl =
                        _pickedImageBase64 ??
                        (widget.existingTrip?.imageUrl ??
                            'https://picsum.photos/seed/travel/800/600');

                    if (widget.existingTrip != null) {
                      // UPDATE EXISTING
                      final updatedTrip = widget.existingTrip!.copyWith(
                        destination: _destinationController.text,
                        startDate: _startDate!,
                        endDate: _endDate!,
                        imageUrl: imageUrl,
                      );
                      ref.read(tripProvider.notifier).updateTrip(updatedTrip);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Trip to ${_destinationController.text} updated!',
                          ),
                        ),
                      );
                    } else {
                      // CREATE NEW
                      final newTrip = Trip(
                        id: const Uuid().v4(),
                        destination: _destinationController.text,
                        startDate: _startDate!,
                        endDate: _endDate!,
                        imageUrl: imageUrl,
                      );
                      ref.read(tripProvider.notifier).addTrip(newTrip);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Trip to ${_destinationController.text} added!',
                          ),
                        ),
                      );
                    }

                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  }
                },
                child: Text(
                  widget.existingTrip != null
                      ? 'Update Journey'
                      : 'Save Journey',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSelectorCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final DateFormat formatter;

  const _DateSelectorCard({
    required this.label,
    required this.date,
    required this.onTap,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              date == null ? 'Select' : formatter.format(date!),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: date == null ? Colors.grey : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
