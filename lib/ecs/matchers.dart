import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/ecs/components.dart';

//A valid Note Entity has timestamp, contents and possible tags & todo items.
mixin Matchers {
  static EntityMatcher note = EntityMatcher(
      all: [Timestamp, Contents],
      none: [Archived],
      maybe: [Tags, Selected, Todo]);

  static EntityMatcher archived =
      note.extend(all: [Archived]).copyWith(none: []);

  static EntityMatcher searchResult = note.extend(all: [SearchResult]);

  static EntityMatcher settings = EntityMatcher(any: [ThemeColor, DarkMode]);
}
