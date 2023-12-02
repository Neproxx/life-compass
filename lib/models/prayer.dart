import 'package:life/models/prayer_answer.dart';
import 'package:uuid/uuid.dart';

enum PrayerCategory {
  intercession,
  personal,
  thanksgiving,
  praise,
  confession,
  other
}

class Prayer {
  String id;
  String title;
  String description;
  PrayerCategory category;
  int targetFrequencyInDays;
  List<DateTime> prayedTimes; // New property
  List<Answer> answers;
  bool isArchived;

  Prayer({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetFrequencyInDays,
    List<Answer>? answers,
    bool? isArchived,
    List<DateTime>? prayedTimes,
  })  : id = id ?? const Uuid().v4(),
        answers = answers ?? [],
        isArchived = isArchived ?? false,
        prayedTimes = prayedTimes ?? [];

  int daysUntilNextPrayer() {
    if (prayedTimes.isEmpty) {
      return 0;
    }
    DateTime lastPrayedTime = prayedTimes.last;
    DateTime nextPrayedTime =
        lastPrayedTime.add(Duration(days: targetFrequencyInDays));

    if (nextPrayedTime.isBefore(DateTime.now())) {
      return 0;
    }

    return DateTime.now().difference(nextPrayedTime).inDays.abs() + 1;
  }

  void addPrayedTime() {
    prayedTimes.add(DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.toString(),
      'targetFrequencyInDays': targetFrequencyInDays,
      'prayedTimes': prayedTimes.map((e) => e.toIso8601String()).toList(),
      'answers': answers.map((e) => e.toJson()).toList(),
      'isArchived': isArchived,
    };
  }

  static Prayer fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: PrayerCategory.values
          .firstWhere((e) => e.toString() == json['category']),
      targetFrequencyInDays: json['targetFrequencyInDays'],
      prayedTimes: List<DateTime>.from(
          json['prayedTimes'].map((e) => DateTime.parse(e))),
      answers:
          List<Answer>.from(json['answers'].map((e) => Answer.fromJson(e))),
      isArchived: json['isArchived'],
    );
  }
}
