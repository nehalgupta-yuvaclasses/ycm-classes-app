class PaginatedResult<T> {
  final List<T> items;
  final int limit;
  final int offset;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  PaginatedResult<T> copyWith({
    List<T>? items,
    int? limit,
    int? offset,
    bool? hasMore,
  }) {
    return PaginatedResult<T>(
      items: items ?? this.items,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}