import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/theme.dart';

class AppSettingsTag extends UniqueComponent {}

class AppTheme extends Component {
  final BaseTheme value;

  AppTheme(this.value);
}

//Note Entity components
class Archived extends Component {}

class ArchiveNotesEvent extends UniqueComponent {}

class Changed extends Component {}

class ChangeLocaleEvent extends UniqueComponent {
  final String localeCode;

  ChangeLocaleEvent(this.localeCode);
}

class CompleteRemindersEvent extends UniqueComponent {}

class Contents extends Component {
  final String value;

  Contents(this.value);
}

class DatabaseKey extends Component {
  final int value;

  DatabaseKey(this.value);
}

class DiscardSelectedEvent extends UniqueComponent {}

class DisplayStatusTag extends UniqueComponent {}

class ExportNotesEvent extends UniqueComponent {}

//System components
class FeatureEntityTag extends UniqueComponent {}

class ImportNotesEvent extends UniqueComponent {}

class ListItem {
  bool isChecked;

  bool isNumbered;

  String label;
  ListItem(this.label, {this.isChecked = false, this.isNumbered = false});
  ListItem.fromJson(Map<String, dynamic> map)
      : label = map['label'] ?? '',
        isNumbered = map['isNumbered'] ?? false,
        isChecked = map['isChecked'] ?? false;

  @override
  int get hashCode => label.hashCode ^ isChecked.hashCode ^ isNumbered.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is ListItem && other.hashCode == hashCode;

  Map<String, dynamic> toJson() =>
      {'label': label, 'isChecked': isChecked, 'isNumbered': isNumbered};

  @override
  String toString() => toJson().toString();
}

class LoadUserSettingsEvent extends UniqueComponent {}

class MainTickTag extends UniqueComponent {}

class NavigationEvent extends UniqueComponent {
  final String routeName;

  final NavigationOps routeOp;

  NavigationEvent(
      {@required this.routeName, this.routeOp = NavigationOps.push});

  NavigationEvent.pop()
      : routeName = '',
        routeOp = NavigationOps.pop;

  NavigationEvent.push(this.routeName) : routeOp = NavigationOps.push;

  NavigationEvent.replace(this.routeName) : routeOp = NavigationOps.replace;
  NavigationEvent.showDialog(this.routeName)
      : routeOp = NavigationOps.showDialog;
}

enum NavigationOps { push, pop, replace, showDialog }

class PageIndex extends UniqueComponent {
  final int value;

  final int oldValue;
  PageIndex(this.value, {this.oldValue});
}

class PerformSearchEvent extends UniqueComponent {}

class PersistMe extends Component {
  final int key;

  PersistMe([this.key]);
}

class PersistUserSettingsEvent extends UniqueComponent {}

class Picture extends Component {
  final File value;

  Picture(String path) : value = File(path);
}

class Priority extends Component {
  final ReminderPriority value;

  Priority(this.value);
}

class RefreshDatabaseEvent extends UniqueComponent {}

enum ReminderPriority { none, low, medium, high, maximum }

class RestoreNotesEvent extends UniqueComponent {}

class SearchBarTag extends UniqueComponent {}

class SearchResult extends Component {}

class SearchTerm extends Component {
  final String value;

  SearchTerm(this.value);
}

class Selected extends Component {}

class SetupDatabaseEvent extends UniqueComponent {}

class StoragePermission extends UniqueComponent {
  StoragePermission();
}

class TagData extends Component {
  final String value;

  TagData(this.value);
}

class Tags extends Component {
  final List<String> value;

  Tags(this.value);
}

class Tick extends Component {
  final int value;

  Tick(this.value);
}

class Timestamp extends Component {
  final DateTime value;

  Timestamp(String _timestamp) : value = DateTime.parse(_timestamp);
}

class Todo extends Component {
  final List<ListItem> value;

  Todo({this.value = const <ListItem>[]});
}

class Toggle extends Component {}

class WaitForUser extends Component {}
