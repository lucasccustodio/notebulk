import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/widgets/cards.dart';

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var em = EntityManagerProvider.of(context).entityManager;

    return Scaffold(
        appBar: AppBar(),
        resizeToAvoidBottomInset: true,
        body: GroupObservingWidget(
          matcher: Matchers.note,
          builder: (group, context) => ListView.builder(
              itemCount: group.entities.length,
              shrinkWrap: true,
              itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        group.entities[index].destroy();
                      },
                      child: NoteCardWidget(
                        noteEntity: group.entities[index],
                      ),
                    ),
                  )),
        ));
  }
}
