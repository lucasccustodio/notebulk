import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:kt_dart/kt.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';

// Compact a Hive box if the deletedEntries is above a threshold of 50.
bool _compactIf(int entries, int deletedEntries) => deletedEntries > 50;

// Returns a valid path to store our files
Future<String> _getValidPath() async {
  /* 
  Uncomment if Desktop
  if (Platform.isFuchsia || Platform.isLinux)
    return './Files';
  else */
  return (await getExternalStorageDirectory()).path;
}

// Helper function to populate a Entity with note-related data
void _populateNote(EntityManager entityManager, Entity noteEntity,
    EntityGroup tagMap, Map<String, dynamic> snapshotData) {
  noteEntity
    ..set(Contents(snapshotData['contents']))
    ..set(Timestamp(snapshotData['timestamp']));

  final List<String> tagItems = List<String>.from(snapshotData['tags']);
  final noteTags =
      KtList<String>.from(tagItems ?? <String>[]).map((tag) => tag.trim());
  final tags = KtList<ObservableEntity>.from(tagMap.entities);

  noteEntity.set(Tags(noteTags.asList()));

  /// Tags must be unique, so check before creating one to avoid duplicates
  for (var noteTag in noteTags.iter) {
    if (tags.none((e) => e.get<TagData>().value == noteTag))
      entityManager.createEntity().set(TagData(noteTag));
  }

  final List<Map<String, dynamic>> todoItems = List.from(snapshotData['todo'])
      .map((data) => Map<String, dynamic>.from(data))
      .toList();
  final todo = List<Map<String, dynamic>>.from(todoItems)
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  noteEntity
      .set(Todo(value: todo.map((json) => ListItem.fromJson(json)).toList()));

  if (snapshotData['picFile'] != null)
    noteEntity.set(Picture(snapshotData['picFile']));

  if (snapshotData['archived'] == true) {
    noteEntity.set(Archived());
  }
}

// Helper function to populate a Entity with reminder-related data
void _populateReminder(EntityManager entityManager, Entity reminderEntity,
    Map<String, dynamic> snapshotData) {
  reminderEntity
    ..set(Contents(snapshotData['contents']))
    ..set(Timestamp(snapshotData['timestamp']))
    ..set(Priority(ReminderPriority.values[snapshotData['priority']]))
    ..set(snapshotData['completed'] == true ? Toggle() : null);
}

// Manages database backup and restoration
class BackupSystem extends TriggeredSystem {
  // TODO: Allow user to define a path instead.
  static const backupPath = '/storage/emulated/0/backup.json';

  // Only react when the event component is added
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  // Match both variantes of the backup events
  @override
  EntityMatcher get matcher =>
      EntityMatcher(any: [ImportBackupEvent, ExportBackupEvent]);

  @override
  void executeOnChange() async {
    // Since the system reacts to both variants we need to branch correctly
    if (entityManager.getUnique<ImportBackupEvent>() != null)
      importBackup();
    else if (entityManager.getUnique<ExportBackupEvent>() != null)
      exportBackup();

    // Important due to the fact the system only reacts to when the event components are added
    entityManager
      ..removeUnique<ImportBackupEvent>()
      ..removeUnique<ExportBackupEvent>();
  }

