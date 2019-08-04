import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: <Widget>[
        ListTile(
          title: Text('Cor do tema'),
        ),
        Wrap(
          children: [
            for (int i = 0; i < Colors.primaries.length; i++)
              InkWell(
                onTap: () => entityManager.getUniqueEntity<UserSettingsTag>()
                  ..set(ThemeColor(Colors.primaries[i])),
                child: Container(
                  color: Colors.primaries[i],
                  width: 50,
                  height: 50,
                ),
              )
          ],
        ),
        SwitchListTile(
          title: Text('Modo escuro'),
          value: darkMode,
          onChanged: (_) => entityManager
              .getUniqueEntity<UserSettingsTag>()
              .update<DarkMode>((old) => DarkMode(value: !old.value)),
        )
      ],
    );
  }
}
