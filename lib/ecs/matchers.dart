import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';

//A valid Note Entity has timestamp, contents and possible tags & todo items.
mixin Matchers {
  static EntityMatcher note = EntityMatcher(
      all: [Timestamp, Contents, DatabaseKey],
      none: [Archived, Priority],
      maybe: [Tags, Todo, Selected]);

  static EntityMatcher archived = EntityMatcher(
      none: [Priority],
      all: [Contents, Timestamp, DatabaseKey, Archived],
      maybe: [Selected, Tags, Todo]);

  static EntityMatcher reminder = EntityMatcher(
      all: [Timestamp, Contents, Priority, DatabaseKey], maybe: [Selected]);

  static EntityMatcher tag = EntityMatcher(all: [TagData], maybe: [Toggle]);

  static EntityMatcher searchResult = note.extend(all: [SearchResult]);

  static EntityMatcher settings =
      EntityMatcher(all: [AppTheme, Localization], maybe: [Toggle]);
}
