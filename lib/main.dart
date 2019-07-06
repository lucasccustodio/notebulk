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
  mainEntityManager.setUnique(ViewModeComponent(ViewMode.showNotes));

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: MaterialApp(
        title: 'Notebulk',
        theme: ThemeData(
            primarySwatch: Colors.blue,
            typography: Typography(
              englishLike: Typography.englishLike2018,
              dense: Typography.dense2018,
              tall: Typography.tall2018,
            )),
        home: MyApp()),
    //Define all application systems in use here.
    systems: RootSystem(mainEntityManager, [
      LoadNotesSystem(),
      PersistNoteSystem(),
      UpdateNoteSystem(),
      DeleteNoteSystem(),
    ]),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: HomePage(),
      onWillPop: () async {
        var em = EntityManagerProvider.of(context).entityManager;
        var viewModeEntity = em.getUniqueEntity<ViewModeComponent>();
        var viewMode = viewModeEntity.get<ViewModeComponent>().viewMode;

        if (viewMode != ViewMode.showNotes) {
          if (viewMode == ViewMode.createNote)
            em.getUniqueEntity<DisplayAsSingleComponent>().destroy();

          em.setUnique(ViewModeComponent(ViewMode.showNotes));
          return true;
        }

        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Deseja sair?'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text("Não"),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    FlatButton(
                      child: Text("Sim"),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ));
      },
    );
  }
}
