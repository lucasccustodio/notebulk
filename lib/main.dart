import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/systems.dart';
import 'package:notebulk/mainApp.dart';
import 'package:notebulk/features/noteFormFeature.dart';
import 'package:notebulk/pages/splashScreenPage.dart';
import 'package:notebulk/pages/storageErrorPage.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:tinycolor/tinycolor.dart';

void main() async {
  final mainEntityManager = EntityManager();

  mainEntityManager.setUnique(SplashScreenTag()).set(Counter(0));
  mainEntityManager.setUnique(UserSettingsTag())
    ..set(ThemeColor(Colors.black))
    ..set(DarkMode(value: true));
  mainEntityManager
    ..setUnique(PageIndex(0))
    ..setUnique(DisplayStatusTag())
    ..setUnique(FABTag())
    ..setUnique(StoragePermission(value: false))
    ..setUnique(SearchBarTag());

  final navigatorKey = GlobalKey<NavigatorState>();

  debugPaintSizeEnabled = false;

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: EntityObservingWidget(
      provider: (em) => em.getUniqueEntity<UserSettingsTag>(),
      builder: (themeEntity, context) {
        final darkMode = themeEntity.get<DarkMode>().value;
        final primaryColor = themeEntity.get<ThemeColor>().value;
        final accentColor = darkMode
            ? TinyColor(primaryColor).brighten().color
            : TinyColor(primaryColor).darken().color;

        return GradientBackground(
          darkMode: darkMode,
          themeColor: accentColor,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Notebulk',
            initialRoute: Routes.splashScreen,
            onGenerateRoute: (settings) {
              Widget pageWidget;

              switch (settings.name) {
                case Routes.splashScreen:
                  pageWidget = SplashScreenPage();
                  break;
                case Routes.showNotes:
                  pageWidget = MainApp(
                    entityManager: mainEntityManager,
                  );
                  break;
                case Routes.createNote:
                  pageWidget = EntityManagerProvider.feature(
                    child: NoteFormFeature(
                      title: 'Criar nota',
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, _) {
                        em.setUnique(FeatureEntityTag());
                      },
                      onDestroy: (em, root) {
                        final hasData = em.getUnique<HasDataTag>();
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        if (hasData != null)
                          root.createEntity()
                            ..set(note.get<Contents>())
                            ..set(note.get<Tags>())
                            ..set(note.get<Todo>())
                            ..set(note.get<Picture>())
                            ..set(PersistMe());
                      },
                    ),
                  );
                  break;
                case Routes.editNote:
                  pageWidget = EntityManagerProvider.feature(
                    child: NoteFormFeature(
                      title: 'Editar nota',
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        final editNote =
                            root.getUniqueEntity<FeatureEntityTag>();

                        em.setUnique(FeatureEntityTag())
                          ..set(editNote.get<Contents>())
                          ..set(editNote.get<Tags>())
                          ..set(editNote.get<Todo>())
                          ..set(editNote.get<DatabaseKey>())
                          ..set(editNote.get<Picture>());

                        root.removeUnique<FeatureEntityTag>();
                      },
                      onDestroy: (em, root) {
                        final hasData = em.getUnique<HasDataTag>();
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        if (hasData != null)
                          root.createEntity()
                            ..set(note.get<Contents>())
                            ..set(note.get<Tags>())
                            ..set(note.get<Todo>())
                            ..set(note.get<DatabaseKey>())
                            ..set(note.get<Picture>())
                            ..set(UpdateMe());
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
                fontFamily: 'Ubuntu',
                brightness: darkMode ? Brightness.dark : Brightness.light,
                primaryColor: primaryColor,
                accentColor: accentColor,
                toggleableActiveColor: accentColor,
                textSelectionColor: accentColor,
                textSelectionHandleColor: accentColor,
                appBarTheme: AppBarTheme.of(context)
                    .copyWith(color: Colors.transparent, elevation: 0),
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
      DatabaseSystem(),
      LoadUserSettingsSystem(),
      PersistUserSettingsSystem(),
      TickSystem(),
      LoadNotesSystem(),
      PersistNoteSystem(),
      UpdateNoteSystem(),
      DeleteNotesSystem(),
      ArchiveNotesSystem(),
      RestoreNotesSystem(),
      NavigationSystem(navigatorKey),
      DisplaySelectedSystem(),
      ClearSelectedSystem(),
      SearchSystem()
    ]),
  ));
}
