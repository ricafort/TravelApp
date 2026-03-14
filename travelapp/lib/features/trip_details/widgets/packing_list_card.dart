import 'package:flutter/material.dart';
import '../../home/models/trip.dart';

class PackingListCard extends StatefulWidget {
  final Trip trip;

  const PackingListCard({super.key, required this.trip});

  @override
  State<PackingListCard> createState() => _PackingListCardState();
}

class _PackingListCardState extends State<PackingListCard> {
  // A local state to keep track of checked items just for UI interaction
  final Set<String> _checkedItems = {};
  List<String> _packingList = [];

  @override
  void initState() {
    super.initState();
    _packingList = _generatePackingList();
  }

  List<String> _generatePackingList() {
    final List<String> list = [
      'Passport & ID',
      'Phone Charger',
      'Toothbrush & Toiletries',
      'Underwear & Socks',
    ];

    // Duration-based logic
    final duration = widget.trip.endDate
        .difference(widget.trip.startDate)
        .inDays;
    if (duration > 5) {
      list.addAll([
        'Laundry Bag',
        'Portable Power Bank',
        'Extra pairs of shoes',
      ]);
    }

    // Context/Destination-based logic
    final dest = widget.trip.destination.toLowerCase();

    if (dest.contains('banff') ||
        dest.contains('canada') ||
        dest.contains('mountain')) {
      list.addAll([
        'Hiking Boots',
        'Warm Layers & Jacket',
        'Bear Bell',
        'Water Bottle',
      ]);
    } else if (dest.contains('santorini') ||
        dest.contains('greece') ||
        dest.contains('beach') ||
        dest.contains('spain')) {
      list.addAll(['Sunscreen', 'Swimwear', 'Sunglasses', 'Beach Towel']);
    } else if (dest.contains('kyoto') ||
        dest.contains('japan') ||
        dest.contains('city') ||
        dest.contains('london')) {
      list.addAll([
        'Comfortable Walking Shoes',
        'Universal Travel Adapter',
        'Coin Purse',
        'Small Daypack',
      ]);
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(Icons.luggage, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Suggested Packing List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: _packingList.map((item) {
              final isChecked = _checkedItems.contains(item);
              return CheckboxListTile(
                title: Text(
                  item,
                  style: TextStyle(
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? Colors.grey : Colors.black87,
                  ),
                ),
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _checkedItems.add(item);
                    } else {
                      _checkedItems.remove(item);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
                activeColor: Colors.orange,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
