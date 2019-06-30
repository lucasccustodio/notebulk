import 'package:flutter/material.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notebulk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Notebulk"),
        ),
        body: Center(
          child: Text("Notes here"),
        ),
        floatingActionButton: FloatingActionButton(
          child: Text('New note'),
          onPressed: () {
          },
        ),
      ),
    );
  }
}