  void exportBackup() {
    // Where to export to
    final jsonFile = File(backupPath);
    // Export all notes, including archived ones
    final noteGroup =
        entityManager.groupMatching(Matchers.note.copyWith(none: [Priority]));
    final reminderGroup = entityManager.groupMatching(Matchers.reminder);

    try {
      final notes = noteGroup.entities;
      final reminders = reminderGroup.entities;
      final settings = entityManager.getUniqueEntity<AppSettingsTag>();
      final map = <String, dynamic>{};

      // Populate array of notes
      map['notes'] = notes
          .map((e) => {
                'contents': e.get<Contents>().value,
                'timestamp': e.get<Timestamp>().value.toIso8601String(),
                'tags': e.get<Tags>()?.value?.toList() ?? [],
                'todo': e
                        .get<Todo>()
                        ?.value
                        ?.map((item) => item.toJson())
                        ?.toList() ??
                    [],
                'archived': e.hasT<Archived>(),
                'picFile': e.get<Picture>()?.value?.path
              })
          .toList();

      // Populate array of reminders
      map['reminders'] = reminders
          .map((e) => {
                'contents': e.get<Contents>().value,
                'timestamp': e.get<Timestamp>().value.toIso8601String(),
                'priority': e.get<Priority>()?.value?.index ?? 0,
                'completed': e.hasT<Toggle>()
              })
          .toList();

      // Save settings, for now only dark mode is available
      map['settings'] = {
        'darkTheme':
            settings.get<AppTheme>().value.brightness == Brightness.dark,
      };

      jsonFile.writeAsStringSync(jsonEncode(map));
    } on FileSystemException catch (e) {
      print(e);
    } finally {
      final localization =
          entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

      // Display the status bar informing the user that exportation is done
      entityManager.getUniqueEntity<StatusBarTag>()
        ..set(Contents(localization.exportedAlert))
        ..set(WaitForUser())
        ..set(Toggle());
    }
  }

  void importBackup() {
    final backupFile = File(backupPath);

    if (backupFile.existsSync()) {
      try {
        // Retrieve the JSON data map
        final Map<String, dynamic> map =
            jsonDecode(backupFile.readAsStringSync() ?? '{}');
        final snapshotData = Map<String, dynamic>.from(map);
        final tagMap = entityManager.groupMatching(Matchers.tag);
        final darkTheme = snapshotData['settings']['darkTheme'] ?? false;

        // Set the theme accordingly
        entityManager
            .getUniqueEntity<AppSettingsTag>()
            .set(AppTheme(darkTheme ? DarkTheme() : LightTheme()));

        // Loop through notes array and create note entities
        // TODO: Should duplicates be handled somehow?
        for (final noteData in snapshotData['notes']) {
          final noteEntity = entityManager.createEntity();

          _populateNote(entityManager, noteEntity, tagMap,
              Map<String, dynamic>.from(noteData));
        }

        // Same for the reminders
        for (final reminderData in snapshotData['reminders']) {
          final reminderEntity = entityManager.createEntity();

          _populateReminder(entityManager, reminderEntity,
              Map<String, dynamic>.from(reminderData));
        }
      } on FileSystemException catch (e) {
        print(e);
      } finally {
        // Matches only imported notes due their lack of DatabaseKey, inserted after persistance and during database refresh.
        final noteGroup = entityManager.groupMatching(Matchers.note
            .copyWith(all: [Contents, Timestamp], none: [DatabaseKey]));
        // Same for reminders
        final reminderGroup = entityManager.groupMatching(Matchers.note
            .copyWith(
                all: [Contents, Timestamp, Priority], none: [DatabaseKey]));

        // This triggers the persistance systems and subsequently database refresh
        for (final e in [...noteGroup.entities, ...reminderGroup.entities])
          e.set(PersistMe());

        // Also persist theme settings
        entityManager.setUnique(PersistUserSettingsEvent());

        final localization =
            entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

        // Inform the user that new data was imported
        entityManager.getUniqueEntity<StatusBarTag>()
          ..set(Contents(localization.importedAlert))
          ..set(WaitForUser())
          ..set(Toggle());
      }
    }
  }
}

// Manages loading, creating and updating notes/reminders
class DatabaseSystem extends TriggeredSystem implements InitSystem, ExitSystem {
  EntityGroup tagMap, noteMap, reminderMap;
  StreamSubscription reminderListener, noteListener;

  // React only to when event components are added
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  // Match both variants
  @override
  EntityMatcher get matcher =>
      EntityMatcher(any: [SetupDatabaseEvent, RefreshDatabaseEvent]);

