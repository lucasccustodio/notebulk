import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';
import 'package:permission/permission.dart';

class StorageErrorPage extends StatelessWidget {
  const StorageErrorPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              'O aplicativo precisa de permissão para ler e escrever no dispositivo.',
              textAlign: TextAlign.center,
            ),
            FlatButton.icon(
              icon: Icon(Icons.settings),
              label: Text('Quero permitir'),
              onPressed: () async {
                final status = (await Permission.requestPermissions(
                        [PermissionName.Storage]))
                    .first
                    .permissionStatus;

                if (status == PermissionStatus.allow) {
                  entityManager
                    ..setUnique(SetupDatabaseEvent())
                    ..setUnique(NavigationEvent.replace(Routes.splashScreen));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
