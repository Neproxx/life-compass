import 'package:flutter/material.dart';
import 'package:life/models/prayer.dart';
import 'package:life/providers/user_provider.dart';
import 'package:life/services/firestore_service.dart';
import 'package:provider/provider.dart';

class PrayNowScreen extends StatefulWidget {
  const PrayNowScreen({Key? key}) : super(key: key);

  @override
  State<PrayNowScreen> createState() => _PrayNowScreenState();
}

class _PrayNowScreenState extends State<PrayNowScreen> {
  final FirestoreService _db = FirestoreService();
  final List<Prayer> processedPrayers = [];

  List<Prayer> getMostUrgentPrayers(
    List<Prayer> prayers,
    int n,
    List<Prayer> prayersToExclude, {
    bool reverse = false,
  }) {
    // Remove prayers that have already been processed
    prayers.removeWhere((prayer) => prayersToExclude.contains(prayer));

    // Sort prayers by days until next prayer
    prayers.sort(
        (a, b) => a.daysUntilNextPrayer().compareTo(b.daysUntilNextPrayer()));

    // Return the top n prayers
    prayers = prayers.take(n).toList();

    if (reverse) {
      prayers = prayers.reversed.toList();
    }

    return prayers;
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = Provider.of<UserProvider>(context).userId;
    int startIdx = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pray Now'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Prayer>>(
          future: _db.getPrayers(userId, withArchived: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final List<Prayer> prayers = getMostUrgentPrayers(
                snapshot.data!,
                3,
                processedPrayers,
                reverse: true,
              );
              if (prayers.isEmpty) {
                return const Center(child: Text('No prayers to pray now'));
              }
              return Stack(
                children:
                    prayers.sublist(startIdx).asMap().entries.map((entry) {
                  final idx = prayers.length - entry.key; // reverse index
                  final prayer = entry.value;
                  final navText = '$idx/${prayers.length}';
                  return Dismissible(
                    key: UniqueKey(),
                    child: PrayerCard(prayer: prayer, navText: navText),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        // Swiped from right to left
                        // Perform the action for "skipped"
                      } else if (direction == DismissDirection.startToEnd) {
                        // Swiped from left to right
                        // Perform the action for "prayed"
                        prayer.addPrayedTime();
                        _db.updatePrayer(prayer, userId);
                        setState(() => processedPrayers.add(prayer));
                      }
                      prayers.remove(prayer);
                      // Note: This does not work, as the future builder will
                      // fetch the data again and reset everything
                      //setState(() => startIdx++);
                    },
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }
}

class PrayerCard extends StatefulWidget {
  final Prayer prayer;
  final String navText;

  const PrayerCard({
    Key? key,
    required this.prayer,
    required this.navText,
  }) : super(key: key);

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  @override
  Widget build(BuildContext context) {
    HSLColor primaryHSL =
        HSLColor.fromColor(Theme.of(context).colorScheme.primary);
    Color centerC = primaryHSL.withHue((primaryHSL.hue - 20) % 360).toColor();
    Color midC = primaryHSL.withHue((primaryHSL.hue - 10) % 360).toColor();
    Color edgeC = primaryHSL.withHue((primaryHSL.hue) % 360).toColor();
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [edgeC, midC, centerC, midC, edgeC],
          stops: const [0.05, 0.175, 0.5, 0.825, 0.95],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.navText,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              widget.prayer.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(widget.prayer.description),
            ),
          ),
          const SwipeIndicator(),
        ],
      ),
    );
  }
}

class SwipeIndicator extends StatelessWidget {
  const SwipeIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.arrow_back), // Arrow to the left
              Text('Skipped'),
            ],
          ),
          Text("(swipe)",
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.5))),
          const Row(
            children: <Widget>[
              Text('Prayed'),
              Icon(Icons.arrow_forward), // Arrow to the right
            ],
          ),
        ],
      ),
    );
  }
}