  void askPermission() async {
    final status =
        await Permission.getPermissionsStatus([PermissionName.Storage]);

    if (status.first.permissionStatus == PermissionStatus.deny ||
        status.first.permissionStatus == PermissionStatus.notDecided ||
        status.first.permissionStatus == PermissionStatus.notAgain) {
      final status =
          (await Permission.requestPermissions([PermissionName.Storage]))
              .first
              .permissionStatus;

      if (status != PermissionStatus.allow) return;
    }

    entityManager
      ..setUnique(StoragePermission())
      ..setUnique(SetupDatabaseEvent());
  }

  @override
  void executeOnChange() {
    // Dont't do anything if the user didn't give permission
    if (entityManager.getUnique<StoragePermission>() == null) {
      return askPermission();
    } else if (entityManager.getUnique<SetupDatabaseEvent>() != null) {
      return setupDatabase();
    }

    refreshNotes();
    refreshReminders();

    // Important to avoid reacting needlessly to events
    entityManager.removeUnique<RefreshDatabaseEvent>();
  }

  @override
  void init() {
    // These allow the system to avoid creating duplicates
    tagMap = entityManager.groupMatching(Matchers.tag);
    noteMap = entityManager.groupMatching(Matchers.note);
    reminderMap = entityManager.groupMatching(Matchers.reminder);

    // Initialize the database when the system is created
    entityManager.setUnique(SetupDatabaseEvent());
  }

  // React to changes on the note box
  void refreshNotes() async {
    // This gets called during the lifetime of system, so avoid opening the box needlessly
    final noteStore = !Hive.isBoxOpen('notes')
        ? await Hive.openBox('notes', compactionStrategy: _compactIf)
        : Hive.box('notes');
    final snapshot = noteStore.toMap();

    for (final snapshot in snapshot.entries) {
      final snapshotData = Map<String, dynamic>.from(snapshot.value);
      final noteEntity = entityManager.createEntity()
        ..set(DatabaseKey(snapshot.key));

      _populateNote(entityManager, noteEntity, tagMap, snapshotData);
    }

    // Avoid listening to changes twice
    await noteListener?.cancel();
    noteListener = noteStore.watch().listen(updateNotes);
  }

  // Same for reminders
  void refreshReminders() async {
    final reminderStore = !Hive.isBoxOpen('reminders')
        ? await Hive.openBox('reminders', compactionStrategy: _compactIf)
        : Hive.box('reminders');
    final snapshots = reminderStore.toMap();

    for (final snapshot in snapshots.entries) {
      final snapshotData = Map<String, dynamic>.from(snapshot.value);
      final reminderEntity = entityManager.createEntity()
        ..set(DatabaseKey(snapshot.key));

      _populateReminder(entityManager, reminderEntity, snapshotData);
    }

    // Avoid listening to changes twice
    await reminderListener?.cancel();
    reminderListener = reminderStore.watch().listen(updateReminders);
  }

  // Check for permission, request if needed and set up the database
  void setupDatabase() async {
    final path = await _getValidPath();
    // Must be called before any Hive operations otherwise throws an exception
    Hive.init(path);

    // Also apply user settings
    entityManager
      ..removeUnique<SetupDatabaseEvent>()
      ..setUnique(RefreshDatabaseEvent())
      ..setUnique(LoadUserSettingsEvent());
  }

  void updateNotes(BoxEvent event) {
    // Is it modifying an existing note or creating a new one?
    final noteEntity = KtList.from(noteMap.entities)
            .singleOrNull((e) => e.get<DatabaseKey>().value == event.key) ??
        entityManager.createEntity()
      ..set(DatabaseKey(event.key));

    if (event.deleted) {
      noteEntity.destroy();
    } else {
      final snapshotData = Map<String, dynamic>.from(event.value);

      _populateNote(entityManager, noteEntity, tagMap, snapshotData);
    }
  }

