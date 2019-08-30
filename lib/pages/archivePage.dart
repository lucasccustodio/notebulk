import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/ecs/util.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;

    return GroupObservingWidget(
        matcher: Matchers.archived,
        builder: (group, context) {
          final notesList = group.entities;
          final notesByDate = <DateTime, List<Entity>>{};

          for (final note in notesList) {
            final date = note.get<Timestamp>().value;
            final simplifiedDate = DateTime.utc(date.year, date.month);
            if (notesByDate[simplifiedDate] == null) {
              notesByDate[simplifiedDate] = [];
            }
            notesByDate[simplifiedDate].add(note);
          }

          if (notesByDate.isEmpty) {
            notesByDate[DateTime.now()] = [];
          }

          return Stack(
            children: <Widget>[
              if (notesList.isEmpty)
                Center(
                  child: RichText(
                    textWidthBasis: TextWidthBasis.longestLine,
                    text: TextSpan(
                        text: '${localization.emptyArchiveHintTitle}\n',
                        style: appTheme.titleTextStyle,
                        children: [
                          TextSpan(
                              text: localization.emptyArchiveHintSubtitle,
                              style: appTheme.subtitleTextStyle)
                        ]),
                  ),
                )
              else
                ListView(
                  primary: true,
                  physics: BouncingScrollPhysics(),
                  key: PageStorageKey('archivedScroll'),
                  children: <Widget>[
                    for (final noteGroup in notesByDate.entries) ...[
                      noteGroup.value.isNotEmpty
                          ? CheckboxListTile(
                              dense: true,
                              activeColor: appTheme.primaryButtonColor,
                              checkColor: appTheme.buttonIconColor,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                formatTimestamp(noteGroup.key, localization,
                                    includeDay: false, includeWeekDay: false),
                                style: appTheme.titleTextStyle,
                              ),
                              value: noteGroup.value
                                      .where((e) => e.hasT<Selected>())
                                      .length ==
                                  noteGroup.value.length,
                              onChanged: (value) {
                                if (value) {
                                  for (final note in noteGroup.value)
                                    note.set(Selected());
                                } else {
                                  for (final note in noteGroup.value)
                                    note.remove<Selected>();
                                }
                              },
                            )
                          : ListTile(
                              dense: true,
                              title: Text(
                                formatTimestamp(noteGroup.key, localization,
                                    includeDay: false, includeWeekDay: false),
                                style: appTheme.titleTextStyle,
                              ),
                            ),
                      buildNotesGridView(
                        noteGroup.value,
                        buildNoteCard,
                      ),
                    ]
                  ],
                ),
            ],
          );
        });
  }

  Widget buildNoteCard(Entity note) {
    return InkWell(
      onLongPress: () => toggleSelected(note),
      onTap: () {
        if (entityManager.getUniqueEntity<DisplayStatusTag>().hasT<Toggle>())
          toggleSelected(note);
      },
      child: NoteCardWidget(
        noteEntity: note,
      ),
    );
  }
}
