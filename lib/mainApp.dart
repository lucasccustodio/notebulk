import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/pages/archivePage.dart';
import 'package:notebulk/pages/notesPage.dart';
import 'package:notebulk/pages/searchPage.dart';
import 'package:notebulk/pages/settingsPage.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:tinycolor/tinycolor.dart';

class MainApp extends StatelessWidget {
  const MainApp({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;
  final Curve curve = Curves.easeIn;
  final Duration duration = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    return WillPopScope(
      onWillPop: () async {
        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(
                    'Deseja sair?',
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Não'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    FlatButton(
                      child: Text('Sim'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ));
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          appBar: AppBar(
            title: AnimatableEntityObservingWidget(
              startAnimating: false,
              duration: duration,
              curve: curve,
              provider: (em) => em.getUniqueEntity<PageNavigationTag>(),
              tweens: {'opacity': Tween<double>(begin: 1.0, end: 0.0)},
              animateUpdated: (oldC, newC) {
                return oldC is NextIndex && newC is NextIndex
                    ? EntityAnimation.forward
                    : EntityAnimation.none;
              },
              builder: (e, animations, context) {
                final index = e.get<CurrentIndex>().value;
                final nextIndex = e.get<NextIndex>().value;
                final opacity = animations['opacity'].value;

                final names = [
                  localization.showNotesTitle,
                  localization.searchNotesTitle,
                  localization.archivedNotesTitle,
                  localization.settingsPageTitle
                ];

                return Stack(
                  children: <Widget>[
                    Opacity(
                      opacity: opacity,
                      child: Text(
                        names[index],
                        style: Theme.of(context).textTheme.title,
                      ),
                    ),
                    Opacity(
                      opacity: 1.0 - opacity,
                      child: Text(
                        names[nextIndex],
                        style: Theme.of(context).textTheme.title,
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: buildBottomBar(context, darkMode: darkMode),
          body: buildScaffoldBody(context, darkMode: darkMode)),
    );
  }

  Stack buildScaffoldBody(BuildContext context, {bool darkMode = true}) {
    return Stack(
      children: <Widget>[
        SafeArea(
          maintainBottomViewPadding: false,
          bottom: true,
          child: AnimatableEntityObservingWidget(
            startAnimating: false,
            provider: (em) => em.getUniqueEntity<PageNavigationTag>(),
            tweens: {'opacity': Tween<double>(begin: 1.0, end: 0.0)},
            duration: duration,
            curve: curve,
            onAnimationEnd: (reversed) {
              if (reversed) {
                return;
              }

              final newCurrentIndex = entityManager
                  .getUniqueEntity<PageNavigationTag>()
                  .get<NextIndex>()
                  .value;

              entityManager
                  .getUniqueEntity<PageNavigationTag>()
                  .set(CurrentIndex(newCurrentIndex));
            },
            animateUpdated: (oldC, newC) {
              if (oldC is NextIndex && newC is NextIndex) {
                final currentIndex = entityManager
                    .getUniqueEntity<PageNavigationTag>()
                    .get<CurrentIndex>()
                    .value;

                return newC.value != currentIndex
                    ? EntityAnimation.forward
                    : EntityAnimation.none;
              } else
                return EntityAnimation.none;
            },
            builder: (e, animations, context) {
              Widget pageWidget = Container();
              Widget nextPageWidget = Container();
              final index = e.get<CurrentIndex>().value;
              final nextIndex = e.get<NextIndex>().value;
              final opacity = animations['opacity'].value;

              switch (index) {
                case 0:
                  pageWidget = NotesPage(entityManager: entityManager);
                  break;
                case 1:
                  pageWidget = SearchPage(entityManager: entityManager);
                  break;
                case 2:
                  pageWidget = ArchivePage(
                    entityManager: entityManager,
                  );
                  break;
                case 3:
                  pageWidget = SettingsPage(entityManager: entityManager);
                  break;
                default:
                  break;
              }

              switch (nextIndex) {
                case 0:
                  nextPageWidget = NotesPage(entityManager: entityManager);
                  break;
                case 1:
                  nextPageWidget = SearchPage(entityManager: entityManager);
                  break;
                case 2:
                  nextPageWidget = ArchivePage(
                    entityManager: entityManager,
                  );
                  break;
                case 3:
                  nextPageWidget = SettingsPage(entityManager: entityManager);
                  break;
                default:
                  break;
              }

              return Stack(
                children: <Widget>[
                  if (opacity > 0) Opacity(opacity: opacity, child: pageWidget),
                  if (opacity < 1.0)
                    Opacity(
                      opacity: 1.0 - opacity,
                      child: nextPageWidget,
                    )
                ],
              );
            },
          ),
        ),
        AnimatableEntityObservingWidget(
          provider: (em) => em.getUniqueEntity<DisplayStatusTag>(),
          startAnimating: false,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          tweens: {
            'size': Tween<double>(begin: 0.0, end: kBottomNavigationBarHeight)
          },
          animateAdded: (c) =>
              c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
          animateRemoved: (c) =>
              c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
          animateUpdated: (_, __) => EntityAnimation.none,
          builder: (statusEntity, animations, context) => Positioned(
              bottom:
                  kBottomNavigationBarHeight + 8 + (animations['size'].value),
              right: 8,
              child: EntityObservingWidget(
                  provider: (em) => em.getUniqueEntity<PageNavigationTag>(),
                  builder: (pageEntity, context) {
                    final index = pageEntity.get<CurrentIndex>().value ?? 0;

                    return index == 0
                        ? buildFAB(darkMode: darkMode)
                        : SizedBox(
                            width: 0,
                            height: 0,
                          );
                  })),
        ),
        Positioned(
          bottom: kBottomNavigationBarHeight,
          child: AnimatableEntityObservingWidget(
            provider: (em) => em.getUniqueEntity<DisplayStatusTag>(),
            startAnimating: false,
            curve: Curves.easeInOut,
            duration: Duration(milliseconds: 300),
            tweens: {
              'size': Tween<double>(begin: 0, end: kBottomNavigationBarHeight)
            },
            animateAdded: (c) =>
                c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
            animateRemoved: (c) =>
                c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
            animateUpdated: (_, __) => EntityAnimation.none,
            builder: (statusEntity, animations, context) {
              final localization = entityManager
                  .getUniqueEntity<AppSettingsTag>()
                  .get<Localization>();

              return Container(
                color: darkMode ? Colors.black : Colors.white,
                width: MediaQuery.of(context).size.width,
                height: animations['size'].value,
                child: statusEntity.hasT<Toggle>()
                    ? EntityObservingWidget(
                        provider: (em) =>
                            em.getUniqueEntity<PageNavigationTag>(),
                        builder: (pageEntity, context) {
                          final index =
                              pageEntity.get<CurrentIndex>().value ?? 0;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(statusEntity.get<Contents>()?.value ?? ''),
                              if (index == 3)
                                FlatButton(
                                  child: Text(localization.hideActionLabel),
                                  onPressed: () {
                                    statusEntity.remove<Toggle>();
                                  },
                                )
                              else if (index == 0)
                                FlatButton(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  child: Text(localization.archiveActionLabel),
                                  onPressed: () {
                                    entityManager
                                        .setUnique(ArchiveNotesEvent());
                                  },
                                )
                              else if (index == 2)
                                FlatButton(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  child: Text(localization.restoreActionLabel),
                                  onPressed: () {
                                    entityManager
                                        .setUnique(RestoreNotesEvent());
                                  },
                                ),
                              if (index != 3)
                                FlatButton(
                                  child: Text(localization.deleteActionLabel),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onPressed: () {
                                    entityManager.setUnique(DeleteNotesEvent());
                                  },
                                )
                            ],
                          );
                        },
                      )
                    : SizedBox(
                        width: 0,
                        height: 0,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildFAB({bool darkMode = true}) {
    return AnimatableEntityObservingWidget(
        startAnimating: false,
        curve: Curves.bounceInOut,
        duration: Duration(milliseconds: 200),
        provider: (em) => em.getUniqueEntity<FABTag>(),
        tweens: {
          'iconColor': ColorTween(
              begin: darkMode ? Colors.white : Colors.black, end: Colors.red),
          'iconOpacity': Tween<double>(begin: 0.0, end: 1.0)
        },
        animateAdded: (c) =>
            c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
        animateRemoved: (c) =>
            c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
        animateUpdated: (oldC, newC) => EntityAnimation.none,
        builder: (fabEntity, animations, __) {
          return FABMenu(
            numButtons: 2,
            buttonIcons: [Icons.note, Icons.list],
            animateIcon: animations['iconOpacity'],
            toggleButtonColor: animations['iconColor'],
            onToggle: () {
              if (fabEntity.hasT<Toggle>())
                fabEntity.remove<Toggle>();
              else
                fabEntity.set(Toggle());
            },
            onPressed: (index) {
              final routes = [
                Routes.createNote,
                Routes.testPage,
              ];

              entityManager.setUnique(NavigationEvent.push(routes[index]));

              fabEntity.remove<Toggle>();
            },
          );
        });
  }

  Widget buildBottomBar(BuildContext context, {bool darkMode = true}) {
    final iconColor = TinyColor(Theme.of(context).accentColor).isDark()
        ? Colors.white
        : Colors.black;

    return AnimatableEntityObservingWidget(
      duration: duration,
      curve: curve,
      provider: (em) => em.getUniqueEntity<PageNavigationTag>(),
      startAnimating: true,
      tweens: {
        'iconScale': Tween<double>(begin: 1.0, end: 1.5),
        'iconColor': ColorTween(begin: Colors.grey, end: iconColor)
      },
      animateUpdated: (_, c) =>
          c is CurrentIndex ? EntityAnimation.forward : EntityAnimation.reverse,
      builder: (pageEntity, animations, __) {
        final pageIndex = pageEntity.get<CurrentIndex>().value;

        return BottomNavigation(
          index: pageIndex,
          scaleIcon: animations['iconScale'],
          colorIcon: animations['iconColor'],
          containerColor: Theme.of(context).primaryColor,
          onTap: (index) {
            if (index != pageIndex) {
              entityManager
                ..getUniqueEntity<PageNavigationTag>().set(NextIndex(index))
                ..getUniqueEntity<FABTag>().remove<Toggle>();
            }
          },
          items: [
            TabItem(icon: Icons.home),
            TabItem(icon: Icons.search),
            TabItem(icon: Icons.archive),
            TabItem(icon: Icons.settings),
          ],
        );
      },
    );
  }
}