  void updateReminders(BoxEvent event) {
    // Is it modifying an existing reminder or creating a new one?
    final reminderEntity = KtList.from(reminderMap.entities)
            .singleOrNull((e) => e.get<DatabaseKey>().value == event.key) ??
        entityManager.createEntity()
      ..set(DatabaseKey(event.key));

    if (event.deleted) {
      reminderEntity.destroy();
    } else {
      final snapshotData = Map<String, dynamic>.from(event.value);

      _populateReminder(entityManager, reminderEntity, snapshotData);
    }
  }

  // Exiting so cancel active listeners, if any
  @override
  void exit() {
    reminderListener?.cancel();
    noteListener?.cancel();
  }
}

// Handles deleting selected notes and reminders
class DiscardSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [DiscardSelectedEvent]);

  @override
  void executeOnChange() async {
    // Matches everything that is currently selected
    final selected = entityManager.group(any: [Selected]);

    // Nothing to do
    if (selected.isEmpty) {
      return;
    }

    for (var e in selected.entities) {
      final dbKey = e.get<DatabaseKey>().value;
      final priority = e.get<Priority>()?.value;
      // Notes can't have priority so use it's presence to branch
      final name = priority != null ? 'reminders' : 'notes';

      final store =
          !Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
      await store.deleteAll([dbKey]);

      // Delete this note's associated image, if any, to save disk space
      if (e.hasT<Picture>()) {
        final file = e.get<Picture>().value;

        try {
          file.deleteSync();
        } on FileSystemException catch (e) {
          print(e);
        }
      }
    }
  }
}

// Helper system to clear the selection when navigating, so the user doesn't delete/modify things previously selected and no longer visible
class InBetweenNavigationSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(any: [
        NavigationEvent,
        PageIndex,
        DiscardSelectedEvent,
        ArchiveNotesEvent,
        RestoreNotesEvent,
        RefreshDatabaseEvent
      ]);

  @override
  void executeOnChange() {
    // TODO: Should the search bar be cleared was well?
    //entityManager.getUniqueEntity<SearchBarTag>().set(SearchTerm(''));
    final selectedNotes = entityManager.group(all: [Selected]);

    for (var note in selectedNotes.entities) {
      note.remove<Selected>();
    }
  }
}

// Handles navigation by delegating to a Navigator instance but allows other system to the react to navigation changes, see [InBetweenNavigationSystem]
class NavigationSystem extends TriggeredSystem {
  final GlobalKey<NavigatorState> _key;

  NavigationSystem(this._key);

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [NavigationEvent]);

  @override
  void executeOnChange() {
    final routeName = entityManager.getUnique<NavigationEvent>().routeName;
    final routeOp = entityManager.getUnique<NavigationEvent>().routeOp;

    switch (routeOp) {
      case NavigationOps.pop:
        _key.currentState.pop();
        break;
      case NavigationOps.push:
        _key.currentState.pushNamed(routeName);
        break;
      case NavigationOps.replace:
        _key.currentState.pushReplacementNamed(routeName);
        break;
      default:
    }
  }
}

// Handles modification on notes like archiving and restoring
class NoteOperationsSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher =>
      EntityMatcher(any: [ArchiveNotesEvent, RestoreNotesEvent]);

  @override
  void executeOnChange() async {
    // Match only selected notes
    final selectedNotes = entityManager.groupMatching(
        Matchers.note.extend(all: [Selected]).copyWith(none: [Priority]));

    // Nothing to do
    if (selectedNotes.isEmpty) {
      return;
    }

    for (var note in selectedNotes.entities) {
      // Branch depending on the event
      if (entityManager.getUnique<ArchiveNotesEvent>() != null)
        note.set(Archived());
      else if (entityManager.getUnique<RestoreNotesEvent>() != null)
        note.remove<Archived>();

      // Apply changes and persist
      note
        ..set(PersistMe(note.get<DatabaseKey>().value))
        ..remove<Selected>();
    }

    entityManager
      ..removeUnique<ArchiveNotesEvent>()
      ..removeUnique<RestoreNotesEvent>();
  }
}

