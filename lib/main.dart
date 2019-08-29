import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/systems.dart';
import 'package:notebulk/features/noteFormFeature.dart';
import 'package:notebulk/mainApp.dart';
import 'package:notebulk/pages/splashScreenPage.dart';
import 'package:notebulk/pages/storageErrorPage.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';

import 'features/eventFormFeature.dart';

void main() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isFuchsia)
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  final mainEntityManager = EntityManager();

  mainEntityManager.setUnique(AppSettingsTag())
    ..set(Localization.en())
    ..set(AppTheme(BlankTheme()));
  mainEntityManager
    ..setUnique(DisplayStatusTag())
    ..setUnique(PageIndex(0, oldValue: 0))
    ..setUnique(SearchBarTag());

  final navigatorKey = GlobalKey<NavigatorState>();

  runApp(EntityManagerProvider(
    entityManager: mainEntityManager,
    child: EntityObservingWidget(
      provider: (em) => em.getUniqueEntity<AppSettingsTag>(),
      builder: (settings, context) {
        final appTheme = settings.get<AppTheme>().value;

        return GradientBackground(
          appTheme: appTheme,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            debugShowMaterialGrid: false,
            navigatorKey: navigatorKey,
            title: 'Notebulk',
            initialRoute: Routes.splashScreen,
            supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
            localeResolutionCallback: (locale, _) {
              if (locale != null) {
                mainEntityManager
                    .setUnique(ChangeLocaleEvent(locale.languageCode));
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
              final appTheme = mainEntityManager
                  .getUniqueEntity<AppSettingsTag>()
                  .get<AppTheme>();

              switch (settings.name) {
                case Routes.splashScreen:
                  pageWidget = SplashScreenPage();
                  break;
                case Routes.errorPage:
                  pageWidget = StorageErrorPage();
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
                        em.setUnique(AppSettingsTag())
                          ..set(localization)
                          ..set(appTheme);
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

                        em.setUnique(AppSettingsTag())
                          ..set(localization)
                          ..set(appTheme);

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
                            ..set(note.get<Picture>())
                            ..set(PersistMe(note.get<DatabaseKey>().value));
                      },
                    ),
                  );
                  break;
                case Routes.createEvent:
                  pageWidget = EntityManagerProvider.feature(
                    system: FeatureSystem(
                        rootEntityManager: mainEntityManager,
                        onCreate: (em, root) {
                          em.setUnique(FeatureEntityTag())
                            ..set(Priority(ReminderPriority.low))
                            ..set(Timestamp(DateTime.now().toIso8601String()));
                          em.setUnique(AppSettingsTag())
                            ..set(localization)
                            ..set(appTheme);
                        },
                        onDestroy: (em, root) {
                          final note = em.getUniqueEntity<FeatureEntityTag>();

                          if (note.hasT<PersistMe>())
                            root.createEntity()
                              ..set(note.get<Contents>())
                              ..set(note.get<Timestamp>())
                              ..set(note.get<Priority>())
                              ..set(PersistMe());
                        }),
                    child: EventFormFeature(
                      title: localization.createEventFeatureTitle,
                    ),
                  );
                  break;
                case Routes.editEvent:
                  pageWidget = EntityManagerProvider.feature(
                    child: EventFormFeature(
                      title: localization.editEventFeatureTitle,
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        final editNote =
                            root.getUniqueEntity<FeatureEntityTag>();

                        em.setUnique(AppSettingsTag())
                          ..set(localization)
                          ..set(appTheme);

                        em.setUnique(FeatureEntityTag())
                          ..set(editNote.get<Contents>())
                          ..set(editNote.get<Timestamp>())
                          ..set(editNote.get<DatabaseKey>())
                          ..set(editNote.get<Priority>());

                        root.removeUnique<FeatureEntityTag>();
                      },
                      onDestroy: (em, root) {
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        if (note.hasT<PersistMe>())
                          root.createEntity()
                            ..set(note.get<Contents>())
                            ..set(note.get<Timestamp>())
                            ..set(note.get<Priority>())
                            ..set(PersistMe(note.get<DatabaseKey>().value));
                      },
                    ),
                  );
                  break;
                default:
                  pageWidget = Container();
              }
              return MaterialPageRoute(
                  builder: (_) => pageWidget, fullscreenDialog: true);
            },
            theme: ThemeData(
                brightness: appTheme.brightness,
                canvasColor: Colors.transparent,
                splashColor: appTheme.accentColor,
                scaffoldBackgroundColor: Colors.transparent,
                textSelectionHandleColor: appTheme.primaryButtonColor,
                textSelectionColor: appTheme.primaryButtonColor,
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
      UserSettingsSystem(),
      TickSystem(),
      BackupSystem(),
      PersistanceSystem(),
      DiscardSystem(),
      ReminderOperationsSystem(),
      NoteOperationsSystem(),
      NavigationSystem(navigatorKey),
      StatusBarSystem(),
      InBetweenNavigationSystem(),
      SearchSystem()
    ]),
  ));
}
