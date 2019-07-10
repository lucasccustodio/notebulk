import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';

class NoResultsCardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cardColor = Colors.white;
    var textColor = Colors.black;

    var contents =
        "Sua pesquisa não retornou nenhum resultado. Dá uma conferida se não digitou alguma tag errado.";
    var tags = "Tente novamente!";

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
              style:
                  Theme.of(context).textTheme.title.copyWith(color: textColor),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
            child: Text(
              contents,
              style:
                  Theme.of(context).textTheme.body1.copyWith(color: textColor),
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
        ],
      ),
    );
  }
}

class EmptyNoteCardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              style:
                  Theme.of(context).textTheme.title.copyWith(color: textColor),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
            child: Text(
              contents,
              style:
                  Theme.of(context).textTheme.body1.copyWith(color: textColor),
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
        ],
      ),
    );
  }
}

class NoteCardWidget extends StatelessWidget {
  final Entity noteEntity;

  NoteCardWidget({Key key, this.noteEntity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var contents = noteEntity.get<ContentsComponent>().contents;
    var timestamp = noteEntity.get<TimestampComponent>().timestamp;
    var tags = noteEntity.get<TagsComponent>()?.tags;
    var listItems =
        noteEntity.get<IsListComponent>()?.items ?? const <ListItem>[];
    var cardColor = Colors.white;
    var textColor = Colors.black;

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
            if (listItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int index = 0; index < listItems.length; index++)
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Checkbox(
                                  value: listItems[index].isChecked,
                                  onChanged: null),
                              Text(
                                listItems[index].label,
                                style: Theme.of(context)
                                    .textTheme
                                    .body1
                                    .copyWith(
                                        decoration: listItems[index].isChecked
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none),
                              ),
                            ])
                    ]),
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
            if (noteEntity.get<ShowMenuComponent>().showMenu)
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

                        em.setUniqueOnEntity(EditingNoteComponent(), noteEntity);

                        em.setUnique(NavigationSystemComponent(
                            routeName: noteEntity.hasT<IsListComponent>() ? Routes.editList : Routes.editNote));
                      },
                    ),
                    FlatButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text("Excluir"),
                      textColor: textColor,
                      onPressed: () {
                        var em =
                            EntityManagerProvider.of(context).entityManager;

                        em.setUniqueOnEntity(
                            DeleteNoteComponent(
                                noteEntity.get<DatabaseKeyComponent>().dbKey),
                            noteEntity);
                      },
                    )
                  ],
                ),
              )
          ],
        ),
    );
  }
}