// Handles persisting notes and reminders.
class PersistanceSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [PersistMe]);

  // Here entities will contain all notes and reminders that got a PersistMe component this frame, which is ideal for operations in batch and in this case will avoid refreshing the database more than once.
  @override
  void executeWith(List<ObservableEntity> entities) async {
    for (var e in entities) {
      final contents = e.get<Contents>()?.value;
      final tags = e.get<Tags>()?.value ?? [];
      final items = e.get<Todo>()?.value ?? [];
      // If present, update, otherwise add to database
      final dbKey = e.get<PersistMe>()?.key;
      final picFile = e.get<Picture>()?.value?.path;
      final date = e.get<Timestamp>()?.value ?? DateTime.now();
      final priority = e.get<Priority>()?.value;
      final archived = e.hasT<Archived>();
      final completed = e.hasT<Toggle>();

      if (priority != null) {
        final reminderStore = !Hive.isBoxOpen('reminders')
            ? await Hive.openBox('reminders', compactionStrategy: _compactIf)
            : Hive.box('reminders');

        final reminder = {
          'contents': contents,
          'timestamp': date.toIso8601String(),
          'priority': priority.index,
          'completed': completed
        };

        if (dbKey != null)
          await reminderStore.put(dbKey, reminder);
        else
          await reminderStore.add(reminder);
        continue;
      }

      final note = <String, dynamic>{
        'contents': contents,
        'timestamp': date.toIso8601String(),
      };

      note['archived'] = archived;

      note['tags'] = tags.toList();

      note['todo'] = items
          .where((item) => item.label.isNotEmpty)
          .map((item) => item.toJson())
          .toList();

      note['picFile'] = picFile;

      final noteStore = !Hive.isBoxOpen('notes')
          ? await Hive.openBox('notes', compactionStrategy: _compactIf)
          : Hive.box('notes');
      if (dbKey != null)
        await noteStore.put(dbKey, note);
      else
        await noteStore.add(note);
    }
  }
}

class ReminderOperationsSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [CompleteRemindersEvent]);

  @override
  void executeOnChange() async {
    // Match only selected reminders
    final selected =
        entityManager.groupMatching(Matchers.reminder.extend(all: [Selected]));

    // Nothing to do
    if (selected.isEmpty) {
      return;
    }

    for (var reminder in selected.entities) {
      // Apply changes and persist
      reminder
        ..set(Toggle())
        ..set(PersistMe(reminder.get<DatabaseKey>()?.value))
        ..remove<Selected>();
    }
  }
}

// Handles searching for tags
class SearchSystem extends EntityManagerSystem implements ExecuteSystem {
  @override
  void execute() {
    final searchEntity = entityManager.getUniqueEntity<SearchBarTag>();
    final searchTerm = searchEntity.get<SearchTerm>()?.value;
    // Only notes can have tags so don't match anything else
    final notes = entityManager.groupMatching(Matchers.note);

    // Remove previous search results
    for (var note in notes.entities) {
      note.remove<SearchResult>();
    }

    // Nothing to do
    if (searchTerm == null || searchTerm.isEmpty || searchTerm.length < 2) {
      return;
    }

    final mainTick =
        entityManager.getUniqueEntity<MainTickTag>().get<Tick>().value;
    final searchTick = searchEntity.get<Tick>()?.value ?? 0;

    // Delays the searching to avoid incomplete terms
    if (searchTick + 5 > mainTick) {
      return;
    }

    for (var note in notes.entities) {
      // Nothing to do
      if (!note.hasT<Tags>()) {
        continue;
      }

      final tags = note.get<Tags>().value;

      // Allows searching for multiple terms at a time
      for (var tag in tags) {
        for (final term in searchTerm.split(' '))
          if (RegExp('\^$term', caseSensitive: false).hasMatch(tag)) {
            note.set(SearchResult());
          }
      }
    }

    // Remove the tick so the search ends
    searchEntity.remove<Tick>();
  }
}

