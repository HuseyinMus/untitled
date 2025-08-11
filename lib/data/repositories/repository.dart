import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/models/user_word_state.dart';
import 'package:untitled/data/models/word.dart';

abstract class Repository {
  List<WordItem> get catalog;
  UserWordState getOrCreateState(String wordId);
  List<WordItem> dueWords({int limit = 20});
  void applyReview(String wordId, ReviewGrade grade);
  // Dinamik filtreleme: kategori/level bazlı listeleme
  List<String> availableCategories();
  List<String> availableLevels();
  List<WordItem> byCategory(String category);
  List<WordItem> byLevel(String level);
}


