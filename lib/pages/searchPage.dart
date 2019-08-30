import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/theme.dart';
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
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;

    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        primary: true,
        physics: BouncingScrollPhysics(),
        key: PageStorageKey('searchScroll'),
        children: <Widget>[
          buildSearchField(localization, appTheme),
          SizedBox(
            height: 16,
          ),
          GroupObservingWidget(
            matcher: Matchers.searchResult,
            builder: (group, context) {
              final notesList = group.entities;
              final term = entityManager
                  .getUniqueEntity<SearchBarTag>()
                  .get<SearchTerm>()
                  ?.value;

              if (term == null || term.isEmpty) return SizedBox();

              if (notesList.isEmpty)
                return Center(
                  child: RichText(
                    text: TextSpan(
                        text: '${localization.emptySearchHintTitle}\n',
                        style: appTheme.titleTextStyle,
                        children: [
                          TextSpan(
                              text: localization.emptySearchHintSubTitle,
                              style: appTheme.subtitleTextStyle)
                        ]),
                  ),
                );

              return buildNotesGridView(notesList, buildNoteCard);
            },
          ),
        ],
      ),
    );
  }

  TextFormField buildSearchField(
      Localization localization, BaseTheme appTheme) {
    return TextFormField(
      key: ValueKey('SearchBar'),
      cursorColor: appTheme.primaryButtonColor,
      style: appTheme.biggerBodyTextStyle,
      decoration: InputDecoration(
          filled: true,
          fillColor: appTheme.selectedTabItemColor.withOpacity(0.3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(10),
              gapPadding: 0),
          hintText: localization.searchNotesHint,
          hintStyle: appTheme.subtitleTextStyle,
          prefixIcon: Icon(
            AppIcons.search,
            color: appTheme.primaryButtonColor,
          )),
      initialValue: entityManager
          .getUniqueEntity<SearchBarTag>()
          .get<SearchTerm>()
          ?.value,
      onChanged: (value) {
        entityManager.getUniqueEntity<SearchBarTag>()
          ..set(SearchTerm(value))
          ..set(entityManager.getUniqueEntity<MainTickTag>().get<Tick>());
      },
      onFieldSubmitted: (_) => entityManager.setUnique(PerformSearchEvent()),
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
