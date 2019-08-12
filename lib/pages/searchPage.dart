import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: InputDecoration(
              hintText: localization.searchNotesHint, icon: Icon(Icons.search)),
          initialValue: entityManager
              .getUniqueEntity<SearchBarTag>()
              .get<SearchTerm>()
              ?.value,
          onChanged: (value) {
            entityManager.getUniqueEntity<SearchBarTag>()
              ..set(SearchTerm(value))
              ..set(entityManager.getUniqueEntity<MainTickTag>().get<Tick>());
          },
          onFieldSubmitted: (_) =>
              entityManager.setUnique(PerformSearchEvent()),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: GroupObservingWidget(
          matcher: Matchers.searchResult,
          builder: (group, context) {
            final notesList = group.entities;

            return buildNotesListView(notesList, buildNoteCard,
                localization.emptySearchHint, localization.emptySearchTodo);
          },
        ),
      ),
    );
  }

  Widget buildNoteCard(Entity note) {
    return InkWell(
      onTap: () {
        entityManager
          ..setUniqueOnEntity(FeatureEntityTag(), note)
          ..setUnique(NavigationEvent.push(Routes.editNote));
      },
      child: NoteCardWidget(
        noteEntity: note,
      ),
    );
  }
}
