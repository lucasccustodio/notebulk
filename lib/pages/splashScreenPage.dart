import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';

class SplashScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: EntityObservingWidget(
        provider: (em) => em.getUniqueEntity<SplashScreenTag>(),
        builder: (splashScreen, context) {
          final progress = splashScreen.get<Counter>().value;

          return Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text('Notebulk',
                    style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'OpenSans',
                        fontStyle: FontStyle.italic,
                        color: Colors.white)),
                Text(
                  '$progress%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'OpenSans',
                      color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
