import 'dart:ui';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';

import '../util.dart';

class HomePage extends StatelessWidget {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    var em = EntityManagerProvider.of(context).entityManager;

    return Material(
      child: SafeArea(
        top: false,
        bottom: true,
        maintainBottomViewPadding: false,
        child: EntityObservingWidget(
          provider: (em) => em.getUniqueEntity<ErrorComponent>(),
          builder: (errorEntity, context) => Stack(
            children: <Widget>[
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [
                        0.2,
                        0.6,
                        1.0
                      ],
                          colors: [
                        Colors.black,
                        Colors.purple,
                        Colors.purple
                      ])),
                  child: CustomScrollView(
                    controller: _controller,
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
                            "NOTEBULK",
                            style: Theme.of(context)
                                .textTheme
                                .headline
                                .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400),
                          ),
                        ),
                        actions: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 32),
                            child: Row(
                              children: <Widget>[
                                IconButton(
                                  padding: EdgeInsets.all(0),
                                  icon: Icon(
                                    Icons.add,
                                  ),
                                  onPressed: () {
                                    var alreadyCreatingNote =
                                        em.getUniqueEntity<
                                                IsNewNoteComponent>() !=
                                            null;

                                    //TODO: Maybe consider disabling the app bar buttons or make context-aware altogether, instead.
                                    if (alreadyCreatingNote) return;

                                    em.removeUnique<IsSelectedComponent>();

                                    var newNoteEntity = em.createEntity()
                                      ..set(ContentsComponent(''))
                                      ..set(TimestampComponent(
                                          DateTime.now().toIso8601String()));

                                    em.setUniqueOnEntity(
                                        IsNewNoteComponent(), newNoteEntity);

                                    em.setUniqueOnEntity(
                                        ShowSingleNoteComponent(),
                                        newNoteEntity);
                                  },
                                ),
                                IconButton(
                                  padding: EdgeInsets.all(0),
                                  icon: Icon(Icons.search),
                                  onPressed: () {},
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      GroupObservingWidget(
                          matcher: NoteMatcher(),
                          builder: (group, context) {
                            var noteList = group.entities;

                            return EntityObservingWidget(
                                provider: (em) => em
                                    .getUniqueEntity<ShowSingleNoteComponent>(),
                                builder: (noteEntity, context) {
                                  var isInSingleNoteMode = noteEntity != null;

                                  return SliverPadding(
                                    padding: const EdgeInsets.only(
                                        left: 16, right: 16, top: 4, bottom: 8),
                                    sliver: isInSingleNoteMode
                                        ? buildSingleNoteMode(noteEntity)
                                        : noteList.isEmpty
                                            ? buildEmptyNote(context)
                                            : buildNoteListView(noteList, em),
                                  );
                                });
                          }),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter buildSingleNoteMode(Entity showSingleNote) {
    bool isNew = showSingleNote.hasT<IsNewNoteComponent>();

    return SliverToBoxAdapter(
        child: isNew
            ? NewCardWidget(noteEntity: showSingleNote)
            : EditingCardWidget(noteEntity: showSingleNote));
  }

  SliverToBoxAdapter buildEmptyNote(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(child: emptyNote(context)),
    );
  }

  SliverList buildNoteListView(List<Entity> notes, EntityManager em) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        var noteEntity = notes[index];

        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: InkWell(
            splashColor: Colors.blue,
            onTap: () {
              var currentSelected = em.getUniqueEntity<IsSelectedComponent>();
              em.removeUnique<IsSelectedComponent>();

              if (currentSelected != noteEntity)
                em.setUniqueOnEntity(IsSelectedComponent(), noteEntity);
            },
            child: NoteCardWidget(noteEntity: noteEntity),
          ),
        );
      }, childCount: notes.length),
    );
  }

  selectNoteAndScrollTo(BuildContext context, Entity toSelect, int index) {
    var em = EntityManagerProvider.of(context).entityManager;
    var quarterOfScreen = MediaQuery.of(context).size.height * 0.25;
    var currentSelected = em.getUniqueEntity<IsSelectedComponent>();

    currentSelected?.remove<IsSelectedComponent>();

    if (currentSelected != toSelect)
      em.setUniqueOnEntity(IsSelectedComponent(), toSelect);

    _controller.animateTo(quarterOfScreen * index,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }
}

