import 'dart:math';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/ecs/util.dart';
import 'package:notebulk/widgets/cards.dart';

class TestFeature extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final em = EntityManagerProvider.of(context).entityManager;

    return Scaffold(
      appBar: AppBar(
        title: Text('GroupObservingListView'),
      ),
      body: GroupObservingGridBuilder(
        delegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4),
        matcher: Matchers.note,
        onAdded: ListItemAnimation.enterLeft,
        onUpdated: ListItemAnimation.fadeIn,
        itemBuilder: (e, context) => NoteCardWidget(
          noteEntity: e,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          em.createEntity()
            ..set(Contents('test'.padLeft(Random().nextInt(50), 'test')))
            ..set(Timestamp(DateTime.now().toIso8601String()));
        },
      ),
    );
  }
}
