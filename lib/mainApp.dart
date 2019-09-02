import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide TabBar;
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/pages/archivePage.dart';
import 'package:notebulk/pages/noteListPage.dart';
import 'package:notebulk/pages/reminderListPage.dart';
import 'package:notebulk/pages/searchPage.dart';
import 'package:notebulk/pages/settingsPage.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';

class MainApp extends StatefulWidget {
  const MainApp({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final Curve curve = Curves.easeIn;

  final Duration duration = const Duration(milliseconds: 200);
  PageController pageController;
  GlobalKey<ScaffoldState> scaffoldKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pageController = PageController(
        keepPage: true,
        initialPage: widget.entityManager.getUnique<PageIndex>().value);
  }

  @override
  void initState() {
    super.initState();
    scaffoldKey = GlobalKey<ScaffoldState>();
  }

  @override
  Widget build(BuildContext context) {
    final localization = widget.entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>();
    final appTheme = widget.entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<AppTheme>()
        .value;

    return WillPopScope(
      onWillPop: () async {
        return showDialog(
            context: context,
            builder: (context) => ShouldLeavePromptDialog(
                appTheme: appTheme,
                noLabel: localization.no,
                yesLabel: localization.yes,
                message: localization.promptLeaveApp,
                onYes: () {
                  Navigator.of(context).pop(true);
                },
                onNo: () {
                  Navigator.of(context).pop(false);
                }));
      },
      child: EntityObservingWidget(
        provider: (em) => em.getUniqueEntity<AppSettingsTag>(),
        blacklist: const [Localization],
        builder: (_, __) {
          final appTheme = widget.entityManager
              .getUniqueEntity<AppSettingsTag>()
              .get<AppTheme>()
              .value;

          final isLandspace =
              MediaQuery.of(context).orientation == Orientation.landscape &&
                  Platform.isAndroid;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              final selected =
                  widget.entityManager.group(any: [Selected]).entities;
              for (final e in selected) e.remove<Selected>();
            },
            child: Scaffold(
                key: scaffoldKey,
                resizeToAvoidBottomInset: false,
                appBar: isLandspace
                    ? null
                    : AppBar(
                        elevation: 4,
                        brightness: appTheme.brightness,
                        backgroundColor: appTheme.appBarColor,
                        leading: Platform.isAndroid || Platform.isIOS
                            ? IconButton(
                                icon: Icon(
                                  AppIcons.menu,
                                  color: appTheme.tertiaryButtonColor,
                                ),
                                onPressed: () {
                                  scaffoldKey.currentState.openDrawer();
                                },
                              )
                            : SizedBox(),
                        automaticallyImplyLeading: false,
                        bottom: PreferredSize(
                          child: buildTabBar(appTheme, localization),
                          preferredSize: Size(MediaQuery.of(context).size.width,
                              kTextTabBarHeight),
                        )),
                drawer: !isLandspace && (Platform.isAndroid || Platform.isIOS)
                    ? buildDrawer(appTheme)
                    : null,
                drawerDragStartBehavior: DragStartBehavior.down,
                drawerScrimColor: Colors.black54,
                body: buildScaffoldBody(appTheme)),
          );
        },
      ),
    );
  }

  Drawer buildDrawer(BaseTheme appTheme) {
    final localization = widget.entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>();

    return Drawer(
      key: ValueKey('NotebulkDrawer'),
      child: Container(
        decoration: BoxDecoration(gradient: appTheme.backgroundGradient),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                localization.settingsPageTitle,
                style: appTheme.appTitleTextStyle,
              ),
            ),
            SettingsPage(
              entityManager: widget.entityManager,
            ),
            /* Divider(),
            ListTile(
              title: Text(
                'TAGS',
                style: appTheme.titleTextStyle,
              ),
            ),
            FlatButton.icon(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              icon: Icon(
                AppIcons.plus,
                color: appTheme.primaryButtonColor,
              ),
              label: Text(
                'Criar tag',
                style: appTheme.actionableLabelStyle
                    .copyWith(color: appTheme.primaryButtonColor),
              ),
              onPressed: () {
                widget.entityManager
                    .setUnique(NavigationEvent.push(Routes.manageTags));
              },
            ),
            GroupObservingWidget(
              matcher: Matchers.tag,
              builder: (group, context) {
                final tags = group.entities.toList()
                  ..sort((s1, s2) {
                    final tag1 = s1.get<TagData>().value;
                    final tag2 = s1.get<TagData>().value;

                    return tag2.compareTo(tag1);
                  });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: tags.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.label,
                          color: appTheme.subtitleTextStyle.color,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          tags[index].get<TagData>().value,
                          style: appTheme.subtitleTextStyle,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ) */
          ],
        ),
      ),
    );
  }

  Widget buildScaffoldBody(BaseTheme appTheme) {
    final localization = widget.entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>();

    return Stack(
      children: <Widget>[
        SafeArea(
          maintainBottomViewPadding: false,
          bottom: true,
          child: Theme(
            data: ThemeData(accentColor: appTheme.primaryColor),
            child: Platform.isAndroid || Platform.isIOS
                ? PageView(
                    dragStartBehavior: DragStartBehavior.down,
                    controller: pageController,
                    onPageChanged: (page) => widget.entityManager.setUnique(
                        PageIndex(page,
                            oldValue: widget.entityManager
                                .getUnique<PageIndex>()
                                .value)),
                    children: <Widget>[
                      NoteListPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('NotesPage'),
                      ),
                      ReminderListPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('EventsPage'),
                      ),
                      SearchPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('SearchPage'),
                      ),
                      ArchivePage(
                        entityManager: widget.entityManager,
                        key: ValueKey('ArchivePage'),
                      )
                    ],
                  )
                : EntityObservingWidget(
                    provider: (em) => em.getUniqueEntity<PageIndex>(),
                    builder: (e, __) => <Widget>[
                      NoteListPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('NotesPage'),
                      ),
                      ReminderListPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('EventsPage'),
                      ),
                      SearchPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('SearchPage'),
                      ),
                      ArchivePage(
                        entityManager: widget.entityManager,
                        key: ValueKey('ArchivePage'),
                      ),
                      SettingsPage(
                        entityManager: widget.entityManager,
                        key: ValueKey('SettingsPage'),
                      )
                    ][e.get<PageIndex>().value],
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: StatusBar(
            key: ValueKey('StatusBar'),
            actions: (index) => <Widget>[
              if (index == 0)
                FlatButton(
                  child: Text(
                    localization.archiveActionLabel,
                    style: appTheme.actionableLabelStyle,
                  ),
                  onPressed: () {
                    widget.entityManager.setUnique(ArchiveNotesEvent());
                  },
                )
              else if (index == 1 &&
                  !widget.entityManager
                      .group(any: [Selected])
                      .entities
                      .any((e) => e.hasT<Toggle>()))
                FlatButton(
                  child: Text(localization.completeActionLabel),
                  onPressed: () {
                    widget.entityManager.setUnique(CompleteRemindersEvent());
                  },
                )
              else if (index == 3)
                FlatButton(
                    child: Text(localization.restoreActionLabel),
                    onPressed: () {
                      widget.entityManager.setUnique(RestoreNotesEvent());
                    }),
              if (index != 3)
                FlatButton(
                  child: Text(
                    localization.deleteActionLabel,
                    style: appTheme.actionableLabelStyle,
                  ),
                  onPressed: () {
                    widget.entityManager.setUnique(DiscardSelectedEvent());
                  },
                )
            ],
          ),
        )
      ],
    );
  }

  Widget buildTabBar(BaseTheme appTheme, Localization localization) {
    return AnimatableEntityObservingWidget(
      duration: duration,
      curve: curve,
      provider: (em) => em.getUniqueEntity<PageIndex>(),
      startAnimating: false,
      tweens: {
        'iconScale': Tween<double>(begin: 0.0, end: 1.0),
        'iconColor': ColorTween(
            begin: appTheme.otherTabItemColor,
            end: appTheme.selectedTabItemColor)
      },
      //animateUpdated: (_, __) => EntityAnimation.forward,
      builder: (pageEntity, animations, __) {
        final pageIndex = pageEntity.get<PageIndex>().value;

        return TabBar(
          index: pageIndex,
          scaleIcon: animations['iconScale'],
          colorIcon: animations['iconColor'],
          appTheme: appTheme,
          prevIndex: pageEntity.get<PageIndex>().oldValue,
          onTap: (index) async {
            if (index != pageIndex) {
              if (Platform.isAndroid || Platform.isIOS)
                await pageController.animateToPage(index,
                    duration: duration, curve: curve);

              widget.entityManager
                  .getUniqueEntity<PageIndex>()
                  .set(PageIndex(index, oldValue: pageIndex));
            }
          },
          items: [
            for (final label in localization.pageLabels) TabItem(label: label),
            if (Platform.isWindows || Platform.isLinux || Platform.isFuchsia)
              TabItem(label: localization.settingsPageTitle)
          ],
        );
      },
    );
  }
}
