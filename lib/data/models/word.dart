class WordItem {
  final String id;
  final String english;
  final String turkish;
  final String partOfSpeech;
  final String example;
  final String? imageUrl;
  final String? audioUrl;
  final String? mnemonic;
  final List<String> categories; // Örn: ["TOEFL", "IELTS", "SAT"]
  final String? level; // Örn: A1..C2 ya da B2-C1

  const WordItem({
    required this.id,
    required this.english,
    required this.turkish,
    required this.partOfSpeech,
    required this.example,
    this.imageUrl,
    this.audioUrl,
    this.mnemonic,
    this.categories = const <String>[],
    this.level,
  });
}


