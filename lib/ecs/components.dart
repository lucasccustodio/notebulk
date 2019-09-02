import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/theme.dart';

/*
  Naming conventions for unique components

  * = Ends with

  *Tag -> Identifier for unique components that represent some aspect of the app structure and helps with grouping relevant information.
  *Event -> Indentifier for event-like components, their modification triggers a system function and they rarely contain any data in them.
*/

// Note/reminder/tag components

// Text data present on notes and reminders
class Contents extends Component {
  final String value;

  Contents(this.value);
}

// Whether a note is currently archived
class Archived extends Component {}

// Holds information for the database use
class DatabaseKey extends Component {
  final int value;

  DatabaseKey(this.value);
}

// Note's Todo list
class Todo extends Component {
  final List<ListItem> value;

  Todo({this.value = const <ListItem>[]});
}

// Todo list item data
class ListItem {
  bool isChecked;

  String label;
  ListItem(this.label, {this.isChecked = false});
  ListItem.fromJson(Map<String, dynamic> map)
      : label = map['label'] ?? '',
        isChecked = map['isChecked'] ?? false;

  @override
  int get hashCode => label.hashCode ^ isChecked.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is ListItem && other.hashCode == hashCode;

  Map<String, dynamic> toJson() => {'label': label, 'isChecked': isChecked};

  @override
  String toString() => toJson().toString();
}

// Note's image
class Picture extends Component {
  final File value;

  Picture(String path) : value = File(path);
}

// Reminder's priority
class Priority extends Component {
  final ReminderPriority value;

  Priority(this.value);
}

enum ReminderPriority { none, low, medium, high, maximum }

// Tag's data
class TagData extends Component {
  final String value;

  TagData(this.value);
}

// Note's tag list
class Tags extends Component {
  final List<String> value;

  Tags(this.value);
}

// Note and reminder creation/edit date
class Timestamp extends Component {
  final DateTime value;

  Timestamp(String _timestamp) : value = DateTime.parse(_timestamp);
}

// Multipurpose components

// Used by forms to enable the save button
class Changed extends Component {}

// Allows operations on multiple notes and reminders simultaneously
class Selected extends Component {}

// Marks a reminder as completed and toggles visiblity of status bar
class Toggle extends Component {}

// Tags for unique entities
class AppSettingsTag extends UniqueComponent {}

class StatusBarTag extends UniqueComponent {}

class FeatureEntityTag extends UniqueComponent {}

class SearchBarTag extends UniqueComponent {}

class MainTickTag extends UniqueComponent {}

// System components

// Currently applied theme
class AppTheme extends Component {
  final BaseTheme value;

  AppTheme(this.value);
}

// Whether the user has given permission for the database to load/persist the app's data
class StoragePermission extends UniqueComponent {
  StoragePermission();
}

// Used to track how much time has passed since the user stopped typing in the search bar
class Tick extends Component {
  final int value;

  Tick(this.value);
}

// Makes the statusbar dismissible only be user interaction
class WaitForUser extends Component {}

// Marks a note or reminder to be persisted
class PersistMe extends Component {
  final int key;

  PersistMe([this.key]);
}

// Current visible page on main screen
class PageIndex extends UniqueComponent {
  final int value;

  final int oldValue;
  PageIndex(this.value, {this.oldValue});
}

// Latest search string input by the user
class SearchTerm extends Component {
  final String value;

  SearchTerm(this.value);
}

// Marks a note as being result of a search
class SearchResult extends Component {}

// Events

// Archive notes
class ArchiveNotesEvent extends UniqueComponent {}

// Locale changed so updated localization
class ChangeLocaleEvent extends UniqueComponent {
  final String localeCode;

  ChangeLocaleEvent(this.localeCode);
}

// Complete reminders
class CompleteRemindersEvent extends UniqueComponent {}

// Delete notes or reminders
class DiscardSelectedEvent extends UniqueComponent {}

// Export backup data to SD card
class ExportBackupEvent extends UniqueComponent {}

// Restore a previous backup
class ImportBackupEvent extends UniqueComponent {}

// Load user settings
class LoadUserSettingsEvent extends UniqueComponent {}

// Navigate somewhere
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

// Perform a search
class PerformSearchEvent extends UniqueComponent {}

// Persist current user settings
class PersistUserSettingsEvent extends UniqueComponent {}

// Refresh notes and reminders
class RefreshDatabaseEvent extends UniqueComponent {}

// Restore notes from archive
class RestoreNotesEvent extends UniqueComponent {}

// Set up the database
class SetupDatabaseEvent extends UniqueComponent {}
