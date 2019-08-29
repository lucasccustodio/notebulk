import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/theme.dart';

class SetupLocalizationEvent extends UniqueComponent {
  SetupLocalizationEvent(this.context);

  final BuildContext context;
}

class SetupDatabaseEvent extends UniqueComponent {}

class DatabaseKey extends Component {
  DatabaseKey(this.value);

  final int value;
}

//Note Entity components
class Timestamp extends Component {
  Timestamp(String _timestamp) : value = DateTime.parse(_timestamp);

  final DateTime value;
}

class Picture extends Component {
  Picture(String path) : value = File(path);

  final File value;
}

class Contents extends Component {
  Contents(this.value);

  final String value;
}

enum ReminderPriority { none, low, medium, high, maximum }

class Priority extends Component {
  final ReminderPriority value;

  Priority(this.value);
}

class Tags extends Component {
  Tags(this.value);

  final List<String> value;
}

class Archived extends Component {}

class Todo extends Component {
  Todo({this.value = const <ListItem>[]});

  final List<ListItem> value;
}

class TagData extends Component {
  final String value;
  final Color color;

  TagData(this.value, [this.color]);
}

class ListItem {
  ListItem(this.label, {this.isChecked = false, this.isNumbered = false});

  ListItem.fromJson(Map<String, dynamic> map)
      : label = map['label'] ?? '',
        isNumbered = map['isNumbered'] ?? false,
        isChecked = map['isChecked'] ?? false;

  bool isChecked;
  bool isNumbered;
  String label;

  Map<String, dynamic> toJson() =>
      {'label': label, 'isChecked': isChecked, 'isNumbered': isNumbered};

  @override
  String toString() => toJson().toString();

  @override
  int get hashCode => label.hashCode ^ isChecked.hashCode ^ isNumbered.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is ListItem && other.hashCode == hashCode;
}

//System components
enum NavigationOps { push, pop, replace, showDialog }

class NavigationEvent extends UniqueComponent {
  NavigationEvent(
      {@required this.routeName, this.routeOp = NavigationOps.push});

  NavigationEvent.pop()
      : routeName = '',
        routeOp = NavigationOps.pop;

  NavigationEvent.push(this.routeName) : routeOp = NavigationOps.push;

  NavigationEvent.showDialog(this.routeName)
      : routeOp = NavigationOps.showDialog;

  NavigationEvent.replace(this.routeName) : routeOp = NavigationOps.replace;

  final String routeName;
  final NavigationOps routeOp;
}

class PageIndex extends UniqueComponent {
  PageIndex(this.value, {this.oldValue});

  final int value;
  final int oldValue;
}

class StoragePermission extends UniqueComponent {
  StoragePermission();
}

class Ready extends Component {}

class PersistUserSettingsEvent extends UniqueComponent {}

class LoadUserSettingsEvent extends UniqueComponent {}

class RefreshDatabaseEvent extends UniqueComponent {}

class DiscardSelectedEvent extends UniqueComponent {}

class ArchiveNotesEvent extends UniqueComponent {}

class RestoreNotesEvent extends UniqueComponent {}

class ExportNotesEvent extends UniqueComponent {}

class ImportNotesEvent extends UniqueComponent {}

class CompleteRemindersEvent extends UniqueComponent {}

class FeatureEntityTag extends UniqueComponent {}

class WaitForUser extends Component {}

class Changed extends Component {}

class PersistMe extends Component {
  final int key;

  PersistMe([this.key]);
}

class DisplayStatusTag extends UniqueComponent {}

class Selected extends Component {}

class SearchResult extends Component {}

class SearchTerm extends Component {
  SearchTerm(this.value);

  final String value;
}

class PerformSearchEvent extends UniqueComponent {}

class Counter extends Component {
  Counter(this.value);

  final int value;
}

class AppTheme extends Component {
  final BaseTheme value;

  AppTheme(this.value);
}

class Toggle extends Component {}

class FABTag extends UniqueComponent {}

class MainTickTag extends UniqueComponent {}

class Tick extends Component {
  Tick(this.value);

  final int value;
}

class SearchBarTag extends UniqueComponent {}

class AppSettingsTag extends UniqueComponent {}

class GridCount extends Component {
  GridCount([this.value = 2]);

  final int value;
}

class ChangeLocaleEvent extends UniqueComponent {
  final String localeCode;

  ChangeLocaleEvent(this.localeCode);
}
