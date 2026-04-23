enum RealtimeMutationType { inserted, updated, deleted }

class DataChange<T> {
  final RealtimeMutationType type;
  final String id;
  final T? current;
  final T? previous;

  const DataChange({
    required this.type,
    required this.id,
    this.current,
    this.previous,
  });
}