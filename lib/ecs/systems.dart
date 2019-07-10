import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';

class NavigationSystem extends TriggeredSystem {
  final GlobalKey<NavigatorState> _key;

  NavigationSystem(this._key);

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() {
    var routeName = entityManager.getUnique<NavigationSystemComponent>().routeName;
    var routeOp = entityManager.getUnique<NavigationSystemComponent>().routeOp;

    if (routeOp == NavigationOps.pop)
    _key.currentState.pop();
    else if (routeOp == NavigationOps.push)
    _key.currentState.pushNamed(routeName);
    else if (routeOp == NavigationOps.replace)
    _key.currentState.pushReplacementNamed(routeName);
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [NavigationSystemComponent]);
}

class LoadNotesSystem extends TriggeredSystem implements InitSystem {
  final NoteMatcher noteMatcher = NoteMatcher();

  @override
  init() {
    entityManager.setUnique(RefreshNotesComponent());
  }

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() async {
    var db = entityManager.getUnique<DatabaseComponent>().db;
    var snapshots = await db.getStore('notes').ref.query().getSnapshots(db);

    //Destroy currently loaded note entities to avoid duplicates.
    entityManager.groupMatching(NoteMatcher()).destroyAllEntities();

    for (var snapshot in snapshots) {
      var snapshotData = snapshot.value as Map<String, dynamic>;

      //Create a new Note entity using the loaded data.
      var noteEntity = entityManager.createEntity()
        ..set(ContentsComponent(snapshotData['contents']))
        ..set(TimestampComponent(snapshotData['timestamp']))
        ..set(DatabaseKeyComponent(snapshot.key))
        ..set(ShowMenuComponent(false));

      //Tags are optional so only include the component if there's any.
      if (snapshotData['tags'] != null)
        noteEntity.set(TagsComponent(snapshotData['tags']));

      if (snapshot['isList'] == true){
        List<Map<String, dynamic>> data = snapshot['listItems'].cast<Map<String, dynamic>>();
        noteEntity.set(IsListComponent(items: data.map((json) => ListItem.fromJson(json)).toList()));
      }
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [RefreshNotesComponent]);
}

class PersistNoteSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() {
    //Grab the note entity that was flagged for being persisted;
    var persistData = entityManager.getUnique<PersistNoteComponent>();
    var dbClient = entityManager.getUnique<DatabaseComponent>().db;

    try {
      Map<String, dynamic> data = {
        'contents': persistData.contents,
        'tags': persistData.tags,
        'timestamp': DateTime.now().toIso8601String()
      };
      if (persistData.items.isNotEmpty){
        data['isList'] = true;
        var listItems = <Map<String, dynamic>>[];
        for (var item in persistData.items)
          listItems.add(item.toJson());
        data['listItems'] = listItems;
      }
      dbClient.getStore('notes').put(data);
    } catch (e) {
      print(e);
    } finally {
      //Clear the flagged entity, refresh database and restore list mode.
      entityManager.setUnique(RefreshNotesComponent());
      entityManager.setUnique(NavigationSystemComponent(routeOp: NavigationOps.pop));
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [PersistNoteComponent]);
}

class UpdateNoteSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() {
    //Grab the entity flagged for update;
    var updateData = entityManager.getUnique<UpdateNoteComponent>();
    var dbClient = entityManager.getUnique<DatabaseComponent>().db;

    try {
      Map<String, dynamic> data = {
        'contents': updateData.contents,
        'tags': updateData.tags,
        'timestamp': DateTime.now().toIso8601String()
      };
      if (updateData.items.isNotEmpty){
        data['isList'] = true;
        var listItems = <Map<String, dynamic>>[];
        for (var item in updateData.items)
          listItems.add(item.toJson());
        data['listItems'] = listItems;
      }
      dbClient.getStore('notes').update(data, updateData.dbKey);
    } catch (e) {
      print(e);
    } finally {
      //Clear the flagged entity, refresh database and restore list mode.
      entityManager.setUnique(RefreshNotesComponent());
      entityManager.removeUnique<EditingNoteComponent>();
      entityManager.setUnique(NavigationSystemComponent(routeOp: NavigationOps.pop));
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [UpdateNoteComponent]);
}

class DeleteNoteSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() {
    //Grab the entity flagged for deletion.
    var dbKey = entityManager.getUnique<DeleteNoteComponent>().dbKey;
    var dbClient = entityManager.getUnique<DatabaseComponent>().db;

    try {
      dbClient
          .getStore('notes')
          .delete(dbKey);
    } catch (e) {
      print(e);
    } finally {
      //Clear the flagged entity, refresh database and restore list mode.
      entityManager.setUnique(RefreshNotesComponent());
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [DeleteNoteComponent]);
}