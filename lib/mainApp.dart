import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/pages/archivePage.dart';
import 'package:notebulk/pages/notesPage.dart';
import 'package:notebulk/pages/searchPage.dart';
import 'package:notebulk/pages/settingsPage.dart';
import 'package:notebulk/widgets/util.dart';

class MainApp extends StatelessWidget {
  const MainApp({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

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
            title: EntityObservingWidget(
              provider: (em) => em.getUniqueEntity<PageIndex>(),
              builder: (e, context) {
                final names = [
                  'Minhas notas',
                  'Pesquisar',
                  'Notas arquivadas',
                  'Configurações'
                ];

                return Text(
                  names[e.get<PageIndex>().value],
                  style: Theme.of(context).textTheme.title,
                );
              },
            ),
          ),
          bottomNavigationBar: buildBottomBar(darkMode: darkMode),
          body: buildScaffoldBody(context, darkMode: darkMode)),
    );
  }

  Stack buildScaffoldBody(BuildContext context, {bool darkMode = true}) {
    return Stack(
      children: <Widget>[
        SafeArea(
          maintainBottomViewPadding: true,
          bottom: false,
          minimum: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom == 0
                  ? kBottomNavigationBarHeight
                  : 0),
          child: EntityObservingWidget(
            provider: (em) => em.getUniqueEntity<PageIndex>(),
            builder: (e, context) {
              Widget pageWidget = Container();
              final index = e.get<PageIndex>().value;

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

              return pageWidget;
            },
          ),
        ),
        Positioned(
          bottom: kBottomNavigationBarHeight,
          child: AnimatableEntityObservingWidget(
            provider: (em) => em.getUniqueEntity<DisplayStatusTag>(),
            startAnimating: false,
            curve: Curves.decelerate,
            duration: Duration(milliseconds: 150),
            tweens: {
              'size': Tween<double>(begin: 0, end: kBottomNavigationBarHeight)
            },
            animateAdded: (c) =>
                c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
            animateRemoved: (c) =>
                c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
            animateUpdated: (_, __) => EntityAnimation.none,
            builder: (statusEntity, animations, context) => Container(
              color: darkMode ? Colors.black : Colors.white,
              width: MediaQuery.of(context).size.width,
              height: animations['size'].value,
              child: statusEntity.hasT<Toggle>()
                  ? EntityObservingWidget(
                      provider: (em) => em.getUniqueEntity<PageIndex>(),
                      builder: (pageEntity, context) {
                        final index = pageEntity.get<PageIndex>().value ?? 0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(statusEntity.get<Contents>()?.value ?? ''),
                            if (index == 0)
                              FlatButton(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                child: Text('Arquivar'),
                                onPressed: () {
                                  entityManager.setUnique(ArchiveNotesEvent());
                                },
                              )
                            else if (index == 2)
                              FlatButton(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                child: Text('Restaurar'),
                                onPressed: () {
                                  entityManager.setUnique(RestoreNotesEvent());
                                },
                              ),
                            FlatButton(
                              child: Text('Excluir'),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBottomBar({bool darkMode = true}) {
    return AnimatableEntityObservingWidget(
      duration: Duration(milliseconds: 150),
      provider: (em) => em.getUniqueEntity<PageIndex>(),
      startAnimating: true,
      tweens: {
        'iconScale': Tween<double>(begin: 1.0, end: 1.5),
        'iconColor': ColorTween(begin: Colors.grey, end: Colors.white)
      },
      builder: (pageEntity, animations, __) {
        final pageIndex = pageEntity.get<PageIndex>().value;

        return BottomNavigation(
          index: pageIndex,
          scaleIcon: animations['iconScale'],
          colorIcon: animations['iconColor'],
          onTap: (index) {
            if (index != pageIndex) {
              entityManager.setUnique(PageIndex(index));
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
