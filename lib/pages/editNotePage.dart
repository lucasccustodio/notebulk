import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import '../util.dart';

class EditNotePage extends StatefulWidget {
  final EntityManager entityManager;
  final Entity noteEntity;
  const EditNotePage({this.entityManager, Key key, this.noteEntity})
      : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  TextEditingController contentsController = TextEditingController();
  TextEditingController tagsController = TextEditingController();

  @override
  void initState() {
    contentsController.text =
        widget.noteEntity.get<ContentsComponent>().contents;
    tagsController.text = widget.noteEntity.get<TagsComponent>()?.tags ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: true,
        maintainBottomViewPadding: false,
        child: CustomScrollView(
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
                  "Criar nota",
                  style: Theme.of(context).textTheme.headline.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w400),
                ),
              ),
            ),
            SliverPadding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 4, bottom: 4),
                sliver: SliverToBoxAdapter(
                  child: buildNoteCard(),
                )),
          ],
        ),
      ),
    );
  }

  Card buildNoteCard() {
    var timestamp = DateTime.now();
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
            buildTimestamp(timestamp, context, textColor),
            buildContentsField(context, textColor),
            buildSeparator(),
            buildTagsField(context, textColor),
            buildBottomMenu(textColor)
          ],
        ),
      ),
    );
  }

  void updateNote() {
    widget.entityManager.setUnique(UpdateNoteComponent(
        contents: contentsController.text,
        tags: tagsController.text,
        dbKey: widget.noteEntity.get<DatabaseKeyComponent>().dbKey));
  }

  void cancel() {
    widget.entityManager.setUnique(
        NavigationSystemComponent(routeOp: NavigationOps.pop));
  }

  Padding buildTimestamp(
      DateTime timestamp, BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: Text(
        formatTimestamp(timestamp),
        style: Theme.of(context).textTheme.title.copyWith(color: textColor),
      ),
    );
  }

  Padding buildContentsField(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: TextField(
        dragStartBehavior: DragStartBehavior.down,
        controller: contentsController,
        decoration: InputDecoration(
            hintText: "Conteúdo da nota",
            labelText: "Conteúdo da nota",
            border: InputBorder.none),
        style: Theme.of(context).textTheme.body1.copyWith(color: textColor),
        textAlign: TextAlign.left,
        maxLines: null,
      ),
    );
  }

  Padding buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Container(
        width: double.maxFinite,
        height: 1,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.purple, Colors.purpleAccent])),
      ),
    );
  }

  Padding buildTagsField(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
      child: TextField(
        controller: tagsController,
        decoration: InputDecoration(
            hintText: "Tags", labelText: "Tags", border: InputBorder.none),
        style: Theme.of(context).textTheme.body2.copyWith(color: textColor),
        textAlign: TextAlign.left,
      ),
    );
  }

  Container buildBottomMenu(Color textColor) {
    return Container(
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
            label: Text("Atualizar"),
            textColor: textColor,
            onPressed: updateNote,
          ),
          FlatButton.icon(
            icon: Icon(Icons.cancel),
            label: Text("Cancelar"),
            textColor: textColor,
            onPressed: cancel,
          )
        ],
      ),
    );
  }
}