Widget emptyNote(BuildContext context) {
  var cardColor = Colors.white;
  var textColor = Colors.black;

  var contents =
      "Você não possui nenhuma nota no momento mas sempre pode criar uma quando bater a inspiração ;)";
  var tags = "Se inspire!";

  return Card(
    color: cardColor,
    clipBehavior: Clip.antiAlias,
    elevation: 8,
    margin: const EdgeInsets.all(0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
          child: Text(
            formatTimestamp(DateTime.now()),
            style: Theme.of(context).textTheme.title.copyWith(color: textColor),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
          child: Text(
            contents,
            style: Theme.of(context).textTheme.body1.copyWith(color: textColor),
            textAlign: TextAlign.left,
            maxLines: null,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          child: Container(
            width: double.maxFinite,
            height: 1,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.purple, Colors.purpleAccent])),
          ),
        ),
        if (tags != null)
          Padding(
            padding:
                const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
            child: Text(
              tags,
              style:
                  Theme.of(context).textTheme.body2.copyWith(color: textColor),
              textAlign: TextAlign.justify,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
      ],
    ),
  );
}

class NoteCardWidget extends StatelessWidget {
  final Entity noteEntity;

  NoteCardWidget({Key key, this.noteEntity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var contents = noteEntity.get<ContentsComponent>().contents;
    var timestamp = noteEntity.get<TimestampComponent>().timestamp;
    var tags = noteEntity.get<TagsComponent>()?.tags;
    var cardColor = Colors.white;
    var textColor = Colors.black;

    return EntityObservingWidget(
      provider: (_) => noteEntity,
      builder: (e, context) => Card(
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        margin: const EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 4, left: 16, right: 16),
              child: Text(
                formatTimestamp(timestamp),
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: textColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 4, left: 16, right: 16),
              child: Text(
                contents,
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: textColor),
                textAlign: TextAlign.left,
                maxLines: null,
                textWidthBasis: TextWidthBasis.longestLine,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Container(
                width: double.maxFinite,
                height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.purple, Colors.purpleAccent])),
              ),
            ),
            if (tags != null)
              Padding(
                padding: const EdgeInsets.only(
                    top: 8, bottom: 16, left: 16, right: 16),
                child: Text(
                  tags,
                  style: Theme.of(context)
                      .textTheme
                      .body2
                      .copyWith(color: textColor),
                  textAlign: TextAlign.justify,
                  textWidthBasis: TextWidthBasis.longestLine,
                ),
              ),
            if (noteEntity.hasT<IsSelectedComponent>())
              Container(
                width: double.maxFinite,
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                    gradient: RadialGradient(
                        radius: 8.0,
                        center: Alignment.centerRight,
                        colors: [Colors.purpleAccent, Colors.purple])),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FlatButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text("Editar"),
                      textColor: textColor,
                      onPressed: () {
                        var em =
                            EntityManagerProvider.of(context).entityManager;

                        em.setUniqueOnEntity(IsEditingComponent(), noteEntity);
                        em.setUniqueOnEntity(
                            ShowSingleNoteComponent(), noteEntity);
                        noteEntity.set(ContentsComponent(contents));
                      },
                    ),
                    FlatButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text("Excluir"),
                      textColor: textColor,
                      onPressed: () {
                        var em =
                            EntityManagerProvider.of(context).entityManager;

                        em.setUniqueOnEntity(DeleteNoteComponent(), noteEntity);
                      },
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

class EditingCardWidget extends StatefulWidget {
  final Entity noteEntity;

  const EditingCardWidget({Key key, this.noteEntity}) : super(key: key);

  @override
  _EditingWidgetState createState() => _EditingWidgetState();
}

class _EditingWidgetState extends State<EditingCardWidget> {
  TextEditingController contentsController;
  TextEditingController tagsController;

