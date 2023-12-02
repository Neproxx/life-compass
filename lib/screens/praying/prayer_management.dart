import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:life/mock/prayers.dart';
import 'package:life/models/prayer.dart';
import 'package:life/providers/user_provider.dart';
import 'package:life/screens/praying/pray_now.dart';
import 'package:life/screens/praying/prayer_details.dart';
import 'package:life/screens/praying/prayer_list_tile.dart';
import 'package:life/services/firestore_service.dart';

class PrayerListScreen extends StatefulWidget {
  const PrayerListScreen({Key? key}) : super(key: key);

  @override
  State<PrayerListScreen> createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends State<PrayerListScreen> {
  final Set<Prayer> _selectedPrayers = {};
  final FirestoreService _db = FirestoreService();
  bool _showArchived = false;

  void _togglePrayer(Prayer prayer) {
    setState(() {
      if (_selectedPrayers.contains(prayer)) {
        _selectedPrayers.remove(prayer);
      } else {
        _selectedPrayers.add(prayer);
      }
    });
  }

  void _applyToSelectedPrayers(
      Function(List<Prayer>, String) fn, String? userId) {
    if (userId == null) {
      return;
    }

    fn(_selectedPrayers.toList(), userId);
    setState(() => _selectedPrayers.clear());
  }

  void _acceptPrayers(String? userId) {
    setState(() {
      for (var prayer in _selectedPrayers) {
        prayer.prayedTimes.add(DateTime.now());
      }
    });
    _applyToSelectedPrayers(_db.updatePrayers, userId);
  }

  void _toggleShowArchivedPrayers() {
    setState(() => _showArchived = !_showArchived);
  }

  void _setArchiveStatus(bool setArchived, String? userId) {
    setState(() {
      for (var prayer in _selectedPrayers) {
        prayer.isArchived = setArchived;
      }
    });
    _applyToSelectedPrayers(_db.updatePrayers, userId);
  }

  void _deletePrayers(String? userId) {
    _applyToSelectedPrayers(_db.deletePrayers, userId);
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = Provider.of<UserProvider>(context).userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer List'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showArchived ? Icons.archive : Icons.unarchive),
            onPressed: _toggleShowArchivedPrayers,
          ),

          // Button to add mock prayers for debugging purposes
          IconButton(
            padding: const EdgeInsets.only(right: 24),
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => _db.addPrayers(mockPrayers, userId),
          ),

          IconButton(
            padding: const EdgeInsets.only(right: 24),
            icon: const Text('🙏', style: TextStyle(fontSize: 25.0)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrayNowScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Prayer>>(
          stream: _db.getPrayersStream(userId, withArchived: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No prayers found'));
            }

            final prayers = snapshot.data!;
            final sortedPrayers = filterAndSortPrayers(prayers, _showArchived);

            return Container(
              margin: const EdgeInsets.only(top: 2),
              child: ListView.builder(
                itemCount: sortedPrayers.length,
                itemBuilder: (context, index) {
                  final prayer = sortedPrayers[index];
                  final dueInText = prayer.daysUntilNextPrayer() == 0
                      ? 'due today'
                      : prayer.daysUntilNextPrayer() == 1
                          ? 'due tomorrow'
                          : 'due in ${prayer.daysUntilNextPrayer()} days';
                  final dueColor = prayer.daysUntilNextPrayer() == 0
                      ? Theme.of(context).colorScheme.error
                      : (prayer.daysUntilNextPrayer() <
                              prayer.targetFrequencyInDays / 2)
                          ? const Color(0xffffd600)
                          : Theme.of(context).colorScheme.secondary;
                  final isSelected = _selectedPrayers.contains(prayer);
                  final primaryColor = Theme.of(context).colorScheme.primary;
                  final gradientColors = prayer.isArchived
                      ? [
                          Theme.of(context).colorScheme.background,
                          getDarkerColor(
                              Theme.of(context).colorScheme.background)
                        ]
                      : [primaryColor, getDarkerColor(primaryColor)];

                  // When a prayer is selected, indent it by 8 pixels
                  return Transform.translate(
                    offset:
                        isSelected ? const Offset(8, 0) : const Offset(0, 0),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: gradientColors,
                          ),
                        ),
                        child: PrayerListTile(
                          leading: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                          title: Text(
                            prayer.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            prayer.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          trailing: prayer.isArchived
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    'Archived',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 88,
                                      child: LinearProgressIndicator(
                                        value: 1 -
                                            prayer.daysUntilNextPrayer() /
                                                prayer.targetFrequencyInDays,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          dueColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dueInText,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                          onLongPress: () => _togglePrayer(prayer),
                          onTap: () {
                            if (_selectedPrayers.isNotEmpty) {
                              _togglePrayer(prayer);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PrayerDetailScreen(prayer: prayer),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
      floatingActionButton: _selectedPrayers.isEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrayerDetailScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,

      // If a button is selected, show a bottom app bar with multiple actions
      bottomNavigationBar: _selectedPrayers.isEmpty
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        _acceptPrayers(userId);
                      },
                      color: Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.archive),
                      onPressed: () {
                        _setArchiveStatus(true, userId);
                      },
                      color: Colors.orange,
                    ),
                    IconButton(
                      icon: const Icon(Icons.unarchive),
                      onPressed: () {
                        _setArchiveStatus(false, userId);
                      },
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm'),
                              content: const Text(
                                  'Are you sure you want to delete selected prayers?'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(
                                    'CANCEL',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('DELETE',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                                  onPressed: () {
                                    _deletePrayers(userId);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

Color getDarkerColor(Color color) {
  return color.withOpacity(0.35);
}

List<Prayer> filterAndSortPrayers(List<Prayer> prayers, bool showAll) {
  final filteredPrayers =
      showAll ? prayers : prayers.where((prayer) => !prayer.isArchived);

  // Sort by isArchived, then by daysUntilNextPrayer
  final sortedPrayers = filteredPrayers.toList()
    ..sort((a, b) {
      if (a.isArchived != b.isArchived) {
        return a.isArchived ? 1 : -1;
      }
      return a.daysUntilNextPrayer().compareTo(b.daysUntilNextPrayer());
    });

  return sortedPrayers;
}
