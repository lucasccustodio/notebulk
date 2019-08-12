import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

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

class NavigationSystem extends TriggeredSystem {
  NavigationSystem(this._key);

  final GlobalKey<NavigatorState> _key;

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

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

  @override
  EntityMatcher get matcher => EntityMatcher(all: [NavigationEvent]);
}

class SearchSystem extends EntityManagerSystem implements ExecuteSystem {
  @override
  void execute() {
    final searchEntity = entityManager.getUniqueEntity<SearchBarTag>();
    final term = searchEntity.get<SearchTerm>()?.value;

    if (term == null || term.isEmpty) {
      return;
    }

    final notes = entityManager.groupMatching(Matchers.note);

    for (var note in notes.entities) {
      note.remove<SearchResult>();
    }

    final mainTick =
        entityManager.getUniqueEntity<MainTickTag>().get<Tick>().value;
    final searchTick = searchEntity.get<Tick>()?.value ?? 0;

    if (searchTick + 20 > mainTick) {
      return;
    }

    for (var note in notes.entities) {
      if (!note.hasT<Tags>()) {
        continue;
      }

      final tags = note.get<Tags>().value;

      if (tags.contains(term))
        note.set(SearchResult());
      else {
        for (var tag in tags) {
          if (RegExp(term).hasMatch(tag)) {
            note.set(SearchResult());
          }
        }
      }
    }

    searchEntity.remove<Tick>();
  }
}

class DisplaySelectedSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.any;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [Selected]);

  @override
  void executeOnChange() {
    final selected = entityManager.group(all: [Selected]);
    final label = entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>()
        .selectedLabel;

    if (!selected.isEmpty) {
      entityManager
          .getUniqueEntity<DisplayStatusTag>()
          .set(Contents('${selected.entities.length} $label'));
      entityManager.getUniqueEntity<DisplayStatusTag>().set(Toggle());
    } else {
      entityManager.getUniqueEntity<DisplayStatusTag>()
        ..remove<Contents>()
        ..remove<Toggle>();
    }
  }
}

class ClearSelectedSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeOnChange() {
    final selectedNotes = entityManager.group(all: [Selected]);

    for (var note in selectedNotes.entities) {
      note.remove<Selected>();
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(any: [
        NavigationEvent,
        PageNavigationTag,
        DeleteNotesEvent,
        ArchiveNotesEvent,
        RestoreNotesEvent
      ]);
}

class LoadUserSettingsSystem extends TriggeredSystem {
  final Color _defaultThemeColor = Colors.purple;
  final bool _defaultDarkMode = true;

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeOnChange() async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;
    if (dbClient == null) {
      return;
    }

    final settingsStore = StoreRef.main();
    final themeColor = Color(
        await settingsStore.record('themeColor')?.get(dbClient) ??
            _defaultThemeColor.value);
    final darkMode = await settingsStore.record('darkMode').get(dbClient) ??
        _defaultDarkMode;

    entityManager.getUniqueEntity<AppSettingsTag>()
      ..set(ThemeColor(themeColor))
      ..set(DarkMode(value: darkMode));

    entityManager
        .getUniqueEntity<SplashScreenTag>()
        .update<Counter>((old) => Counter(old.value + 25));
    entityManager.setUnique(RefreshNotesEvent());
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [LoadUserSettingsEvent]);
}

class PersistUserSettingsSystem extends TriggeredSystem implements ExitSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.updated;

  @override
  void executeOnChange() {
    persistUserSettings();
  }

  @override
  void exit() {
    persistUserSettings();
  }

  void persistUserSettings() {
    final userSettings = entityManager.getUniqueEntity<AppSettingsTag>();

    if (userSettings == null) {
      return;
    }

    final dbClient = entityManager.getUnique<DatabaseService>()?.value;
    if (dbClient == null) {
      return;
    }

    final settingsStore = StoreRef.main();
    final themeColor = userSettings.get<ThemeColor>().value;
    final darkMode = userSettings.get<DarkMode>().value;

    settingsStore
        .record('themeColor')
        .put(dbClient, themeColor.value, merge: true);
    settingsStore.record('darkMode').put(dbClient, darkMode, merge: true);
  }

  @override
  EntityMatcher get matcher => Matchers.settings.extend(any: [DatabaseService]);
}

class DatabaseSystem extends TriggeredSystem implements InitSystem {
  @override
  void init() => setupDatabase();