// Hide or show status bar if there's anything selected
class StatusBarSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.any;

  @override
  EntityMatcher get matcher => EntityMatcher(any: [Selected]);

  @override
  void executeOnChange() {
    // Apply to both notes and reminders
    final selected = entityManager.group(any: [Selected]).entities;
    final label = entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>()
        .selectedLabel;

    if (selected.isNotEmpty) {
      entityManager.getUniqueEntity<StatusBarTag>().set(Contents('$label'));
      entityManager.getUniqueEntity<StatusBarTag>().set(Toggle());
    } else {
      entityManager.getUniqueEntity<StatusBarTag>()
        ..remove<Contents>()
        ..remove<Toggle>();
    }
  }
}

// Updates a counter every frame, mainly used to have realtime capabilities on the app
class TickSystem extends EntityManagerSystem
    implements InitSystem, ExecuteSystem {
  @override
  void execute() {
    entityManager
        .getUniqueEntity<MainTickTag>()
        .update<Tick>((old) => Tick(old.value + 1));
  }

  @override
  void init() {
    entityManager.setUnique(MainTickTag()).set(Tick(0));
  }
}

// Changes locale, applies and persists user settings
class UserSettingsSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher => EntityMatcher(any: [
        PersistUserSettingsEvent,
        LoadUserSettingsEvent,
        ChangeLocaleEvent
      ]);

  void changeLocale() {
    final localeCode = entityManager.getUnique<ChangeLocaleEvent>().localeCode;
    entityManager
      ..removeUnique<ChangeLocaleEvent>()
      ..getUniqueEntity<AppSettingsTag>()
          .set(localeCode == 'en' ? Localization.en() : Localization.ptBR());
  }

  @override
  void executeOnChange() {
    // Branch depending on event type
    if (entityManager.getUnique<PersistUserSettingsEvent>() != null) {
      return persistUserSettings();
    } else if (entityManager.getUnique<LoadUserSettingsEvent>() != null) {
      return loadUserSettings();
    } else if (entityManager.getUnique<ChangeLocaleEvent>() != null) {
      return changeLocale();
    }
  }

  void loadUserSettings() async {
    final settingsStore = !Hive.isBoxOpen('settings ')
        ? await Hive.openBox('settings',
            compactionStrategy: (_, deletedEntries) => deletedEntries > 5)
        : Hive.box('settings');
    final darkTheme = settingsStore.get('darkTheme') ?? false;

    entityManager
        .getUniqueEntity<AppSettingsTag>()
        .set(AppTheme(darkTheme ? DarkTheme() : LightTheme()));

    // Make the OS status bar color match theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: darkTheme ? BaseTheme.darkestGrey : Colors.white,
    ));

    // Mainly used on initialization to dismiss the splash screen
    // TODO: Split this responsability somewhere else
    entityManager
      ..removeUnique<LoadUserSettingsEvent>()
      ..setUnique(NavigationEvent.replace(Routes.mainScreen));
  }

  void persistUserSettings() async {
    final userSettings = entityManager.getUniqueEntity<AppSettingsTag>();

    final settingsStore = !Hive.isBoxOpen('settings ')
        ? await Hive.openBox('settings',
            compactionStrategy: (_, deletedEntries) => deletedEntries > 5)
        : Hive.box('settings');
    final darkTheme =
        userSettings.get<AppTheme>().value.brightness == Brightness.dark;

    await settingsStore.put('darkTheme', darkTheme);

    // Make the OS status bar color match theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: darkTheme ? BaseTheme.darkestGrey : Colors.white,
    ));

    entityManager.removeUnique<PersistUserSettingsEvent>();
  }
}
