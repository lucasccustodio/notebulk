import 'package:entitas_ff/entitas_ff.dart' show EntityManager;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';

class CreateListPage extends StatefulWidget {
  final EntityManager entityManager;
  const CreateListPage({Key key, this.entityManager}) : super(key: key);

  @override
  _CreateListPageState createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  TextEditingController contentsController = TextEditingController();
  TextEditingController tagsController = TextEditingController();
  TextEditingController itemController = TextEditingController();
  List<ListItem> items;
  FocusNode itemNode = FocusNode();
  int currentlyEditing;

  @override
  void initState() {
    contentsController.text = '';
    tagsController.text = '';
    items = <ListItem>[];
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
                  "Criar lista",
                  style: Theme.of(context).textTheme.headline.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w400),
                ),
              ),
            ),
            SliverPadding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 4, bottom: 4),
                sliver: SliverToBoxAdapter(
                  child: buildListCard(),
                )),
          ],
        ),
      ),
    );
  }

  Card buildListCard() {
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
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 8, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int index = 0; index < items.length; index++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Checkbox(
                              value: items[index].isChecked,
                              onChanged: (value) => setState(() {
                                    items[index].isChecked = value;
                                  })),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.40,
                            child: Text(
                              items[index].label,
                              textAlign: TextAlign.left,
                              textWidthBasis: TextWidthBasis.longestLine,
                              maxLines: null,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                  decoration: items[index].isChecked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none),
                            ),
                          ),
                          if (currentlyEditing == null) ...[
                            IconButton(
                              padding: const EdgeInsets.all(0),
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  itemController.text = items[index].label;
                                  currentlyEditing = index;
                                  itemNode.requestFocus();
                                });
                              },
                            ),
                            IconButton(
                              padding: const EdgeInsets.all(0),
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  items.removeAt(index);
                                });
                              },
                            )
                          ],
                        ],
                      ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(currentlyEditing != null
                                ? Icons.save
                                : Icons.add),
                            onPressed: () {
                              if (currentlyEditing != null) {
                                if (itemController.text.isNotEmpty)
                                  setState(() {
                                    items[currentlyEditing].label =
                                        itemController.text;
                                    itemController.clear();
                                    itemNode.unfocus();
                                    currentlyEditing = null;
                                  });
                              }

                              if (itemController.text.isNotEmpty)
                                setState(() {
                                  items.add(ListItem(itemController.text));
                                  itemController.clear();
                                  itemNode.unfocus();
                                });
                            },
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.65,
                            child: TextField(
                              controller: itemController,
                              focusNode: itemNode,
                              maxLines: null,
                              decoration: InputDecoration(
                                  labelText: "Nome do item",
                                  hintText: "Crie um novo item na lista",
                                  border: InputBorder.none),
                            ),
                          ),
                        ])
                  ]),
            ),
            buildSeparator(),
            buildTagsField(context, textColor),
            buildBottomMenu(textColor)
          ],
        ),
      ),
    );
  }

  void createList() {
    widget.entityManager.setUnique(PersistNoteComponent(
        contents: contentsController.text,
        tags: tagsController.text,
        items: items));
  }

  void cancel() {
    widget.entityManager
        .setUnique(NavigationSystemComponent(routeOp: NavigationOps.pop));
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
            hintText: "Dê um nome pra sua lista primeiro.",
            labelText: "Nome da lista",
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
            hintText: "Insira algumas tags pra ajudar nas buscas depois.",
            labelText: "Tags",
            border: InputBorder.none),
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
            label: Text("Salvar"),
            textColor: textColor,
            onPressed: createList,
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

  @override
  void dispose() {
    contentsController.dispose();
    tagsController.dispose();
    super.dispose();
  }
}
