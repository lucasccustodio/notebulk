import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:tinycolor/tinycolor.dart';

class HomePage extends StatelessWidget {
  final EntityManager entityManager;

  const HomePage({Key key, this.entityManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var darkMode = Theme.of(context).brightness == Brightness.dark;
    var themeColor = Theme.of(context).primaryColor;
    var fabPos = MediaQuery.of(context).size.width / 2 - (56.0 * 4.0) / 2;

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
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          drawer: Drawer(
            child: Container(
              color: Theme.of(context).cardColor,
              child: Column(
                children: <Widget>[
                  Container(
                    child: Text(
                      "Configurações",
                    ),
                    alignment: Alignment.center,
                    color: themeColor,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.15,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Cor do tema"),
                  ),
                  Wrap(
                    children: [
                      for (int i = 0; i < Colors.primaries.length; i++)
                        InkWell(
                          onTap: () =>
                              entityManager.getUniqueEntity<ThemeComponent>()
                                ..set(ColorComponent(Colors.primaries[i]))
                                ..set(AccentColorComponent(
                                    TinyColor(Colors.primaries[i])
                                        .brighten(5)
                                        .color)),
                          child: Container(
                            color: Colors.primaries[i],
                            width: 50,
                            height: 50,
                          ),
                        )
                    ],
                  ),
                  SwitchListTile(
                    title: Text("Modo escuro"),
                    value: darkMode,
                    onChanged: (_) => entityManager
                        .getUniqueEntity<ThemeComponent>()
                        .update<DarkModeComponent>(
                            (old) => DarkModeComponent(!old.darkMode)),
                  )
                ],
              ),
            ),
          ),
          body: buildScaffoldBody(darkMode, fabPos, context)),
    );
  }

  Stack buildScaffoldBody(bool darkMode, double fabPos, BuildContext context) {
    return Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          top: false,
          //maintainBottomViewPadding: true,
          minimum: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: EntityObservingWidget(
            provider: (em) => em.getUniqueEntity<CurrentPageComponent>(),
            builder: (e, context) {
              return NotesList(
                  entityManager: entityManager,
                  currentPage: e.get<CurrentPageComponent>().index);
            },
          ),
        ),
        //if (MediaQuery.of(context).viewInsets.bottom == 0)
        Positioned(
            bottom: 0,
            child: AnimatableEntityObservingWidget<Entity>(
                duration: Duration(milliseconds: 300),
                provider: (em) => em.getUniqueEntity<CurrentPageComponent>(),
                startAnimating: true,
                tweens: {
                  'iconScale': Tween<double>(begin: 1.0, end: 1.2),
                  'iconColor': ColorTween(
                      begin: Colors.grey,
                      end: darkMode ? Colors.white : Colors.black)
                },
                builder: (pageEntity, animations, __) {
                  var pageIndex = pageEntity.get<CurrentPageComponent>().index;

                  return BottomNavigation(
                    index: pageIndex,
                    scaleIcon: animations['iconScale'],
                    colorIcon: animations['iconColor'],
                    onTap: (index) {
                      if (index != pageIndex)
                        entityManager.setUnique(CurrentPageComponent(index));
                    },
                    items: [
                      TabItem(icon: Icons.home, label: "Homepage"),
                      TabItem(icon: Icons.archive, label: "Arquivo")
                    ],
                  );
                })),
        //if (MediaQuery.of(context).viewInsets.bottom == 0)
        Positioned(
            bottom: 30,
            left: fabPos,
            child: AnimatableEntityObservingWidget<EntityMap>(
                startAnimating: false,
                duration: Duration(milliseconds: 300),
                provider: (em) => em.getUniquesNamed({
                      'menuEntity': OpenMenuComponent,
                      'pageEntity': CurrentPageComponent
                    }),
                tweens: {
                  'buttonTranslation': Tween<double>(
                    begin: 56,
                    end: -14,
                  ),
                  'iconColor': ColorTween(
                      begin: darkMode ? Colors.white : Colors.black,
                      end: Colors.red),
                  'iconOpacity': Tween<double>(begin: 0.0, end: 1.0)
                },
                animateUpdated: (oldC, newC) {
                  if (newC is CurrentPageComponent) return null;

                  return (newC is OpenMenuComponent && newC.isOpen == false)
                      ? false
                      : true;
                },
                builder: (map, animations, __) {
                  var isOpen =
                      map['menuEntity'].get<OpenMenuComponent>().isOpen;
                  var page =
                      map['pageEntity'].get<CurrentPageComponent>().index;

                  return page == 0
                      ? FABMenu(
                          animateIcon: animations['iconOpacity'],
                          toggleButtonColor: animations['iconColor'],
                          translateButton: animations['buttonTranslation'],
                          onToggle: () => entityManager
                              .setUnique(OpenMenuComponent(!isOpen)),
                          onPressed: (index) {
                            var routes = [
                              Routes.createNote,
                              Routes.testPage,
                              Routes.createList
                            ];

                            entityManager.setUnique(
                                NavigationSystemComponent.push(routes[index]));

                            entityManager.setUnique(OpenMenuComponent(false));
                          },
                        )
                      : SizedBox();
                })),
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 0.5,
          child: IgnorePointer(
            child: Container(
              width: 1,
              height: MediaQuery.of(context).size.height,
              color: Colors.red,
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 0.5,
          child: IgnorePointer(
            child: Container(
              height: 1,
              width: MediaQuery.of(context).size.width,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

class NotesList extends StatelessWidget {
  final EntityManager entityManager;
  final int currentPage;

  const NotesList({Key key, this.entityManager, this.currentPage = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      key: PageStorageKey(
          currentPage == 0 ? 'noteListScroll' : 'archiveListScroll'),
      slivers: <Widget>[
        AnimatableEntityObservingWidget(
          provider: (em) => em.getUniqueEntity<SearchBarComponent>(),
          tweens: {
            'scale': Tween<double>(
                begin: 0, end: MediaQuery.of(context).size.width * 0.6),
            'opacity': Tween<double>(begin: 0.0, end: 1.0)
          },
          startAnimating: false,
          animateUpdated: (_, c) =>
              (c is SearchBarComponent && c.isOpen == false) ? false : true,
          builder: (searchMenuEntity, animations, context) {
            var barScale = animations['scale'].value;
            var barOpacity = animations['opacity'].value;

            return SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    child: Icon(
                      barOpacity == 1.0 ? Icons.arrow_right : Icons.search,
                    ),
                    onTap: () {
                      entityManager.updateUnique<SearchBarComponent>(
                          (old) => SearchBarComponent(!old.isOpen));
                    },
                  ),
                  Opacity(
                    opacity: barOpacity,
                    child: Container(
                      margin: EdgeInsets.only(left: 8, right: 16 * barOpacity),
                      width: barScale,
                      height: kBottomNavigationBarHeight / 2,
                      child: TextField(
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder()),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
        SliverPadding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
            sliver: GroupObservingWidget(
                matcher: currentPage == 0 ? Matchers.note : Matchers.archived,
                builder: (group, context) {
                  var notesList = group.entities;

                  return notesList.isEmpty
                      ? buildEmptyNote(context)
                      : buildNoteListView(notesList);
                })),
      ],
    );
  }

  Widget buildEmptyNote(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
          child: InfoCardWidget(
        contents: currentPage == 1
            ? "Suas anotações arquivadas irão aparecer aqui e podem ser restauradas depois."
            : "Você ainda não possui nenhuma anotação...",
        themeEntity: entityManager.getUniqueEntity<ThemeComponent>(),
      )),
    );
  }

  Widget buildNoteListView(List<Entity> notes) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        var noteEntity = notes[index];

        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: InkWell(
            onTap: () => selectNote(noteEntity),
            child: NoteCardWidget(
              noteEntity: noteEntity,
            ),
          ),
        );
      }, childCount: notes.length),
    );
  }

  selectNote(Entity toSelect) {
    if (toSelect.hasT<ShowMenuComponent>())
      toSelect.remove<ShowMenuComponent>();
    else
      toSelect.set(ShowMenuComponent());
  }
}
