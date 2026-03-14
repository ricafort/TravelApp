import 'package:flutter/material.dart';

class CurrencyCard extends StatelessWidget {
  final String destination;

  const CurrencyCard({super.key, required this.destination});

  // A tiny static dictionary mapping common travel regions to estimated conversion rates vs USD
  static const Map<String, Map<String, String>> _exchangeRates = {
    'japan': {'symbol': '¥', 'name': 'JPY', 'rate': '150.0'},
    'greece': {'symbol': '€', 'name': 'EUR', 'rate': '0.92'},
    'spain': {'symbol': '€', 'name': 'EUR', 'rate': '0.92'},
    'italy': {'symbol': '€', 'name': 'EUR', 'rate': '0.92'},
    'france': {'symbol': '€', 'name': 'EUR', 'rate': '0.92'},
    'germany': {'symbol': '€', 'name': 'EUR', 'rate': '0.92'},
    'uk': {'symbol': '£', 'name': 'GBP', 'rate': '0.78'},
    'london': {'symbol': '£', 'name': 'GBP', 'rate': '0.78'},
    'canada': {'symbol': 'CA\$', 'name': 'CAD', 'rate': '1.35'},
    'australia': {'symbol': 'A\$', 'name': 'AUD', 'rate': '1.50'},
    'sydney': {'symbol': 'A\$', 'name': 'AUD', 'rate': '1.50'},
  };

  Map<String, String>? _getExchangeRate() {
    final lowerDest = destination.toLowerCase();
    for (final key in _exchangeRates.keys) {
      if (lowerDest.contains(key)) {
        return _exchangeRates[key];
      }
    }
    return null; // Return null if unsupported or implicitly domestic
  }

  @override
  Widget build(BuildContext context) {
    final rateData = _getExchangeRate();

    // Hide widget if we don't have conversion data for this destination
    if (rateData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.currency_exchange, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Text(
            '1 USD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 14, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Text(
            '${rateData['symbol']}${rateData['rate']} ${rateData['name']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
