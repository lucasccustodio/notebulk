import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/ecs/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;
  static const String emptyMessage =
      'Você ainda não tem anotações arquivadas...';

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: GroupObservingWidget(
            matcher: Matchers.archived,
            builder: (group, context) {
              final notesList = group.entities;

              return buildNotesGridView(notesList, buildNoteCard, emptyMessage);
            }));
  }

  Widget buildNoteCard(Entity note) {
    return InkWell(
      onLongPress: () => selectNote(note),
      onTap: () {
        if (entityManager.getUniqueEntity<DisplayStatusTag>().hasT<Toggle>())
          selectNote(note);
      },
      child: NoteCardWidget(
        noteEntity: note,
      ),
    );
  }
}
