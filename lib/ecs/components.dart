import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';

class DatabaseComponent extends UniqueComponent {
  final Database db;

  DatabaseComponent(this.db);
}

class DatabaseKeyComponent extends Component {
  final int dbKey;

  DatabaseKeyComponent(this.dbKey);
}

//Note Entity components
class ShowMenuComponent extends Component {}

class TimestampComponent extends Component {
  final DateTime timestamp;

  TimestampComponent(String _timestamp)
      : timestamp = DateTime.parse(_timestamp);
}

class PictureComponent extends Component {
  final File pic;

  PictureComponent(String path) : pic = File(path);
}

class ContentsComponent extends Component {
  final String contents;

  ContentsComponent(this.contents);
}

class TagsComponent extends Component {
  final List<String> tags;

  TagsComponent(this.tags);
}

class ArchivedComponent extends Component {}

class ListComponent extends Component {
  final List<ListItem> items;

  ListComponent({this.items = const <ListItem>[]});
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

enum NavigationOps { push, pop, replace, showDialog }

class NavigationSystemComponent extends UniqueComponent {
  final String routeName;
  final NavigationOps routeOp;

  NavigationSystemComponent.pop()
      : routeName = '',
        routeOp = NavigationOps.pop;

  NavigationSystemComponent.push(String name)
      : routeName = name,
        routeOp = NavigationOps.push;

  NavigationSystemComponent.showDialog(String name)
      : routeName = name,
        routeOp = NavigationOps.showDialog;

  NavigationSystemComponent.replace(String name)
      : routeName = name,
        routeOp = NavigationOps.replace;

  NavigationSystemComponent(
      {this.routeName, this.routeOp = NavigationOps.push});
}

class CurrentPageComponent extends UniqueComponent {
  final int index;

  CurrentPageComponent([this.index = 0]);
}

class StoragePermissionComponent extends UniqueComponent {
  final bool granted;

  StoragePermissionComponent([this.granted = true]);
}

class RefreshNotesComponent extends UniqueComponent {}

class FeatureEntityComponent extends UniqueComponent {}

class HasDataComponent extends UniqueComponent {}

class PersistNoteComponent extends Component {}

class UpdateNoteComponent extends Component {}

class DeleteNoteComponent extends Component {}

class ThemeComponent extends UniqueComponent {}

class ColorComponent extends Component {
  final Color color;

  ColorComponent(this.color);
}

class AccentColorComponent extends Component {
  final Color accentColor;

  AccentColorComponent(this.accentColor);
}

class DarkModeComponent extends Component {
  final bool darkMode;

  DarkModeComponent([this.darkMode = true]);
}

class OpenMenuComponent extends UniqueComponent {
  final bool isOpen;

  OpenMenuComponent([this.isOpen = false]);
}

class MainTickComponent extends UniqueComponent {
  final int tick;

  MainTickComponent(this.tick);
}

class TickComponent extends Component {
  final int tick;

  TickComponent(this.tick);
}

class SearchBarComponent extends UniqueComponent {
  final bool isOpen;

  SearchBarComponent([this.isOpen = false]);
}

class KeyboardVisibleComponent extends UniqueComponent {
  final bool isVisible;

  KeyboardVisibleComponent(this.isVisible);
}

class FormDataComponent extends UniqueComponent {
  final String contents;
  final String tags;

  FormDataComponent({this.contents, this.tags});
}