  void setupDatabase() async {
    final status =
        await Permission.getPermissionsStatus([PermissionName.Storage]);

    if (status.first.permissionStatus == PermissionStatus.deny ||
        status.first.permissionStatus == PermissionStatus.notDecided) {
      entityManager.setUnique(NavigationEvent.replace(Routes.errorPage));
      return;
    }

    final path = (await getExternalStorageDirectory()).path;
    final db = await databaseFactoryIo.openDatabase('$path/notes.db');

    entityManager.setUnique(DatabaseService(db));
    entityManager
        .getUniqueEntity<SplashScreenTag>()
        .update<Counter>((old) => Counter(old.value + 25));
    entityManager.setUnique(LoadUserSettingsEvent());
  }

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeOnChange() => setupDatabase();

  @override
  EntityMatcher get matcher => EntityMatcher(all: [SetupDatabaseEvent]);
}

class ExportNotesSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeOnChange() async {
    final path = (await getExternalStorageDirectory()).path;
    final dbFile = File('$path/notes.db');
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    if (dbFile.existsSync()) {
      const newPath = '/storage/emulated/0/notesBkp.db';
      try {
        dbFile.copySync(newPath);
        entityManager.getUniqueEntity<DisplayStatusTag>()
          ..set(Contents(localization.exportMessage))
          ..set(Toggle());
      } on FileSystemException catch (e) {
        print(e);
      }
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [ExportNotesEvent]);
}

class ImportNotesSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeOnChange() async {
    const path = '/storage/emulated/0';
    const dbBkpPath = '$path/notesBkp.db';
    final bkpEntityManager = EntityManager();
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    if (File(dbBkpPath).existsSync()) {
      try {
        final dbBkp = await databaseFactoryIo.openDatabase(dbBkpPath);
        final bkpNoteStore = intMapStoreFactory.store('notes');

        final snapshots = await bkpNoteStore.query().getSnapshots(dbBkp);

        entityManager.getUniqueEntity<DisplayStatusTag>()
          ..set(Contents(localization.importingAlert))
          ..set(Toggle());

        for (var snapshot in snapshots
          ..sort((s1, s2) {
            final date1 = DateTime.parse(s1.value['timestamp']);
            final date2 = DateTime.parse(s2.value['timestamp']);

            return date1.compareTo(date2);
          })) {
          final snapshotData = snapshot.value;

          final noteEntity = bkpEntityManager.createEntity()
            ..set(Contents(snapshotData['contents']))
            ..set(Timestamp(snapshotData['timestamp']))
            ..set(DatabaseKey(snapshot.key));

          if (snapshotData['tags'] != null) {
            final tags = snapshotData['tags'].cast<String>();
            noteEntity.set(Tags(
                tags.where((tag) => tag is String && tag.isNotEmpty).toList()));
          }

          if (snapshot['isList'] == true) {
            final List<Map<String, dynamic>> data =
                snapshot['listItems'].cast<Map<String, dynamic>>();
            noteEntity.set(Todo(
                value: data.map((json) => ListItem.fromJson(json)).toList()));
          }

          if (snapshot['picFile'] != null) {
            if (File(snapshot['picFile']).existsSync())
              noteEntity.set(Picture(snapshot['picFile']));
          }

          if (snapshot['archived'] == true) {
            noteEntity.set(Archived());
          }
        }

        await dbBkp.close();
      } on FileSystemException catch (e) {
        print(e);
      } finally {
        for (final note in bkpEntityManager.entities) {
          entityManager.createEntity()
            ..set(note.get<Contents>())
            ..set(note.get<Timestamp>())
            ..set(note.get<Todo>())
            ..set(note.get<Tags>())
            ..set(note.get<Picture>())
            ..set(note.get<DatabaseKey>())
            ..set(PersistMe());
        }
      }
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [ImportNotesEvent]);
}

class LoadNotesSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeOnChange() async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;

    if (dbClient == null) {
      return;
    }

    final noteStore = intMapStoreFactory.store('notes');
    final snapshots = await noteStore.query().getSnapshots(dbClient);

    //Destroy currently loaded note entities to avoid duplicates.
    entityManager.groupMatching(Matchers.note).destroyAllEntities();
    entityManager.groupMatching(Matchers.archived).destroyAllEntities();

    final splashScreen = entityManager.getUniqueEntity<SplashScreenTag>();
    final endCount = snapshots.length;
    var count = 0;

    for (var snapshot in snapshots
      ..sort((s1, s2) {
        final date1 = DateTime.parse(s1.value['timestamp']);
        final date2 = DateTime.parse(s2.value['timestamp']);

        return date2.compareTo(date1);
      })) {
      final snapshotData = snapshot.value;

      //Create a new Note entity using the loaded data.
      final noteEntity = entityManager.createEntity()
        ..set(Contents(snapshotData['contents']))
        ..set(Timestamp(snapshotData['timestamp']))
        ..set(DatabaseKey(snapshot.key));

      final List<String> tags = snapshotData['tags'].cast<String>();

      if (tags.isNotEmpty) {
        noteEntity.set(Tags(tags.toList()));
      }

      final List<Map<String, dynamic>> todo =
          snapshot['todo']?.cast<Map<String, dynamic>>();

      if (todo.isNotEmpty) {
        noteEntity.set(
            Todo(value: todo.map((json) => ListItem.fromJson(json)).toList()));
      }

      if (snapshot['picFile'] != null)
        noteEntity.set(Picture(snapshot['picFile']));

      if (snapshot['archived'] == true) {
        noteEntity.set(Archived());
      }

      splashScreen.update<Counter>(
          (old) => Counter(old.value + ((++count / endCount) * 50).truncate()));
    }

    splashScreen.set(Counter(100));
    entityManager.setUnique(NavigationEvent.replace(Routes.showNotes));
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [RefreshNotesEvent]);
}

class PersistNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [PersistMe]);

  @override
  void executeWith(List<Entity> entities) async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;

    if (dbClient == null) {
      return;
    }

    for (var note in entities) {
      final contents = note.get<Contents>().value;
      final tags = note.get<Tags>()?.value ?? [];
      final items = note.get<Todo>()?.value ?? [];
      final picFile = note.get<Picture>()?.value;

      final data = {
        'contents': contents,
        'tags': tags.where((value) => value.isNotEmpty).toList(),
        'todo': items
            .where((item) => item.label.isNotEmpty)
            .map((item) => item.toJson())
            .toList(),
        'timestamp': DateTime.now().toIso8601String()
      };
      if (picFile != null) {
        data['picFile'] = picFile.path;
      }
      final noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.add(tx, data);
      }).catchError(print);
    }
    entityManager.setUnique(RefreshNotesEvent());
  }
}

class UpdateNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  void executeWith(List<Entity> entities) async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;

    if (dbClient == null) {
      return;
    }

    for (var note in entities) {
      final contents = note.get<Contents>().value;
      final tags = note.get<Tags>()?.value ?? [];
      final items = note.get<Todo>()?.value ?? [];
      final dbKey = note.get<DatabaseKey>().value;
      final picFile = note.get<Picture>()?.value;

      final data = {
        'contents': contents,
        'tags': tags.where((value) => value.isNotEmpty).toList(),
        'todo': items
            .where((item) => item.label.isNotEmpty)
            .map((item) => item.toJson())
            .toList(),
        'timestamp': DateTime.now().toIso8601String()
      };

      if (picFile != null) {
        data['picFile'] = picFile.path;
      }
      final noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).update(tx, data);
      }).catchError(print);
    }
    entityManager.setUnique(RefreshNotesEvent());
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [UpdateMe]);
}

class DeleteNotesSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [DeleteNotesEvent]);

  @override
  void executeOnChange() async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;

    if (dbClient == null) {
      return;
    }

    final selectedNotes = entityManager.group(all: [Selected]);

    if (selectedNotes.isEmpty) {
      return;
    }

    for (var note in selectedNotes.entities) {
      final dbKey = note.get<DatabaseKey>().value;

      final noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).delete(tx);
      }).catchError(print);

      if (note.hasT<Picture>()) {
        final file = note.get<Picture>().value;

        try {
          file.deleteSync();
        } on FileSystemException catch (e) {
          print(e);
        }
      }
    }

    entityManager
      ..removeUnique<DeleteNotesEvent>()
      ..setUnique(RefreshNotesEvent());
  }
}

class ArchiveNotesSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [ArchiveNotesEvent]);

  @override
  void executeOnChange() async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;

    if (dbClient == null) {
      return;
    }

    final selectedNotes = entityManager.group(all: [Selected]);

    if (selectedNotes.isEmpty) {
      return;
    }

    for (var note in selectedNotes.entities) {
      final dbKey = note.get<DatabaseKey>()?.value;
      if (dbKey == null) {
        continue;
      }
      final noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).update(tx, {'archived': true});
      });
    }

    entityManager
      ..removeUnique<ArchiveNotesEvent>()
      ..setUnique(RefreshNotesEvent());
  }
}

class RestoreNotesSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [RestoreNotesEvent]);

  @override
  void executeOnChange() async {
    final dbClient = entityManager.getUnique<DatabaseService>()?.value;

    if (dbClient == null) {
      return;
    }

    final selectedNotes = entityManager.group(all: [Selected]);

    if (selectedNotes.isEmpty) {
      return;
    }

    for (var note in selectedNotes.entities) {
      final dbKey = note.get<DatabaseKey>()?.value;
      if (dbKey == null) {
        continue;
      }
      final noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).update(tx, {'archived': false});
      });
    }

    entityManager
      ..removeUnique<RestoreNotesEvent>()
      ..setUnique(RefreshNotesEvent());
  }
}
