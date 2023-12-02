import 'package:flutter/material.dart';
import 'package:life/models/prayer.dart';
import 'package:life/providers/user_provider.dart';
import 'package:life/services/firestore_service.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Prayer? prayer;

  const PrayerDetailScreen({Key? key, this.prayer}) : super(key: key);

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetFrequencyInDaysController;
  late PrayerCategory _category;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prayer?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.prayer?.description ?? '');
    _targetFrequencyInDaysController = TextEditingController(
        text: widget.prayer?.targetFrequencyInDays.toString() ?? '7');
    _category = widget.prayer?.category ?? PrayerCategory.personal;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetFrequencyInDaysController.dispose();
    super.dispose();
  }

  void setModified(_) {
    setState(() {
      _isModified = true;
    });
  }

  Map<DateTime, int> getHeatMapData(Prayer prayer) {
    Map<DateTime, int> data = {};
    for (var date in prayer.prayedTimes) {
      // Normalize the date to remove time
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      data[normalizedDate] = 1;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    String? userId = Provider.of<UserProvider>(context).userId;

    return WillPopScope(
      onWillPop: () async {
        if (_isModified) {
          final bool? shouldLeave = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved changes'),
              content: const Text(
                  'You have unsaved changes. Are you sure you want to leave?'),
              actions: [
                TextButton(
                  child: const Text('No'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );
          return shouldLeave ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Prayer Details'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Input fields
              const Text(
                'Prayer properties',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: setModified,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: setModified,
              ),
              TextField(
                controller: _targetFrequencyInDaysController,
                decoration: const InputDecoration(
                    labelText: 'Target Frequency In Days'),
                keyboardType: TextInputType.number,
                onChanged: setModified,
              ),
              DropdownButton<PrayerCategory>(
                value: _category,
                onChanged: (PrayerCategory? newValue) {
                  setState(() {
                    _category = newValue!;
                    _isModified = true;
                  });
                },
                items: PrayerCategory.values
                    .map<DropdownMenuItem<PrayerCategory>>(
                        (PrayerCategory value) {
                  return DropdownMenuItem<PrayerCategory>(
                    value: value,
                    child: Text(value.toString().split('.').last),
                  );
                }).toList(),
              ),

              // Heatmap calendar for prayer history
              widget.prayer != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Explore your prayer history',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Center(
                          child: HeatMapCalendar(
                            datasets: getHeatMapData(widget.prayer!),
                            colorsets: {
                              1: Theme.of(context).colorScheme.primary
                            },
                          ),
                        ),
                      ],
                    )
                  : Container(),
              const SizedBox(height: 16),

              // Buttons for saving and deleting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Save button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Update existing prayer
                      if (widget.prayer != null) {
                        widget.prayer!.title = _titleController.text;
                        widget.prayer!.description =
                            _descriptionController.text;
                        widget.prayer!.category = _category;
                        widget.prayer!.targetFrequencyInDays =
                            int.parse(_targetFrequencyInDaysController.text);
                        FirestoreService().updatePrayer(widget.prayer!, userId);
                      }
                      // Add new prayer
                      else {
                        final prayer = Prayer(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          category: _category,
                          targetFrequencyInDays:
                              int.parse(_targetFrequencyInDaysController.text),
                        );
                        FirestoreService().addPrayer(prayer, userId);
                      }

                      Navigator.of(context).pop();
                      setState(() {
                        _isModified = false;
                      });
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),

                  // Delete button
                  ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                  'Are you sure you want to delete this prayer?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    FirestoreService()
                                        .deletePrayer(widget.prayer!.id, userId)
                                        .then((success) {
                                      if (success) {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                        Navigator.of(context)
                                            .pop(); // Return to the previous screen
                                      }
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
