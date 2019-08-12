import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/ecs/util.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    return GroupObservingWidget(
        matcher: Matchers.note,
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

          return CustomScrollView(
            primary: true,
            slivers: <Widget>[
              for (final noteGroup in notesByDate.entries) ...[
                SliverToBoxAdapter(
                    child: noteGroup.value.isNotEmpty
                        ? CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(formatTimestamp(
                                noteGroup.key, localization,
                                includeDay: false, includeWeekDay: false)),
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
                            title: Text(formatTimestamp(
                                noteGroup.key, localization,
                                includeDay: false, includeWeekDay: false)),
                          )),
                buildNotesSliverGridView(
                    noteGroup.value,
                    buildNoteCard,
                    localization.emptyNoteHint,
                    localization.emptyNoteTodo,
                    localization.defaultHelpTags)
              ]
            ],
          );
        });
  }

  Widget buildNoteCard(Entity note) {
    return InkWell(
      onLongPress: () => selectNote(note),
      onTap: () {
        if (entityManager.getUniqueEntity<DisplayStatusTag>().hasT<Toggle>())
          selectNote(note);
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
