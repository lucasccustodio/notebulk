import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';

class SetupLocalizationEvent extends UniqueComponent {
  SetupLocalizationEvent(this.context);

  final BuildContext context;
}

class SetupDatabaseEvent extends UniqueComponent {}

class DatabaseService extends UniqueComponent {
  DatabaseService(this.value);

  final Database value;
}

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

class Tags extends Component {
  Tags(this.value);

  final List<String> value;
}

class Archived extends Component {}

class Todo extends Component {
  Todo({this.value = const <ListItem>[]});

  final List<ListItem> value;
}

class ListItem {
  ListItem(this.label, {this.isChecked = false});

  ListItem.fromJson(Map<String, dynamic> map)
      : label = map['label'],
        isChecked = map['isChecked'];

  bool isChecked;
  String label;

  Map<String, dynamic> toJson() => {'label': label, 'isChecked': isChecked};

  @override
  String toString() => 'label: $label, isChecked: $isChecked';

  @override
  int get hashCode => label.hashCode ^ isChecked.hashCode;

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

class PageNavigationTag extends UniqueComponent {}

class CurrentIndex extends Component {
  CurrentIndex([this.value = 0]);

  final int value;
}

class NextIndex extends Component {
  NextIndex(this.value);

  final int value;
}

class StoragePermission extends UniqueComponent {
  StoragePermission({this.value = true});

  final bool value;
}

class Ready extends Component {}

class LoadUserSettingsEvent extends UniqueComponent {}

class RefreshNotesEvent extends UniqueComponent {}

class DeleteNotesEvent extends UniqueComponent {}

class ArchiveNotesEvent extends UniqueComponent {}

class RestoreNotesEvent extends UniqueComponent {}

class ExportNotesEvent extends UniqueComponent {}

class ImportNotesEvent extends UniqueComponent {}

class FeatureEntityTag extends UniqueComponent {}

class Changed extends Component {}

class PersistMe extends Component {}

class UpdateMe extends Component {}

class DisplayStatusTag extends UniqueComponent {}

class SplashScreenTag extends UniqueComponent {}

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

class ThemeColor extends Component {
  ThemeColor(this.value);

  final Color value;
}

class DarkMode extends Component {
  DarkMode({this.value = true});

  final bool value;
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
