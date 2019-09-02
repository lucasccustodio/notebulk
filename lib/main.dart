import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:notebulk/mainApp.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';

import 'ecs/ecs.dart';
import 'features/features.dart';
import 'pages/pages.dart';

void main() async {
  // Necessary to debug on Linux/Fucshia
  if (Platform.isLinux || Platform.isFuchsia)
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  // Main EntityManager instance
  final mainEntityManager = EntityManager();

  // Set up the app initial configuration
  mainEntityManager.setUnique(AppSettingsTag())
    ..set(Localization.en())
    ..set(AppTheme(BlankTheme()));
  mainEntityManager
    ..setUnique(StatusBarTag())
    ..setUnique(PageIndex(0, oldValue: 0))
    ..setUnique(SearchBarTag());

  if (Platform.isFuchsia || Platform.isLinux || Platform.isWindows)
    mainEntityManager.setUnique(
        StoragePermission()); // No need for external storage read/write permission

  // The app's Navigator instance
  final navigatorKey = GlobalKey<NavigatorState>();

  // Provides the EntityManager instance and hosts the RootSystem
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
            // Needed to have navigation events
            // TODO: Make RootSystem a NavigatorObserver and implement navigation on Entitas side instead
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
            // Handle navigation here
            // TODO: Consider changing to Fluro, Voyager or alike
            onGenerateRoute: (settings) {
              Widget pageWidget;
              final localization = mainEntityManager
                  .getUniqueEntity<AppSettingsTag>()
                  .get<Localization>();
              final appTheme = mainEntityManager
                  .getUniqueEntity<AppSettingsTag>()
                  .get<AppTheme>();

              // See features.dart for an explaination on Features

              switch (settings.name) {
                case Routes.splashScreen:
                  pageWidget = SplashScreenPage();
                  break;
                //
                case Routes.mainScreen:
                  pageWidget = MainApp(
                    entityManager: mainEntityManager,
                  );
                  break;
                case Routes.createNote:
                  pageWidget = EntityManagerProvider.feature(
                    child: NoteFormFeature(
                      title: localization.createNoteFeatureTitle,
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        // Will hold the note data temporarily
                        em.setUnique(FeatureEntityTag());
                        // Copy the settings to match locale and theming
                        em.setUnique(AppSettingsTag())
                          ..set(localization)
                          ..set(appTheme);
                      },
                      onDestroy: (em, root) {
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        // User didn't exit without saving, so persist note
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

                        // Copy theme and locale
                        em.setUnique(AppSettingsTag())
                          ..set(localization)
                          ..set(appTheme);

                        // Populate the temporary note entity with current data
                        em.setUnique(FeatureEntityTag())
                          ..set(editNote.get<Contents>())
                          ..set(editNote.get<Tags>())
                          ..set(editNote.get<Todo>())
                          ..set(editNote.get<DatabaseKey>())
                          ..set(editNote.get<Picture>());

                        // Failsafe to avoid conflicts
                        root.removeUnique<FeatureEntityTag>();
                      },
                      onDestroy: (em, root) {
                        final note = em.getUniqueEntity<FeatureEntityTag>();

                        // User didn't exit without saving, so persist changes
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
                case Routes.createReminder:
                  pageWidget = EntityManagerProvider.feature(
                    system: FeatureSystem(
                        rootEntityManager: mainEntityManager,
                        onCreate: (em, root) {
                          // Temporary reminder with placeholder values
                          em.setUnique(FeatureEntityTag())
                            ..set(Priority(ReminderPriority.low))
                            ..set(Timestamp(DateTime.now().toIso8601String()));
                          // Copy to match theming and locale
                          em.setUnique(AppSettingsTag())
                            ..set(localization)
                            ..set(appTheme);
                        },
                        onDestroy: (em, root) {
                          final reminder =
                              em.getUniqueEntity<FeatureEntityTag>();

                          // User didn't exit without saving, so persist reminder
                          if (reminder.hasT<PersistMe>())
                            root.createEntity()
                              ..set(reminder.get<Contents>())
                              ..set(reminder.get<Timestamp>())
                              ..set(reminder.get<Priority>())
                              ..set(PersistMe());
                        }),
                    child: ReminderFormFeature(
                      title: localization.createEventFeatureTitle,
                    ),
                  );
                  break;
                case Routes.editReminder:
                  pageWidget = EntityManagerProvider.feature(
                    child: ReminderFormFeature(
                      title: localization.editEventFeatureTitle,
                    ),
                    system: FeatureSystem(
                      rootEntityManager: mainEntityManager,
                      onCreate: (em, root) {
                        final editReminder =
                            root.getUniqueEntity<FeatureEntityTag>();

                        em.setUnique(AppSettingsTag())
                          ..set(localization)
                          ..set(appTheme);

                        // Populate with current data
                        em.setUnique(FeatureEntityTag())
                          ..set(editReminder.get<Contents>())
                          ..set(editReminder.get<Timestamp>())
                          ..set(editReminder.get<DatabaseKey>())
                          ..set(editReminder.get<Priority>());

                        // Failsafe to avoid conflicts
                        root.removeUnique<FeatureEntityTag>();
                      },
                      onDestroy: (em, root) {
                        final reminder = em.getUniqueEntity<FeatureEntityTag>();

                        // User didn't exit without saving, so persist changes
                        if (reminder.hasT<PersistMe>())
                          root.createEntity()
                            ..set(reminder.get<Contents>())
                            ..set(reminder.get<Timestamp>())
                            ..set(reminder.get<Priority>())
                            ..set(PersistMe(reminder.get<DatabaseKey>().value));
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
            // Basic theming
            theme: ThemeData(
                brightness: appTheme.brightness,
                canvasColor: Colors.transparent,
                splashColor: appTheme.accentColor,
                scaffoldBackgroundColor: Colors.transparent,
                textSelectionHandleColor: appTheme.primaryButtonColor,
                textSelectionColor: appTheme.primaryButtonColor,
                fontFamily: 'Palanquin',
                typography: Typography(
                  englishLike: Typography.englishLike2018,
                  dense: Typography.dense2018,
                  tall: Typography.tall2018,
                )),
          ),
        );
      },
    ),
    // Manages all the app systems lifecycle and execution
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
