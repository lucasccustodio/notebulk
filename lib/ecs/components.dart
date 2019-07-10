import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';

abstract class _NavigatorController {
  final GlobalKey<NavigatorState> key;

  void goto(String routeName);
  void pop([dynamic value]);

  _NavigatorController(this.key);
}

//Dependency Injection components
class NavigatorControllerComponent extends _NavigatorController
    implements UniqueComponent {
  NavigatorControllerComponent(GlobalKey key) : super(key);

  @override
  void goto(String routeName) => key.currentState.pushNamed(routeName);

  @override
  void pop([dynamic value]) => key.currentState.pop(value);
}

class DatabaseComponent extends UniqueComponent {
  final Database db;

  DatabaseComponent(this.db);
}

class DatabaseKeyComponent extends Component {
  final int dbKey;

  DatabaseKeyComponent(this.dbKey);
}

//Note Entity components
class ShowMenuComponent extends Component {
  final bool showMenu;

  ShowMenuComponent(this.showMenu);
}

class TimestampComponent extends Component {
  final DateTime timestamp;

  TimestampComponent(String _timestamp)
      : timestamp = DateTime.parse(_timestamp);
}

class ContentsComponent extends Component {
  final String contents;

  ContentsComponent(this.contents);
}

class TagsComponent extends Component {
  final String tags;

  TagsComponent(this.tags);
}

class IsListComponent extends Component {
  final List<ListItem> items;

  IsListComponent({this.items = const <ListItem>[]});
}

class ListItem {
  bool isChecked;
  String label;

  ListItem(this.label, {this.isChecked = false});

  factory ListItem.fromJson(Map<String, dynamic> json) =>
      ListItem(json['label'], isChecked: json['isChecked']);

  Map<String, dynamic> toJson() => {'label': label, 'isChecked': isChecked};

  @override
  String toString() => "label: $label, isChecked: $isChecked";

  @override
  int get hashCode => label.hashCode ^ isChecked.hashCode;

  operator ==(dynamic other) =>
      other is ListItem && other.hashCode == this.hashCode;
}

//System components
class ErrorComponent extends UniqueComponent {
  final String error;

  ErrorComponent(this.error);
}

enum NavigationOps { push, pop, replace }

class NavigationSystemComponent extends UniqueComponent {
  final String routeName;
  final NavigationOps routeOp;

  NavigationSystemComponent(
      {this.routeName, this.routeOp = NavigationOps.push});
}

class RefreshNotesComponent extends UniqueComponent {}

class PersistNoteComponent extends UniqueComponent {
  final int dbKey;
  final String contents;
  final String tags;
  final List<ListItem> items;

  PersistNoteComponent({this.contents, this.tags, this.items = const <ListItem>[], this.dbKey});
}

class UpdateNoteComponent extends UniqueComponent {
  final int dbKey;
  final String contents;
  final String tags;
  final List<ListItem> items;

  UpdateNoteComponent({this.contents, this.tags, this.items = const <ListItem>[], this.dbKey});
}

class EditingNoteComponent extends UniqueComponent {}

class DeleteNoteComponent extends UniqueComponent {
  final int dbKey;

  DeleteNoteComponent(this.dbKey);
}

enum FABStatus {
  closed, open
}

class FABStatusComponent extends UniqueComponent {
  final FABStatus status;

  FABStatusComponent({this.status = FABStatus.closed});
}
