class WordListMeta {
  final String id;
  final String name;
  final String? description;
  final int itemCount;
  final DateTime createdAt;

  const WordListMeta({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.createdAt,
    this.description,
  });
}


