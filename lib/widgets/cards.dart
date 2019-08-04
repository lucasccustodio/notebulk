import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';

class InfoCardWidget extends StatelessWidget {
  const InfoCardWidget(
      {@required this.message,
      @required this.tags,
      Key key,
      this.listItems = const <ListItem>[]})
      : super(key: key);

  final String message;
  final List<String> tags;
  final List<ListItem> listItems;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      margin: EdgeInsets.all(0),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildTimestamp(context, DateTime.now()),
                buildContentsField(context, message),
                if (listItems.isNotEmpty) buildListField(listItems, context),
                GradientLineSeparator(),
                if (tags.isNotEmpty) buildTagsChips(tags, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContentsField(BuildContext context, String contents) {
    final padding = EdgeInsets.only(top: 4, bottom: 4);

    return Padding(
      padding: padding,
      child: Text(
        contents,
        textAlign: TextAlign.left,
        maxLines: null,
        textWidthBasis: TextWidthBasis.longestLine,
        style: Theme.of(context)
            .textTheme
            .title
            .copyWith(fontFamily: 'Ubuntu', fontSize: 16),
      ),
    );
  }

  Widget buildListField(List<ListItem> listItems, BuildContext context) {
    final style = Theme.of(context).textTheme.body1;

    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 4, left: 2),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < listItems.length; index++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.arrow_right),
                    Expanded(
                      child: Text(
                        listItems[index].label,
                        softWrap: true,
                        textAlign: TextAlign.left,
                        style: style.copyWith(
                            fontSize: 14,
                            fontFamily: 'Ubuntu',
                            decoration: listItems[index].isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none),
                      ),
                    ),
                  ],
                ),
              )
          ]),
    );
  }

  Widget buildTimestamp(BuildContext context, DateTime timestamp) {
    final style = Theme.of(context).textTheme.title.copyWith(
        fontFamily: 'OpenSans', fontSize: 12, fontWeight: FontWeight.w700);

    return Text(
      formatTimestamp(timestamp),
      style: style,
    );
  }

  Widget buildTagsChips(List<String> tags, BuildContext context) {
    final style = Theme.of(context).textTheme.caption;
    final accentColor = Theme.of(context).accentColor;
    final padding = EdgeInsets.only(top: 4, bottom: 4);

    return Padding(
      padding: padding,
      child: Text(tags.join(', '),
          textWidthBasis: TextWidthBasis.parent,
          textAlign: TextAlign.justify,
          style: style.copyWith(
            fontFamily: 'OpenSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
          )),
    );
  }
}

class NoteCardWidget extends StatelessWidget {
  const NoteCardWidget({Key key, this.noteEntity}) : super(key: key);

  final Entity noteEntity;

  @override
  Widget build(BuildContext context) {
    final contents = noteEntity.get<Contents>().value;
    final timestamp = noteEntity.get<Timestamp>().value;
    final tags = noteEntity.get<Tags>()?.value ?? [];
    final listItems = noteEntity.get<Todo>()?.value ?? <ListItem>[];
    final picFile = noteEntity.get<Picture>()?.value;
    final isSelected = noteEntity.hasT<Selected>();

    return Container(
      foregroundDecoration:
          BoxDecoration(color: Colors.transparent, boxShadow: [
        if (isSelected)
          BoxShadow(
              color: Theme.of(context).accentColor.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 2)
      ]),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        margin: EdgeInsets.all(0),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  buildTimestamp(context, timestamp),
                  if (picFile != null) buildPicField(picFile),
                  buildContentsField(context, contents),
                  if (listItems.isNotEmpty) buildListField(listItems, context),
                  GradientLineSeparator(),
                  if (tags.isNotEmpty) buildTagsChips(tags, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPicField(File picFile) {
    final margin = EdgeInsets.only(top: 8, bottom: 8);

    return Card(
      margin: margin,
      elevation: 8,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.file(
          picFile,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget buildContentsField(BuildContext context, String contents) {
    final padding = EdgeInsets.only(top: 4, bottom: 4);

    return Padding(
      padding: padding,
      child: Text(
        contents,
        textAlign: TextAlign.left,
        maxLines: null,
        textWidthBasis: TextWidthBasis.longestLine,
        style: Theme.of(context)
            .textTheme
            .title
            .copyWith(fontFamily: 'Ubuntu', fontSize: 16),
      ),
    );
  }

  Widget buildListField(List<ListItem> listItems, BuildContext context) {
    final style = Theme.of(context).textTheme.body1;

    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 4, left: 2),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < listItems.length; index++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.arrow_right),
                    Expanded(
                      child: Text(
                        listItems[index].label,
                        softWrap: true,
                        textAlign: TextAlign.left,
                        style: style.copyWith(
                            fontSize: 14,
                            fontFamily: 'Ubuntu',
                            decoration: listItems[index].isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none),
                      ),
                    ),
                  ],
                ),
              )
          ]),
    );
  }

  Widget buildTimestamp(BuildContext context, DateTime timestamp) {
    final style = Theme.of(context).textTheme.title.copyWith(
        fontFamily: 'OpenSans', fontSize: 12, fontWeight: FontWeight.w700);

    return Text(
      formatTimestamp(timestamp),
      style: style,
    );
  }

  Widget buildTagsChips(List<String> tags, BuildContext context) {
    final style = Theme.of(context).textTheme.caption;
    final accentColor = Theme.of(context).accentColor;
    final padding = EdgeInsets.only(top: 4, bottom: 4);

    return Padding(
      padding: padding,
      child: Text(tags.join(', '),
          style: style.copyWith(
            fontFamily: 'OpenSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
          )),
    );
  }
}
