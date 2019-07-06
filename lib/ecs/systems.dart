import 'dart:async';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';

class LoadNotesSystem extends EntityManagerSystem
    implements InitSystem, ExitSystem {
  StreamSubscription notesSub;

  @override
  init() {
    //Only interested in Note entitys.
    final noteMatcher = NoteMatcher();
    //Fetch our database client.
    final db = entityManager.getUnique<DatabaseComponent>().db;

    notesSub =
        db.getStore('notes').ref.query().onSnapshots(db).listen((snapshots) {
      //Destroy currently loaded note entities to avoid duplicates.
      entityManager.groupMatching(noteMatcher).destroyAllEntities();

      for (var snapshot in snapshots) {
        var snapshotData = snapshot.value as Map<String, dynamic>;

        //Create a new Note entity using the loaded data.
        var noteEntity = entityManager.createEntity()
          ..set(ContentsComponent(snapshotData['contents']))
          ..set(TimestampComponent(snapshotData['timestamp']))
          ..set(DatabaseKeyComponent(snapshot.key));

        //Tags are optional so only include the component if there's any.
        if (snapshotData['tags'] != null)
          noteEntity.set(TagsComponent(snapshotData['tags']));
      }
    });
  }

  @override
  exit() {
    //It's safe to cancel the stream when exiting ie: application closing.
    notesSub.cancel();
  }
}

class PersistNoteSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  executeOnChange() {
    //Grab the note entity that was flagged for being persisted;
    var noteEntity = entityManager.getUniqueEntity<PersistNoteComponent>();
    var dbClient = entityManager.getUnique<DatabaseComponent>().db;

    try {
      dbClient.getStore('notes').put({
        'contents': noteEntity.get<ContentsComponent>().contents,
        'tags': noteEntity.get<TagsComponent>()?.tags,
        'timestamp': DateTime.now().toIso8601String()
      });
    } catch (e) {
      noteEntity.destroy();
      noteEntity = null;
    } finally {
      //Clear the flagged entity and restore list mode.
      entityManager.setUnique(ViewModeComponent(ViewMode.showNotes));
      entityManager.removeUnique<DisplayAsSingleComponent>();
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
    var noteEntity = entityManager.getUniqueEntity<UpdateNoteComponent>();
    var dbClient = entityManager.getUnique<DatabaseComponent>().db;

    try {
      dbClient.getStore('notes').update({
        'contents': noteEntity.get<ContentsComponent>().contents,
        'tags': noteEntity.get<TagsComponent>()?.tags,
        'timestamp': DateTime.now().toIso8601String()
      }, noteEntity.get<DatabaseKeyComponent>().dbKey);
    } catch (e) {
      print(e);
    } finally {
      //Clear the flagged entity and restore list mode.
      entityManager.setUnique(ViewModeComponent(ViewMode.showNotes));
      entityManager.removeUnique<DisplayAsSingleComponent>();
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
    var noteEntity = entityManager.getUniqueEntity<DeleteNoteComponent>();
    var dbClient = entityManager.getUnique<DatabaseComponent>().db;

    try {
      dbClient
          .getStore('notes')
          .delete(noteEntity.get<DatabaseKeyComponent>().dbKey);
    } catch (e) {
      print(e);
    }
  }

  @override
  EntityMatcher get matcher => EntityMatcher(all: [DeleteNoteComponent]);
}
