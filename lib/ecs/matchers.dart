import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/ecs/components.dart';

//A valid Note Entity has both a timestamp, datatbase key and some contents
class Matchers {
  static EntityMatcher note = EntityMatcher(
      all: [TimestampComponent, ContentsComponent, DatabaseKeyComponent],
      none: [ArchivedComponent],
      maybe: [ShowMenuComponent, ListComponent]);

  static EntityMatcher archived = EntityMatcher(
      all: [TimestampComponent, ContentsComponent, DatabaseKeyComponent, ArchivedComponent],
      maybe: [ShowMenuComponent, ListComponent]);
}