  @override
  void initState() {
    contentsController = TextEditingController(
        text: widget.noteEntity.get<ContentsComponent>().contents);
    tagsController = TextEditingController(
        text: widget.noteEntity.get<TagsComponent>()?.tags ?? '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var noteEntity = widget.noteEntity;
    var timestamp = noteEntity.get<TimestampComponent>().timestamp;
    var cardColor = Colors.white;
    var textColor = Colors.black;

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      margin: const EdgeInsets.all(0),
      child: Form(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 4, left: 16, right: 16),
              child: Text(
                formatTimestamp(timestamp),
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: textColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 4, left: 16, right: 16),
              child: TextField(
                controller: contentsController,
                decoration: InputDecoration(
                    hintText: "Conteúdo da nota", border: InputBorder.none),
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: textColor),
                textAlign: TextAlign.left,
                maxLines: null,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Container(
                width: double.maxFinite,
                height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.purple, Colors.purpleAccent])),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 16, left: 16, right: 16),
              child: TextField(
                controller: tagsController,
                decoration:
                    InputDecoration(hintText: "Tags", border: InputBorder.none),
                style: Theme.of(context)
                    .textTheme
                    .body2
                    .copyWith(color: textColor),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              width: double.maxFinite,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.purple, Colors.purpleAccent])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton.icon(
                    icon: Icon(Icons.save),
                    label: Text("Salvar"),
                    textColor: textColor,
                    onPressed: () {
                      var em = EntityManagerProvider.of(context).entityManager;

                      noteEntity
                          .set(ContentsComponent(contentsController.text));

                      if (tagsController.text.isNotEmpty)
                        noteEntity.set(TagsComponent(tagsController.text));

                      em.setUniqueOnEntity(UpdateNoteComponent(), noteEntity);
                    },
                  ),
                  FlatButton.icon(
                    icon: Icon(Icons.cancel),
                    label: Text("Cancelar"),
                    textColor: textColor,
                    onPressed: () {
                      var em = EntityManagerProvider.of(context).entityManager;

                      em.removeUnique<IsEditingComponent>();
                      em.removeUnique<ShowSingleNoteComponent>();
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class NewCardWidget extends StatefulWidget {
  final Entity noteEntity;

  const NewCardWidget({Key key, this.noteEntity}) : super(key: key);

  @override
  _NewCardWidgetState createState() => _NewCardWidgetState();
}

class _NewCardWidgetState extends State<NewCardWidget> {
  TextEditingController contentsController;
  TextEditingController tagsController;

  @override
  void initState() {
    contentsController = TextEditingController();
    tagsController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var noteEntity = widget.noteEntity;
    var timestamp = noteEntity.get<TimestampComponent>().timestamp;
    var cardColor = Colors.white;
    var textColor = Colors.black;

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      margin: const EdgeInsets.all(0),
      child: Form(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 4, left: 16, right: 16),
              child: Text(
                formatTimestamp(timestamp),
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: textColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 4, left: 16, right: 16),
              child: TextField(
                controller: contentsController,
                decoration: InputDecoration(
                    hintText: "Conteúdo da nota", border: InputBorder.none),
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: textColor),
                textAlign: TextAlign.left,
                maxLines: null,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Container(
                width: double.maxFinite,
                height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.purple, Colors.purpleAccent])),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 16, left: 16, right: 16),
              child: TextField(
                controller: tagsController,
                decoration:
                    InputDecoration(hintText: "Tags", border: InputBorder.none),
                style: Theme.of(context)
                    .textTheme
                    .body2
                    .copyWith(color: textColor),
                textAlign: TextAlign.left,
                maxLines: null,
              ),
            ),
            Container(
              width: double.maxFinite,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.purple, Colors.purpleAccent])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton.icon(
                    icon: Icon(Icons.save),
                    label: Text("Salvar"),
                    textColor: textColor,
                    onPressed: () {
                      var em = EntityManagerProvider.of(context).entityManager;

                      noteEntity
                          .set(ContentsComponent(contentsController.text));

                      if (tagsController.text.isNotEmpty)
                        noteEntity.set(TagsComponent(tagsController.text));

                      em.setUniqueOnEntity(PersistNoteComponent(), noteEntity);
                    },
                  ),
                  FlatButton.icon(
                    icon: Icon(Icons.cancel),
                    label: Text("Descartar"),
                    textColor: textColor,
                    onPressed: () {
                      noteEntity.destroy();
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
