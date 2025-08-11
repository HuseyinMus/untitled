import 'package:flutter/foundation.dart';

class SelectedFilter {
  String? category;
  String? level;

  SelectedFilter({this.category, this.level});

  SelectedFilter copyWith({String? category, String? level}) {
    return SelectedFilter(
      category: category ?? this.category,
      level: level ?? this.level,
    );
  }
}

final ValueNotifier<SelectedFilter> selectedFilterNotifier =
    ValueNotifier<SelectedFilter>(SelectedFilter());


