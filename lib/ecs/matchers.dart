import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/ecs/components.dart';

//A valid Note Entity has both a timestamp and some contents
class NoteMatcher extends EntityMatcher {
  NoteMatcher() : super(all: [TimestampComponent, ContentsComponent]);
}