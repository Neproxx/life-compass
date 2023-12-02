import 'package:life/models/prayer.dart';
import 'package:life/models/prayer_answer.dart';

Prayer prayer1 = Prayer(
  id: '1',
  title: 'Pray for World Peace',
  description: 'Pray for peace and harmony in the world',
  category: PrayerCategory.intercession,
  targetFrequencyInDays: 5,
  answers: [
    Answer(
        date: DateTime.now(),
        result: AnswerResult.unclear,
        description: 'Unclear result')
  ],
  isArchived: false,
  prayedTimes: [
    DateTime.now().subtract(const Duration(days: 6)),
    DateTime.now().subtract(const Duration(days: 4)),
    DateTime.now().subtract(const Duration(days: 2)),
  ],
);

Prayer prayer2 = Prayer(
  id: '2',
  title: 'Pray for Personal Growth',
  description: 'Pray for personal development and spiritual growth',
  category: PrayerCategory.personal,
  targetFrequencyInDays: 7,
  answers: [
    Answer(
        date: DateTime.now(),
        result: AnswerResult.positive,
        description: 'Positive result')
  ],
  isArchived: false,
  prayedTimes: [
    DateTime.now().subtract(const Duration(days: 21)),
    DateTime.now().subtract(const Duration(days: 14)),
    DateTime.now().subtract(const Duration(days: 7)),
  ],
);

Prayer prayer3 = Prayer(
  id: '3',
  title: 'Pray for Revival',
  description: 'Pray for a spiritual revival in our community',
  category: PrayerCategory.intercession,
  targetFrequencyInDays: 7,
  answers: [
    Answer(
        date: DateTime.now(),
        result: AnswerResult.negative,
        description: 'Negative result')
  ],
  isArchived: true,
  prayedTimes: [
    DateTime.now().subtract(const Duration(days: 12)),
    DateTime.now().subtract(const Duration(days: 8)),
    DateTime.now().subtract(const Duration(days: 4)),
  ],
);

List<Prayer> mockPrayers = [prayer1, prayer2, prayer3];
