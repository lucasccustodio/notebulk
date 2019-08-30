import 'package:flutter/material.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/widgets/util.dart';

class SplashScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      appTheme: DarkTheme(),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/icon-adaptive.png',
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.height * 0.3,
            ),
            Material(
              child: Text('Notebulk',
                  style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'PalanquinDark',
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
