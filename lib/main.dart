import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:flutter/rendering.dart';
import 'package:notebulk/ecs/systems.dart';
import 'package:notebulk/mainApp.dart';
import 'package:notebulk/features/noteFormFeature.dart';
import 'package:notebulk/pages/splashScreenPage.dart';
import 'package:notebulk/pages/storageErrorPage.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:tinycolor/tinycolor.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/testFeature.dart';

void main() async {
  //debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  //debugPaintSizeEnabled = true;

  final mainEntityManager = EntityManager();

  mainEntityManager.setUnique(SplashScreenTag()).set(Counter(0));
  mainEntityManager.setUnique(AppSettingsTag())
    ..set(ThemeColor(Colors.black))
    ..set(DarkMode(value: true))
    ..set(Localization.en());
  mainEntityManager.setUnique(PageNavigationTag())
    ..set(CurrentIndex(0))
    ..set(NextIndex(1));
  mainEntityManager
    ..setUnique(DisplayStatusTag())
    ..setUnique(FABTag())
    ..setUnique(StoragePermission(value: false))
    ..setUnique(SearchBarTag());

  final navigatorKey = GlobalKey<NavigatorState>();

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: EntityObservingWidget(
      provider: (em) => em.getUniqueEntity<AppSettingsTag>(),
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
            debugShowCheckedModeBanner: false,
            debugShowMaterialGrid: false,
            navigatorKey: navigatorKey,
            title: 'Notebulk',
            initialRoute: Routes.splashScreen,
            supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
            localeResolutionCallback: (locale, _) {
              if (locale != null) {
                mainEntityManager.getUniqueEntity<AppSettingsTag>().set(
                    locale.languageCode == 'en'
                        ? Localization.en()
                        : Localization.ptBR());
              }
              return locale;
            },
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            onGenerateRoute: (settings) {
              Widget pageWidget;
              final localization = mainEntityManager
                  .getUniqueEntity<AppSettingsTag>()
                  .get<Localization>();

              switch (settings.name) {
                case Routes.splashScreen:
                  pageWidget = SplashScreenPage();
                  break;
                case Routes.showNotes:
                  pageWidget = MainApp(
                    entityManager: mainEntityManager,
                  );
                  break;
                case Routes.createList:
                case Routes.createNote:
                  pageWidget = EntityManagerProvider.feature(
                    child: NoteFormFeature(
                      title: localization.createNoteFeatureTitle,
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        em.setUnique(FeatureEntityTag());
                        em.setUnique(AppSettingsTag()).set(root
                            .getUniqueEntity<AppSettingsTag>()
                            .get<Localization>());
                      },
                      onDestroy: (em, root) {
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        if (note.hasT<PersistMe>())
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
                      title: localization.editNoteFeatureTitle,
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        final editNote =
                            root.getUniqueEntity<FeatureEntityTag>();

                        em.setUnique(AppSettingsTag()).set(root
                            .getUniqueEntity<AppSettingsTag>()
                            .get<Localization>());

                        em.setUnique(FeatureEntityTag())
                          ..set(editNote.get<Contents>())
                          ..set(editNote.get<Tags>())
                          ..set(editNote.get<Todo>())
                          ..set(editNote.get<DatabaseKey>())
                          ..set(editNote.get<Picture>());

                        root.removeUnique<FeatureEntityTag>();
                      },
                      onDestroy: (em, root) {
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        if (note.hasT<PersistMe>())
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
                case Routes.testPage:
                  pageWidget = EntityManagerProvider.feature(
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                    ),
                    child: TestFeature(),
                  );
                  break;
                default:
                  pageWidget = Container();
              }
              return FadeRoute(page: pageWidget);
            },
            theme: ThemeData(
                fontFamily: 'OpenSans',
                brightness: darkMode ? Brightness.dark : Brightness.light,
                primaryColor: primaryColor,
                accentColor: accentColor,
                toggleableActiveColor: accentColor,
                textSelectionColor: accentColor,
                textSelectionHandleColor: accentColor,
                appBarTheme: AppBarTheme.of(context).copyWith(
                    color: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconTheme.of(context).copyWith(
                        color: darkMode ? Colors.white : Colors.black)),
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
      ImportNotesSystem(),
      ExportNotesSystem(),
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
