import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/util.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:permission/permission.dart';

class TickSystem extends EntityManagerSystem
    implements InitSystem, ExecuteSystem {
  @override
  execute() {
    entityManager
        .getUniqueEntity<MainTickComponent>()
        .update<MainTickComponent>((old) => MainTickComponent(old.tick + 1));
  }

  @override
  init() {
    entityManager.setUnique(MainTickComponent(0));
  }
}

class NavigationSystem extends TriggeredSystem {
  final GlobalKey<NavigatorState> _key;

  NavigationSystem(this._key);

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() {
    var routeName =
        entityManager.getUnique<NavigationSystemComponent>().routeName;
    var routeOp = entityManager.getUnique<NavigationSystemComponent>().routeOp;

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
  EntityMatcher get matcher => EntityMatcher(all: [NavigationSystemComponent]);
}

class LoadNotesSystem extends TriggeredSystem implements InitSystem {
  @override
  init() async {
    var status =
        await Permission.getPermissionsStatus([PermissionName.Storage]);

    if (status.first.permissionStatus == PermissionStatus.deny ||
        status.first.permissionStatus == PermissionStatus.notAgain) {
      entityManager
          .setUnique(NavigationSystemComponent.replace(Routes.errorPage));
      return;
    }

    var docPath = (await path.getExternalStorageDirectory()).path;
    var db = await databaseFactoryIo.openDatabase('$docPath/notes.db');

    entityManager.setUnique(DatabaseComponent(db));
    entityManager.setUnique(RefreshNotesComponent());
  }

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() async {
    var dbClient = entityManager.getUnique<DatabaseComponent>()?.db;
    if (dbClient == null) return;

    var noteStore = intMapStoreFactory.store('notes');
    var snapshots = await noteStore.query().getSnapshots(dbClient);

    //Destroy currently loaded note entities to avoid duplicates.
    entityManager.groupMatching(Matchers.note).destroyAllEntities();
    entityManager.groupMatching(Matchers.archived).destroyAllEntities();

    for (var snapshot in snapshots) {
      var snapshotData = snapshot.value;

      //Create a new Note entity using the loaded data.
      var noteEntity = entityManager.createEntity()
        ..set(ContentsComponent(snapshotData['contents']))
        ..set(TimestampComponent(snapshotData['timestamp']))
        ..set(DatabaseKeyComponent(snapshot.key));

      //Tags are optional so only include the component if there's any.
      if (snapshotData['tags'] != null) {
        var tags = snapshotData['tags'] as String;
        noteEntity.set(TagsComponent(tags.split(",")));
      }

      if (snapshot['isList'] == true) {
        List<Map<String, dynamic>> data =
            snapshot['listItems'].cast<Map<String, dynamic>>();
        noteEntity.set(ListComponent(
            items: data.map((json) => ListItem.fromJson(json)).toList()));
      }

      if (snapshot['picFile'] != null)
        noteEntity.set(PictureComponent(snapshot['picFile']));

      if (snapshot['archived'] == true) noteEntity.set(ArchivedComponent());
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [RefreshNotesComponent]);
}

class PersistNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [PersistNoteComponent]);

  @override
  executeWith(List<Entity> entities) async {
    var dbClient = entityManager.getUnique<DatabaseComponent>()?.db;

    if (dbClient == null) return;

    for (var note in entities) {
      var contents = note.get<ContentsComponent>().contents;
      var tags = note.get<TagsComponent>()?.tags ?? [];
      var items = note.get<ListComponent>()?.items ?? [];
      var picFile = note.get<PictureComponent>()?.pic;

      Map<String, dynamic> data = {
        'contents': contents,
        'tags': tags.join(",").trim(),
        'timestamp': DateTime.now().toIso8601String()
      };
      if (items.isNotEmpty) {
        data['isList'] = true;
        var listItems = <Map<String, dynamic>>[];
        for (var item in items) listItems.add(item.toJson());
        data['listItems'] = listItems;
      }
      if (picFile != null) data['picFile'] = picFile.path;
      var noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.add(tx, data);
      }).catchError((e) => print(e));
    }
    entityManager.setUnique(RefreshNotesComponent());
  }
}

class UpdateNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeWith(List<Entity> entities) async {
    var dbClient = entityManager.getUnique<DatabaseComponent>()?.db;

    if (dbClient == null) return;

    for (var note in entities) {
      var contents = note.get<ContentsComponent>().contents;
      var tags = note.get<TagsComponent>()?.tags ?? [];
      var items = note.get<ListComponent>()?.items ?? [];
      var dbKey = note.get<DatabaseKeyComponent>().dbKey;
      var picFile = note.get<PictureComponent>()?.pic;

      Map<String, dynamic> data = {
        'contents': contents,
        'tags': tags.join(",").trim(),
        'timestamp': DateTime.now().toIso8601String()
      };
      if (items.isNotEmpty) {
        data['isList'] = true;
        var listItems = <Map<String, dynamic>>[];
        for (var item in items) listItems.add(item.toJson());
        data['listItems'] = listItems;
      }
      if (picFile != null) data['picFile'] = picFile.path;
      var noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).update(tx, data);
      }).catchError((e) => print(e));
    }
    entityManager.setUnique(RefreshNotesComponent());
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [UpdateNoteComponent]);
}

class DeleteNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [DeleteNoteComponent]);

  @override
  executeWith(List<Entity> entities) async {
    var dbClient = entityManager.getUnique<DatabaseComponent>()?.db;

    if (dbClient == null) return;

    for (var note in entities) {
      var dbKey = note.get<DatabaseKeyComponent>().dbKey;

      var noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).delete(tx);
      }).catchError((e) => print(e));
    }
    entityManager.setUnique(RefreshNotesComponent());
  }
}

class ArchiveNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [ArchivedComponent]);

  @override
  executeWith(List<Entity> entities) async {
    var dbClient = entityManager.getUnique<DatabaseComponent>()?.db;

    if (dbClient == null) return;

    for (var note in entities) {
      var dbKey = note.get<DatabaseKeyComponent>()?.dbKey;
      if (dbKey == null) continue;
      var noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).update(tx, {'archived': true});
      });
    }
  }
}

class RestoreNoteSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.removed;

  @override
  EntityMatcher get matcher => EntityMatcher(all: [ArchivedComponent]);

  @override
  executeWith(List<Entity> entities) async {
    var dbClient = entityManager.getUnique<DatabaseComponent>()?.db;

    if (dbClient == null) return;

    for (var note in entities) {
      var dbKey = note.get<DatabaseKeyComponent>()?.dbKey;
      if (dbKey == null) continue;
      var noteStore = intMapStoreFactory.store('notes');
      await dbClient.transaction((tx) async {
        await noteStore.record(dbKey).update(tx, {'archived': false});
      });
    }
  }
}
