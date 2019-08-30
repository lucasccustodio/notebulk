import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:tinycolor/tinycolor.dart';

class NoteCardWidget extends StatelessWidget {
  const NoteCardWidget({Key key, this.noteEntity}) : super(key: key);

  final Entity noteEntity;

  @override
  Widget build(BuildContext context) {
    final contents = noteEntity.get<Contents>().value;
    final timestamp = noteEntity.get<Timestamp>()?.value ?? DateTime.now();
    final tags = noteEntity.get<Tags>()?.value ?? [];
    final listItems = noteEntity.get<Todo>()?.value ?? <ListItem>[];
    final picFile = noteEntity.get<Picture>()?.value;
    final isSelected = noteEntity.hasT<Selected>();
    final localization = EntityManagerProvider.of(context)
        .entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>();
    final appTheme = EntityManagerProvider.of(context)
        .entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<AppTheme>()
        .value;

    return Container(
      foregroundDecoration: BoxDecoration(
          color: isSelected
              ? appTheme.primaryButtonColor.withOpacity(0.75)
              : Colors.transparent),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        color: appTheme.appBarColor,
        margin: EdgeInsets.all(0),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  buildTimestamp(context, timestamp, localization, appTheme),
                  SizedBox(
                    height: 8,
                  ),
                  if (picFile != null) ...[
                    buildPicField(picFile),
                    SizedBox(
                      height: 8,
                    ),
                  ],
                  buildContentsField(context, contents, appTheme),
                  if (listItems.isNotEmpty) ...[
                    SizedBox(
                      height: 8,
                    ),
                    buildListField(listItems, context, appTheme)
                  ],
                  if (tags.isNotEmpty) ...[
                    Divider(),
                    buildTags(tags, context, appTheme)
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPicField(File picFile) {
    final margin = EdgeInsets.symmetric(vertical: 8);

    return Card(
      margin: margin,
      elevation: 2,
      child: Hero(
        tag: picFile.path,
        child: Image.file(
          picFile,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget buildContentsField(
      BuildContext context, String contents, BaseTheme appTheme) {
    return Text(
      contents,
      textAlign: TextAlign.left,
      textWidthBasis: TextWidthBasis.longestLine,
      style: appTheme.cardWidgetContentsTyle,
    );
  }

  Widget buildListField(
      List<ListItem> listItems, BuildContext context, BaseTheme appTheme) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < listItems.length; index++)
              Padding(
                padding: EdgeInsets.all(4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '• ${listItems[index].label}',
                        softWrap: true,
                        textAlign: TextAlign.left,
                        style: appTheme.cardWidgetTodoItemStyle.copyWith(
                            fontWeight: listItems[index].isChecked
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: listItems[index].isChecked
                                ? Colors.grey.shade600
                                : appTheme.cardWidgetTodoItemStyle.color,
                            decoration: listItems[index].isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
    );
  }

  Widget buildTimestamp(BuildContext context, DateTime timestamp,
      Localization localization, BaseTheme appTheme) {
    return Text(
      formatTimestamp(timestamp, localization),
      style: appTheme.cardWidgetTimestampStyle,
    );
  }

  Widget buildTags(
      List<String> tags, BuildContext context, BaseTheme appTheme) {
    final padding = EdgeInsets.symmetric(vertical: 4);

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.all(4),
              child: RichText(
                  text:
                      TextSpan(text: tag, style: appTheme.cardWidgetTagStyle)),
            )
        ],
      ),
    );
  }
}

class EventCardWidget extends StatelessWidget {
  const EventCardWidget({Key key, this.noteEntity}) : super(key: key);

  final Entity noteEntity;

  @override
  Widget build(BuildContext context) {
    final reminderPriority = noteEntity.get<Priority>().value.index;
    final contents = noteEntity.get<Contents>().value;
    final timestamp = noteEntity.get<Timestamp>()?.value ?? DateTime.now();
    final isSelected = noteEntity.hasT<Selected>();
    final localization = EntityManagerProvider.of(context)
        .entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<Localization>();
    final appTheme = EntityManagerProvider.of(context)
        .entityManager
        .getUniqueEntity<AppSettingsTag>()
        .get<AppTheme>()
        .value;

    return Container(
      foregroundDecoration: isSelected
          ? BoxDecoration(color: appTheme.primaryButtonColor.withOpacity(0.75))
          : null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        color: appTheme.reminderPriorityColors[reminderPriority],
        margin: EdgeInsets.all(0),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  buildTimestamp(context, timestamp, localization, appTheme),
                  SizedBox(
                    height: 8,
                  ),
                  buildContentsField(context, contents, appTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContentsField(
      BuildContext context, String contents, BaseTheme appTheme) {
    final priority = noteEntity.get<Priority>()?.value;
    final cardColor = priority != null
        ? appTheme.reminderPriorityColors[priority.index]
        : appTheme.appBarColor;
    final textColor =
        TinyColor(cardColor).isDark() ? Colors.white : Colors.black;

    return Text(
      contents,
      textAlign: TextAlign.left,
      maxLines: null,
      textWidthBasis: TextWidthBasis.longestLine,
      style: appTheme.cardWidgetContentsTyle.copyWith(color: textColor),
    );
  }

  Widget buildTimestamp(BuildContext context, DateTime date,
      Localization localization, BaseTheme appTheme) {
    final timestamp = formatTimestamp(date, localization);
    final priority = noteEntity.get<Priority>()?.value;
    final cardColor = priority != null
        ? appTheme.reminderPriorityColors[priority.index]
        : appTheme.appBarColor;
    final textColor =
        TinyColor(cardColor).isDark() ? Colors.white : Colors.black;

    return Text(timestamp,
        style: appTheme.cardWidgetTimestampStyle.copyWith(color: textColor));
  }
}
