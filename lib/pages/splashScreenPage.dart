import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';

class SplashScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: SizedBox.expand(
          child: Align(
            alignment: Alignment.center,
            child: Text('Notebulk',
                style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PalanquinDark',
                    color: Colors.white)),
          ),
        ));
  }
}
