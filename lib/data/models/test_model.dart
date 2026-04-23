List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const <String>[];
}

String _stringValue(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _intValue(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _dateTimeValue(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class TestModel {
  final String id;
  final String title;
  final String? description;
  final String? courseId;
  final String? subjectId;
  final int durationMinutes;
  final int totalQuestions;
  final int totalMarks;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<QuestionModel>? questions;

  const TestModel({
    required this.id,
    required this.title,
    this.description,
    this.courseId,
    this.subjectId,
    required this.durationMinutes,
    required this.totalQuestions,
    this.totalMarks = 0,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.questions,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: _stringValue(json['id']),
      title: _stringValue(json['title'], 'Untitled test'),
      description: _stringValue(json['description'], ''),
      courseId: _stringValue(json['course_id'], ''),
      subjectId: _stringValue(json['subject_id'], ''),
      durationMinutes: _intValue(json['duration'] ?? json['duration_minutes']),
      totalQuestions: _intValue(json['total_questions']),
      totalMarks: _intValue(json['total_marks'] ?? json['marks']),
      status: _stringValue(json['status'], 'draft'),
      createdAt: _dateTimeValue(json['created_at']),
      updatedAt: _dateTimeValue(json['updated_at']),
      questions: (json['questions'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(QuestionModel.fromJson)
          .toList(),
    );
  }
}

class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final int marks;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.marks = 1,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: _stringValue(json['id']),
      question: _stringValue(json['question_text'] ?? json['question'], 'Question'),
      options: _asStringList(json['options']),
      correctIndex: _intValue(json['correct_answer'] ?? json['correct_index']),
      explanation: _stringValue(json['explanation'], ''),
      marks: _intValue(json['marks'], 1),
    );
  }
}