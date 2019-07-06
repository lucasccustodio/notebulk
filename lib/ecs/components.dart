import 'dart:math';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:sembast/sembast.dart';

//Dependency Injection components
class DatabaseComponent extends UniqueComponent {
  final Database db;

  DatabaseComponent(this.db);
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

enum ViewMode {
  showNotes, createNote, editNote, filterNotes
}

class ViewModeComponent extends UniqueComponent {
  final ViewMode viewMode;

  ViewModeComponent([this.viewMode = ViewMode.showNotes]);
}

//TODO: Find a better name
class DisplayAsSingleComponent extends UniqueComponent {}

class IsSelectedComponent extends UniqueComponent {}

class PersistNoteComponent extends UniqueComponent {}

class UpdateNoteComponent extends UniqueComponent {}

class DeleteNoteComponent extends UniqueComponent {}
