import 'dart:math';

import 'package:flutter/material.dart';
import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/pages/homepage.dart';
import 'package:sembast/sembast_io.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/systems.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  var mainEntityManager = EntityManager();

  var docPath = (await getExternalStorageDirectory()).path;
  var db = await databaseFactoryIo.openDatabase('$docPath/notes.db');
  mainEntityManager.setUnique(DatabaseComponent(db));
  mainEntityManager.setUnique(RandomGeneratorComponent(Random()));
  mainEntityManager.setUnique(ErrorComponent(null));

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: MyApp(),
    //Define all application systems in use here. 
    systems: RootSystem(mainEntityManager, [
      LoadNotesSystem(),
      PersistNoteSystem(),
      UpdateNoteSystem(),
      DeleteNoteSystem(),
    ]),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Notebulk',
        theme: ThemeData(
            primarySwatch: Colors.blue,
            typography: Typography(
              englishLike: Typography.englishLike2018,
              dense: Typography.dense2018,
              tall: Typography.tall2018,
            )),
        home: HomePage());
  }
}
