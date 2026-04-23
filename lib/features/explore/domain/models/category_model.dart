class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final int displayOrder;
  final String status;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.displayOrder = 0,
    this.status = 'Active',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'],
      slug: json['slug'],
      iconUrl: json['icon_url'],
      displayOrder: json['display_order'] ?? 0,
      status: json['status'] ?? 'Active',
    );
  }
}
