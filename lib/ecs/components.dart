import 'dart:math';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:sembast/sembast.dart';

//Dependency Injection components
class DatabaseComponent extends UniqueComponent {
  final Database db;

  DatabaseComponent(this.db);
}

class RandomGeneratorComponent extends UniqueComponent {
  final Random random;

  RandomGeneratorComponent(this.random);
}

class DatabaseKeyComponent extends Component {
  final int dbKey;

  DatabaseKeyComponent(this.dbKey);
}

//Entity components
class TimestampComponent extends Component {
  final DateTime timestamp;

  TimestampComponent(String _timestamp) : timestamp = DateTime.parse(_timestamp);
}

class ContentsComponent extends Component {
  final String contents;

  ContentsComponent(this.contents);
}

class TagsComponent extends Component {
  final String tags;

  TagsComponent(this.tags);
}

//System components
class ErrorComponent extends UniqueComponent {
  final String error;

  ErrorComponent(this.error);
}

class ShowSingleNoteComponent extends UniqueComponent {}

class IsSelectedComponent extends UniqueComponent {}

class IsEditingComponent extends UniqueComponent {}

class IsNewNoteComponent extends UniqueComponent {}

class PersistNoteComponent extends UniqueComponent {}

class UpdateNoteComponent extends UniqueComponent {}

class DeleteNoteComponent extends UniqueComponent {}
