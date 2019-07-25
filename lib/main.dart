import 'dart:math';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/systems.dart';
import 'package:notebulk/pages/homepage.dart';
import 'package:notebulk/pages/noteFormFeature.dart';
import 'package:notebulk/pages/storageErrorPage.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:tinycolor/tinycolor.dart';

void main() async {
  var mainEntityManager = EntityManager();

  mainEntityManager.setUnique(ThemeComponent())
    ..set(ColorComponent(Colors.purple))
    ..set(AccentColorComponent(TinyColor(Colors.purple).brighten().color))
    ..set(DarkModeComponent(true));

  mainEntityManager.setUnique(CurrentPageComponent(0));
  mainEntityManager.setUnique(OpenMenuComponent(false));
  mainEntityManager.setUnique(StoragePermissionComponent(false));
  mainEntityManager.setUnique(SearchBarComponent(false));
  mainEntityManager.setUnique(KeyboardVisibleComponent(false));

  var navigatorKey = GlobalKey<NavigatorState>();

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: EntityObservingWidget(
      provider: (em) => em.getUniqueEntity<ThemeComponent>(),
      builder: (themeEntity, context) {
        return GradientBackground(
          darkMode: themeEntity.get<DarkModeComponent>().darkMode,
          themeColor: themeEntity.get<ColorComponent>().color,
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
                  pageWidget = EntityManagerProvider.feature(
                    child: NoteFormFeature(
                      title: "Criar nota",
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, _) {
                        em.setUnique(FeatureEntityComponent());
                      },
                      onDestroy: (em, root) {
                        var hasData = em.getUnique<HasDataComponent>();
                        var note = em.getUniqueEntity<FeatureEntityComponent>();

                        if (hasData != null)
                          root.createEntity()
                            ..set(note.get<ContentsComponent>())
                            ..set(note.get<TagsComponent>())
                            ..set(note.get<ListComponent>())
                            ..set(note.get<PictureComponent>())
                            ..set(PersistNoteComponent())
                            ..set(note.get<ArchivedComponent>());
                      },
                    ),
                  );
                  break;
                case Routes.editNote:
                  pageWidget = EntityManagerProvider.feature(
                    child: NoteFormFeature(
                      title: "Editar nota",
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        var editNote =
                            root.getUniqueEntity<FeatureEntityComponent>();

                        em.setUnique(FeatureEntityComponent())
                          ..set(editNote.get<ContentsComponent>())
                          ..set(editNote.get<TagsComponent>())
                          ..set(editNote.get<ListComponent>())
                          ..set(editNote.get<DatabaseKeyComponent>())
                          ..set(editNote.get<PictureComponent>())
                          ..set(editNote.get<ArchivedComponent>());

                        root.removeUnique<FeatureEntityComponent>();
                      },
                      onDestroy: (em, root) {
                        var hasData = em.getUnique<HasDataComponent>();
                        var note = em.getUniqueEntity<FeatureEntityComponent>();

                        if (hasData != null)
                          root.createEntity()
                            ..set(note.get<ContentsComponent>())
                            ..set(note.get<TagsComponent>())
                            ..set(note.get<ListComponent>())
                            ..set(note.get<DatabaseKeyComponent>())
                            ..set(note.get<PictureComponent>())
                            ..set(UpdateNoteComponent());
                      },
                    ),
                  );
                  break;
                case Routes.errorPage:
                  pageWidget = StorageErrorPage(
                    entityManager: mainEntityManager,
                  );
                  break;
                default:
                  pageWidget = Container();
              }
              return FadeRoute(page: pageWidget);
            },
            theme: ThemeData(
                brightness: themeEntity.get<DarkModeComponent>().darkMode
                    ? Brightness.dark
                    : Brightness.light,
                primaryColor: themeEntity.get<ColorComponent>().color,
                accentColor:
                    themeEntity.get<AccentColorComponent>().accentColor,
                toggleableActiveColor:
                    themeEntity.get<AccentColorComponent>().accentColor,
                textSelectionColor:
                    themeEntity.get<AccentColorComponent>().accentColor,
                textSelectionHandleColor:
                    themeEntity.get<AccentColorComponent>().accentColor,
                appBarTheme: AppBarTheme.of(context).copyWith(
                    color: themeEntity.get<DarkModeComponent>().darkMode
                        ? Colors.black
                        : Colors.white,
                    elevation: 0,
                    iconTheme: IconThemeData(
                        color: themeEntity.get<DarkModeComponent>().darkMode
                            ? Colors.white
                            : Colors.black),
                    actionsIconTheme: IconThemeData(
                        color: themeEntity.get<DarkModeComponent>().darkMode
                            ? Colors.white
                            : Colors.black)),
                canvasColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                scaffoldBackgroundColor: Colors.transparent,
                typography: Typography(
                  englishLike: Typography.englishLike2018,
                  dense: Typography.dense2018,
                  tall: Typography.tall2018,
                )),
          ),
        );
      },
    ),
    //Define all application systems in use here.
    system: RootSystem(entityManager: mainEntityManager, systems: [
      //TickSystem(),
      NavigationSystem(navigatorKey),
      LoadNotesSystem(),
      PersistNoteSystem(),
      UpdateNoteSystem(),
      DeleteNoteSystem(),
      ArchiveNoteSystem(),
      RestoreNoteSystem()
    ]),
  ));
}

class LogSystem
    implements InitSystem, ExecuteSystem, CleanupSystem, ExitSystem {
  int ticks;
  int cleaned;

  @override
  cleanup() {
    cleaned++;
  }

  @override
  execute() {
    ticks++;
  }

  @override
  exit() {
    print('executed: $ticks times, cleaned: $cleaned');
    print('end');
  }

  @override
  init() {
    ticks = 0;
    cleaned = 0;
    print('init');
  }
}

class MockNotesSystem extends EntityManagerSystem implements InitSystem {
  @override
  init() {
    var rnd = Random();

    for (int i = 0; i < 500; i++) {
      var e = entityManager.createEntity();

      e.set(TimestampComponent(DateTime.now()
          .add(Duration(days: rnd.nextInt(365)))
          .toIso8601String()));
      e.set(ContentsComponent('Nota#$i'));
      e.set(TagsComponent(['Mock', 'Test', 'DEV', 'Testing', 'ReallyBigOne']));

      if (rnd.nextBool()) e.set(ArchivedComponent());
    }
  }
}
