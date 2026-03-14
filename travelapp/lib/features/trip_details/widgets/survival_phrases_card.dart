import 'package:flutter/material.dart';

class SurvivalPhrasesCard extends StatelessWidget {
  final String destination;

  const SurvivalPhrasesCard({super.key, required this.destination});

  // A tiny local dictionary for top foreign destinations
  static const Map<String, List<Map<String, String>>> _dictionary = {
    'japan': [
      {'eng': 'Hello', 'local': 'こんにちは (Konnichiwa)'},
      {'eng': 'Thank you', 'local': 'ありがとう (Arigato)'},
      {'eng': 'Excuse me', 'local': 'すみません (Sumimasen)'},
      {
        'eng': 'Where is the bathroom?',
        'local': 'トイレはどこですか？ (Toire wa doko desu ka?)',
      },
      {'eng': 'How much?', 'local': 'いくらですか？ (Ikura desu ka?)'},
    ],
    'france': [
      {'eng': 'Hello', 'local': 'Bonjour'},
      {'eng': 'Thank you', 'local': 'Merci'},
      {'eng': 'Please', 'local': 'S\'il vous plaît'},
      {'eng': 'Where is the bathroom?', 'local': 'Où sont les toilettes ?'},
      {'eng': 'Do you speak English?', 'local': 'Parlez-vous anglais ?'},
    ],
    'greece': [
      {'eng': 'Hello', 'local': 'Γειά σου (Yassou)'},
      {'eng': 'Thank you', 'local': 'Ευχαριστώ (Efcharistó)'},
      {'eng': 'Please/You\'re welcome', 'local': 'Παρακαλώ (Parakaló)'},
      {'eng': 'Yes / No', 'local': 'Ναι (Né) / Όχι (Óchi)'},
      {'eng': 'How much is it?', 'local': 'Πόσο κάνει; (Póso káni?)'},
    ],
    'spain': [
      {'eng': 'Hello', 'local': 'Hola'},
      {'eng': 'Thank you', 'local': 'Gracias'},
      {'eng': 'Please', 'local': 'Por favor'},
      {'eng': 'Where is the bathroom?', 'local': '¿Dónde está el baño?'},
      {'eng': 'How much?', 'local': '¿Cuánto cuesta?'},
    ],
    'italy': [
      {'eng': 'Hello/Goodbye', 'local': 'Ciao'},
      {'eng': 'Thank you', 'local': 'Grazie'},
      {'eng': 'Please', 'local': 'Per favore'},
      {'eng': 'Where is the bathroom?', 'local': 'Dov\'è il bagno?'},
      {'eng': 'How much?', 'local': 'Quanto costa?'},
    ],
  };

  // Helper to determine if the destination string matches any dictionary keys
  List<Map<String, String>>? _getPhrases() {
    final lowerDest = destination.toLowerCase();
    for (final key in _dictionary.keys) {
      if (lowerDest.contains(key)) {
        return _dictionary[key];
      }
    }
    return null; // Return null if English-speaking or unsupported
  }

  @override
  Widget build(BuildContext context) {
    final phrases = _getPhrases();

    // If we don't have phrases for this destination, don't show the widget at all!
    if (phrases == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.translate, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Local Survival Phrases',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < phrases.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i == phrases.length - 1 ? 0 : 12.0,
                      ),
                      child: _buildPhraseCard(
                        phrases[i]['eng']!,
                        phrases[i]['local']!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhraseCard(String english, String localText) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // VERY subtle shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            english,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.indigo.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
