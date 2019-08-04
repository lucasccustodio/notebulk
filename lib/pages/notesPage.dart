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
  final String emptyMessage = 'Você ainda não possui nenhuma anotação...';

  Widget buildFAB({bool darkMode = true}) {
    return AnimatableEntityObservingWidget(
        startAnimating: false,
        duration: Duration(milliseconds: 150),
        provider: (em) => em.getUniqueEntity<FABTag>(),
        tweens: {
          'iconColor': ColorTween(
              begin: darkMode ? Colors.white : Colors.black, end: Colors.red),
          'iconOpacity': Tween<double>(begin: 0.0, end: 1.0)
        },
        animateAdded: (c) =>
            c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
        animateRemoved: (c) =>
            c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
        animateUpdated: (oldC, newC) => EntityAnimation.none,
        builder: (fabEntity, animations, __) {
          return FABMenu(
            animateIcon: animations['iconOpacity'],
            toggleButtonColor: animations['iconColor'],
            onToggle: () {
              if (fabEntity.hasT<Toggle>())
                fabEntity.remove<Toggle>();
              else
                fabEntity.set(Toggle());
            },
            onPressed: (index) {
              final routes = [
                Routes.createNote,
                Routes.createNote,
                Routes.createNote
              ];

              entityManager.setUnique(NavigationEvent.push(routes[index]));

              fabEntity.set(Toggle());
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: GroupObservingWidget(
                matcher: Matchers.note,
                builder: (group, context) {
                  final notesList = group.entities;

                  return buildNotesGridView(notesList, buildNoteCard,
                      'Você ainda não possui anotações...', [
                    ListItem('Criar uma anotação'),
                    ListItem('Encarar esse vazio...')
                  ]);
                })),
        AnimatableEntityObservingWidget(
          provider: (em) => em.getUniqueEntity<DisplayStatusTag>(),
          startAnimating: false,
          curve: Curves.decelerate,
          tweens: {
            'size': Tween<double>(begin: 0.0, end: kBottomNavigationBarHeight)
          },
          animateAdded: (c) =>
              c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
          animateRemoved: (c) =>
              c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
          animateUpdated: (_, __) => EntityAnimation.none,
          builder: (statusEntity, animations, context) => Positioned(
            bottom: 8 + (animations['size'].value),
            right: 8,
            child: buildFAB(darkMode: darkMode),
          ),
        ),
      ],
    );
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
