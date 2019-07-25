import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:tinycolor/tinycolor.dart';

class InfoCardWidget extends StatelessWidget {
  final String contents;
  final String tags;
  final Entity themeEntity;

  InfoCardWidget(
      {this.contents =
          "Você não possui nenhuma nota no momento mas sempre pode criar uma quando bater a inspiração ;)",
      this.tags = "Ajuda",
      this.themeEntity});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
            child: Text(
              contents,
              textAlign: TextAlign.left,
              maxLines: null,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
          GradientLineSeparator(),
          if (tags != null)
            Padding(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 16, left: 16, right: 16),
              child: Text(
                tags,
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

  NoteCardWidget({Key key, this.noteEntity})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var contents = noteEntity.get<ContentsComponent>().contents;
    var timestamp = noteEntity.get<TimestampComponent>().timestamp;
    var tags = noteEntity.get<TagsComponent>()?.tags;
    var listItems =
        noteEntity.get<ListComponent>()?.items ?? const <ListItem>[];
    var picFile = noteEntity.get<PictureComponent>()?.pic;
    var isArchived = noteEntity.hasT<ArchivedComponent>();
    var buttonColor = TinyColor(Theme.of(context).accentColor).isDark()
        ? Colors.white
        : Colors.black;
    var showMenu = noteEntity.hasT<ShowMenuComponent>();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      margin: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          buildTimestamp(timestamp),
          if (picFile != null) buildPicField(picFile),
          buildContentsField(contents),
          if (listItems.isNotEmpty) buildListField(listItems, context),
          GradientLineSeparator(),
          if (tags != null) buildTagsChips(tags, context),
          if (showMenu) buildBottomMenu(context, buttonColor, isArchived)
        ],
      ),
    );
  }

  Widget buildPicField(File picFile) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: AspectRatio(
        aspectRatio: 4/3,
        child: Image.file(
          picFile,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget buildContentsField(String contents) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: Text(
        contents,
        textAlign: TextAlign.left,
        maxLines: null,
        textWidthBasis: TextWidthBasis.longestLine,
      ),
    );
  }

  Widget buildListField(List<ListItem> listItems, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
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
                        value: listItems[index].isChecked, onChanged: null),
                    Text(
                      listItems[index].label,
                      style: Theme.of(context).textTheme.body1.copyWith(
                          decoration: listItems[index].isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none),
                    ),
                  ])
          ]),
    );
  }

  Widget buildTimestamp(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: Text(
        formatTimestamp(timestamp),
      ),
    );
  }

  Widget buildTagsChips(List<String> tags, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.spaceEvenly,
        spacing: 4,
        runSpacing: 4,
        children: tags
            .map((tag) => Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Theme.of(context).accentColor,
                  label: Text(
                    tag,
                    style: Theme.of(context).textTheme.caption.copyWith(
                        color: TinyColor(Theme.of(context).accentColor).isDark()
                            ? Colors.white
                            : Colors.black),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget buildBottomMenu(
      BuildContext context, Color buttonColor, bool isArchived) {
    return Container(
      color: Theme.of(context).accentColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FlatButton.icon(
            icon: Icon(
              Icons.edit,
              color: buttonColor,
            ),
            label: Text("Editar",
                style: Theme.of(context)
                    .textTheme
                    .subtitle
                    .copyWith(color: buttonColor)),
            onPressed: () {
              var em = EntityManagerProvider.of(context).entityManager;

              em.setUniqueOnEntity(FeatureEntityComponent(), noteEntity);

              em.setUnique(
                  NavigationSystemComponent(routeName: Routes.editNote));
            },
          ),
          if (!isArchived)
            FlatButton.icon(
              icon: Icon(
                Icons.delete,
                color: buttonColor,
              ),
              label: Text("Excluir",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle
                      .copyWith(color: buttonColor)),
              onPressed: () {
                noteEntity.set(DeleteNoteComponent());
              },
            ),
          if (!isArchived)
            FlatButton.icon(
              icon: Icon(
                Icons.archive,
                color: buttonColor,
              ),
              label: Text("Arquivar",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle
                      .copyWith(color: buttonColor)),
              onPressed: () => noteEntity.set(ArchivedComponent()),
            )
          else
            FlatButton.icon(
              icon: Icon(
                Icons.restore,
                color: buttonColor,
              ),
              label: Text("Restaurar",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle
                      .copyWith(color: buttonColor)),
              onPressed: () => noteEntity.remove<ArchivedComponent>(),
            )
        ],
      ),
    );
  }
}
