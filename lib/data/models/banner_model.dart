String _bannerString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _bannerInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

bool _bannerBool(dynamic value, [bool fallback = true]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? ctaLink;
  final String ctaText;
  final int displayOrder;
  final bool isActive;
  final String? startDate;
  final String? endDate;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.ctaLink,
    this.ctaText = 'Enroll Now',
    required this.displayOrder,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  String? get targetId => ctaLink;
  String get cta => ctaText;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: _bannerString(json['id']),
      title: _bannerString(json['title']),
      subtitle: _bannerString(json['subtitle']),
      imageUrl: _bannerString(json['image_url']),
      ctaLink: _bannerString(json['cta_link'], ''),
      ctaText: _bannerString(json['cta_text'], 'Enroll Now'),
      displayOrder: _bannerInt(json['display_order'] ?? json['sort_order']),
      isActive: _bannerBool(json['is_active']),
      startDate: _bannerString(json['start_date'], ''),
      endDate: _bannerString(json['end_date'], ''),
    );
  }
}