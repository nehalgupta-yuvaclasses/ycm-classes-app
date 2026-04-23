String _resultString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _resultDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class ResultModel {
  final String id;
  final String studentName;
  final String exam;
  final String rank;
  final String? imageUrl;
  final String? resultText;
  final DateTime? createdAt;

  const ResultModel({
    required this.id,
    required this.studentName,
    required this.exam,
    required this.rank,
    this.imageUrl,
    this.resultText,
    this.createdAt,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      id: _resultString(json['id']),
      studentName: _resultString(json['student_name'], 'Student'),
      exam: _resultString(json['exam'], 'Exam'),
      rank: _resultString(json['rank'], '-'),
      imageUrl: _resultString(json['image_url'], ''),
      resultText: _resultString(json['result'], ''),
      createdAt: _resultDateTime(json['created_at']),
    );
  }
}