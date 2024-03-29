import 'package:flutter/material.dart';
import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter_test/flutter_test.dart';

//An UniqueComponent can only be held by a single entity at a time
class TestComponent extends UniqueComponent {
  TestComponent(this.counter);

  final int counter;
}

void main() async {
  testWidgets('Should update counter when fab is tapped', (widgetTester) async {
    //Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));
    //Instantiate TestComponent and set counter to 0

    await widgetTester.pumpWidget(
        //InheritedWidget that will provide our EntityManager to the subtree
        EntityManagerProvider(
      entityManager: testEntityManager,
      child: TestApp(),
    ));

    //By default counter should be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    //Tap to increase counter
    await widgetTester.tap(find.text('Increase counter'));

    //Trigger a frame
    await widgetTester.pump();

    //Now counter should be at 1
    expect(find.text('Counter: 1'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Testing'),
        ),
        body: Center(
          //An reactive widget that will rebuild when the provided Entity's components are modified
          child: EntityObservingWidget(
            //getUniqueEntity will retrieve the entity which is currently holding the corresponding UniqueComponent, not that component itself as EntityObservingWidget is expecting an Entity, if the UniqueComponent isn't currently set it will return null.
            provider: (entityManager) =>
                entityManager.getUniqueEntity<TestComponent>(),
            //The builder function must always return a Widget
            builder: (entity, context) =>
                Text('Counter: ${entity.get<TestComponent>().counter}'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Text('Increase counter'),
          onPressed: () {
            //Retrieve the underlying EntityManager
            final entityManager =
                EntityManagerProvider.of(context).entityManager;
            //Retrieve the UniqueComponent, not it's owner Entity, and the current counter value
            final counter = entityManager.getUnique<TestComponent>().counter;
            //Update the UniqueComponent  by creating a new instance with counter incremented, which will rebuild all EntityObservingWidgets currently observing for changes on this UniqueComponent
            entityManager.setUnique(TestComponent(counter + 1));
          },
        ),
      ),
    );
  }
}
