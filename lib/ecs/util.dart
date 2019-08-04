import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/ecs/components.dart';

void selectNote(Entity toSelect) {
  if (toSelect.hasT<Selected>())
    toSelect.remove<Selected>();
  else
    toSelect.set(Selected());
}
