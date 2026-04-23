String _attemptString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _attemptInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _attemptDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class AttemptModel {
  final String id;
  final String? studentId;
  final String? testId;
  final int score;
  final String status;
  final DateTime? submittedAt;
  final DateTime? createdAt;
  final String? testTitle;
  final String? studentName;
  final int? totalMarks;
  final String? resultText;

  const AttemptModel({
    required this.id,
    this.studentId,
    this.testId,
    required this.score,
    required this.status,
    this.submittedAt,
    this.createdAt,
    this.testTitle,
    this.studentName,
    this.totalMarks,
    this.resultText,
  });

  factory AttemptModel.fromJson(Map<String, dynamic> json) {
    final test = json['tests'];
    final student = json['students'];
    final testMap = test is Map<String, dynamic> ? test : const <String, dynamic>{};
    final studentMap = student is Map<String, dynamic> ? student : const <String, dynamic>{};

    return AttemptModel(
      id: _attemptString(json['id']),
      studentId: _attemptString(json['student_id'], ''),
      testId: _attemptString(json['test_id'], ''),
      score: _attemptInt(json['score']),
      status: _attemptString(json['status'], 'completed'),
      submittedAt: _attemptDateTime(json['submitted_at']),
      createdAt: _attemptDateTime(json['created_at']),
      testTitle: _attemptString(testMap['title'], ''),
      studentName: _attemptString(studentMap['full_name'] ?? studentMap['name'], ''),
      totalMarks: _attemptInt(testMap['total_marks'], 0),
      resultText: _attemptString(json['result'], ''),
    );
  }
}