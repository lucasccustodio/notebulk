import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';

class HomePage extends StatefulWidget {
  final EntityManager entityManager;

  const HomePage({Key key, this.entityManager}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    widget.entityManager
        .setUnique(FABStatusComponent(status: FABStatus.closed));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Deseja sair?'),
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
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          bottom: true,
          maintainBottomViewPadding: false,
          child: Stack(
            children: <Widget>[
              CustomScrollView(
                controller: _controller,
                key: PageStorageKey('noteListScroll'),
                slivers: <Widget>[
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: const Radius.circular(45),
                            bottomRight: const Radius.circular(45))),
                    backgroundColor: Colors.black,
                    title: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        "Suas notas",
                        style: Theme.of(context).textTheme.headline.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w400),
                      ),
                    ),
                    actions: <Widget>[
                      IconButton(
                        padding: EdgeInsets.all(0),
                        icon: Icon(Icons.search),
                        onPressed: () {},
                      )
                    ],
                  ),
                  SliverPadding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 4, bottom: 4),
                      sliver: GroupObservingWidget(
                          matcher: NoteMatcher(),
                          builder: (group, context) {
                            var notesList = group.entities;

                            return notesList.isEmpty
                                ? buildEmptyNote(context)
                                : buildNoteListView(notesList);
                          })),
                ],
              ),
              Positioned(
                  right: 16,
                  bottom: 16,
                  child: AnimatedFab(
                    onPressed: (index) {
                      widget.entityManager.setUnique(NavigationSystemComponent(
                          routeName: index == 0
                              ? Routes.createNote
                              : Routes.createList));
                    },
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmptyNote(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(child: EmptyNoteCardWidget()),
    );
  }

  Widget buildNoteListView(List<Entity> notes) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        var noteEntity = notes[index];

        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: InkWell(
            splashColor: Colors.blue,
            onTap: () => selectNoteAndScrollTo(context, noteEntity, index),
            child: NoteCardWidget(noteEntity: noteEntity),
          ),
        );
      }, childCount: notes.length),
    );
  }

  selectNoteAndScrollTo(BuildContext context, Entity toSelect, int index) {
    var em = widget.entityManager;
    var quarterOfScreen = MediaQuery.of(context).size.height * 0.25;
    var showMenu = toSelect.get<ShowMenuComponent>().showMenu;

    toSelect.set(ShowMenuComponent(!showMenu));

    _controller.animateTo(quarterOfScreen * index,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }
}

class AnimatedFab extends StatefulWidget {
  final Function(int button) onPressed;
  final String tooltip;
  final IconData icon;

  AnimatedFab({this.onPressed, this.tooltip, this.icon});

  @override
  _AnimatedFabState createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with SingleTickerProviderStateMixin {
  bool isOpened = false;
  AnimationController _animationController;
  Animation<Color> _buttonColor;
  Animation<double> _animateIcon;
  Animation<double> _translateButton;
  Curve _curve = Curves.easeOut;
  double _fabHeight = 56.0;

  @override
  initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            setState(() {});
          });
    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _buttonColor = ColorTween(
      begin: Colors.black,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: Curves.linear,
      ),
    ));
    _translateButton = Tween<double>(
      begin: _fabHeight,
      end: -14.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.0,
        1.0,
        curve: _curve,
      ),
    ));
    super.initState();
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  animate() {
    if (!isOpened) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    isOpened = !isOpened;
  }

  Widget addNote() {
    return Container(
      child: FloatingActionButton(
        onPressed: () {
          animate();
          widget.onPressed(0);
        },
        elevation: _animateIcon.value * 6,
        tooltip: 'Note',
        heroTag: 'addNoteBtn',
        child: Icon(Icons.note),
      ),
    );
  }

  Widget addList() {
    return Container(
      child: FloatingActionButton(
        onPressed: () {
          animate();
          widget.onPressed(0);
        },
        elevation: _animateIcon.value * 6,
        tooltip: 'Add list',
        heroTag: 'addListBtn',
        child: Icon(Icons.list),
      ),
    );
  }

  Widget toggle() {
    return Container(
      child: FloatingActionButton(
        backgroundColor: _buttonColor.value,
        onPressed: animate,
        tooltip: 'Toggle',
        heroTag: 'toogleBtn',
        child: _animateIcon.value > 0.5
            ? FadeTransition(
                opacity: _animateIcon,
                child: Icon(Icons.close),
              )
            : Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 2.0,
            0.0,
          ),
          child: addNote(),
        ),
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 1.0,
            0.0,
          ),
          child: addList(),
        ),
        toggle(),
      ],
    );
  }
}
