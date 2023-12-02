enum AnswerResult { positive, negative, unclear }

class Answer {
  DateTime date;
  AnswerResult result;
  String description;

  Answer({required this.date, required this.result, required this.description});

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'result': result.toString(),
      'description': description,
    };
  }

  static Answer fromJson(Map<String, dynamic> json) {
    return Answer(
      date: DateTime.parse(json['date']),
      result:
          AnswerResult.values.firstWhere((e) => e.toString() == json['result']),
      description: json['description'],
    );
  }
}
