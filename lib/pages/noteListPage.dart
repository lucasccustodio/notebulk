import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:kt_dart/kt.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/ecs/util.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';

class NoteListPage extends StatelessWidget {
  const NoteListPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;

    return GroupObservingWidget(
        matcher: Matchers.note,
        builder: (group, context) {
          final notesList = KtList<ObservableEntity>.from(group.entities)
              .sortedByDescending((e) => e.get<Timestamp>().value)
              .asList();
          final notesByDate = <DateTime, List<ObservableEntity>>{};

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
                buildEmptyPage(localization, appTheme)
              else
                ListView(
                  primary: true,
                  shrinkWrap: false,
                  physics: BouncingScrollPhysics(),
                  children: <Widget>[
                    if (notesList.isNotEmpty)
                      for (final noteGroup in notesByDate.entries) ...[
                        Theme(
                          data: ThemeData(brightness: appTheme.brightness),
                          child: noteGroup.value.isNotEmpty
                              ? CheckboxListTile(
                                  dense: true,
                                  checkColor: appTheme.buttonIconColor,
                                  activeColor: appTheme.primaryButtonColor,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    formatTimestamp(noteGroup.key, localization,
                                        includeDay: false,
                                        includeWeekDay: false),
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
                                        includeDay: false,
                                        includeWeekDay: false),
                                    style: appTheme.titleTextStyle,
                                  ),
                                ),
                        ),
                        buildNotesGridView(
                          noteGroup.value,
                          buildNoteCard,
                        )
                      ]
                  ],
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton(
                  child: Icon(
                    AppIcons.pencil,
                    color: appTheme.buttonIconColor,
                  ),
                  backgroundColor: appTheme.primaryButtonColor,
                  onPressed: () {
                    entityManager
                        .setUnique(NavigationEvent.push(Routes.createNote));
                  },
                ),
              ),
            ],
          );
        });
  }

  Widget buildEmptyPage(Localization localization, BaseTheme appTheme) {
    return Center(
      child: RichText(
        text: TextSpan(
            text: '${localization.emptyNoteHintTitle}\n',
            style: appTheme.titleTextStyle,
            children: [
              TextSpan(
                  text: localization.emptyNoteHintSubtitle,
                  style: appTheme.subtitleTextStyle)
            ]),
      ),
    );
  }

  Widget buildNoteCard(Entity note) {
    return InkWell(
      onLongPress: () => toggleSelected(note),
      onTap: () {
        if (entityManager.getUniqueEntity<DisplayStatusTag>().hasT<Toggle>())
          toggleSelected(note);
        else {
          entityManager
            ..setUniqueOnEntity(FeatureEntityTag(), note)
            ..setUnique(NavigationEvent.push(Routes.editNote));
        }
      },
      child: NoteCardWidget(
        noteEntity: note,
      ),
    );
  }
}
