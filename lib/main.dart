import 'package:flutter/material.dart';
import 'package:entitas_ff/entitas_ff.dart';
import 'package:notebulk/pages/createListPage.dart';
import 'package:notebulk/pages/createNotePage.dart';
import 'package:notebulk/pages/editListPage.dart';
import 'package:notebulk/pages/editNotePage.dart';
import 'package:notebulk/pages/homepage.dart';
import 'package:notebulk/util.dart';
import 'package:sembast/sembast_io.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/systems.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  var mainEntityManager = EntityManager();

  var docPath = (await getExternalStorageDirectory()).path;
  var db = await databaseFactoryIo.openDatabase('$docPath/notes.db');

  mainEntityManager.setUnique(DatabaseComponent(db));

  var navigatorKey = GlobalKey<NavigatorState>();

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: GradientBackground(
      child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Notebulk',
          initialRoute: Routes.showNotes,
          onGenerateRoute: (RouteSettings settings) {
            Widget pageWidget;

            switch (settings.name) {
              case Routes.showNotes:
                pageWidget = HomePage(
                  entityManager: mainEntityManager,
                );
                break;
              case Routes.createNote:
                pageWidget = CreateNotePage(entityManager: mainEntityManager);
                break;
              case Routes.editNote:
                pageWidget = EditNotePage(
                  entityManager: mainEntityManager,
                  noteEntity:
                      mainEntityManager.getUniqueEntity<EditingNoteComponent>(),
                );
                break;
              case Routes.createList:
                pageWidget = CreateListPage(entityManager: mainEntityManager);
                break;
              case Routes.editList:
                pageWidget = EditListPage(
                  entityManager: mainEntityManager,
                  noteEntity:
                      mainEntityManager.getUniqueEntity<EditingNoteComponent>(),
                );
                break;
              default:
                pageWidget = Container();
            }
            return FadeRoute(page: pageWidget);
          },
          theme: ThemeData(
              primarySwatch: Colors.purple,
              typography: Typography(
                englishLike: Typography.englishLike2018,
                dense: Typography.dense2018,
                tall: Typography.tall2018,
              ))),
    ),
    //Define all application systems in use here.
    systems: RootSystem(mainEntityManager, [
      NavigationSystem(navigatorKey),
      LoadNotesSystem(),
      PersistNoteSystem(),
      UpdateNoteSystem(),
      DeleteNoteSystem(),
    ]),
  ));
}

//Nice gradient background that helps stylize the app.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.2, 0.6, 1.0],
                colors: [Colors.black, Colors.purple, Colors.purple])),
        child: child);
  }
}

class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
}
