import 'package:flutter/material.dart';
import 'package:kt_dart/kt.dart';
import 'package:notebulk/ecs/ecs.dart';
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
          // Sort notes by creation/edited date
          final notesList = KtList<ObservableEntity>.from(group.entities)
              .sortedByDescending((e) => e.get<Timestamp>().value)
              .asList();
          // Group by date, only month and year
          final notesByDate = <DateTime, List<ObservableEntity>>{};

          for (final note in notesList) {
            final date = note.get<Timestamp>().value;
            final simplifiedDate = DateTime.utc(date.year, date.month);
            if (notesByDate[simplifiedDate] == null) {
              notesByDate[simplifiedDate] = [];
            }
            notesByDate[simplifiedDate].add(note);
          }

          return Stack(
            children: <Widget>[
              if (notesList.isEmpty)
                buildEmptyPage(localization, appTheme) // Render empty state
              else
                ListView(
                  primary: true,
                  shrinkWrap: false,
                  physics: BouncingScrollPhysics(),
                  children: <Widget>[
                    if (notesList.isNotEmpty)
                      for (final noteGroup in notesByDate.entries) ...[
                        if (noteGroup.value.isNotEmpty)
                          Theme(
                              data: ThemeData(
                                  brightness: appTheme
                                      .brightness), // Make checkbox match brightness
                              child: CheckboxListTile(
                                dense: true,
                                checkColor: appTheme.buttonIconColor,
                                activeColor: appTheme.primaryButtonColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  formatTimestamp(noteGroup.key, localization,
                                      includeDay: false, includeWeekDay: false),
                                  style: appTheme.titleTextStyle,
                                ),
                                value: noteGroup.value
                                        .where((e) => e.hasT<Selected>())
                                        .length ==
                                    noteGroup.value
                                        .length, // Inform that all notes for that month are selected
                                onChanged: (value) {
                                  // Shortcut to select or deselect all associated notes
                                  if (value) {
                                    for (final note in noteGroup.value)
                                      note.set(Selected());
                                  } else {
                                    for (final note in noteGroup.value)
                                      note.remove<Selected>();
                                  }
                                },
                              )),
                        buildNotesGridView(noteGroup.value, buildNoteCard)
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
                    // Open note form in creation mode
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
        // If there's already a selection a single tap should select the note
        if (entityManager.getUniqueEntity<StatusBarTag>().hasT<Toggle>())
          toggleSelected(note);
        else {
          // If nothing is selected open note form for editing instead
          entityManager
            ..setUniqueOnEntity(FeatureEntityTag(),
                note) // Mark this note as the one being edited
            ..setUnique(NavigationEvent.push(Routes.editNote));
        }
      },
      child: NoteCardWidget(
        noteEntity: note,
      ),
    );
  }
}
