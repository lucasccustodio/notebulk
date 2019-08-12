import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';
import 'package:tinycolor/tinycolor.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
    final textColor = TinyColor(Theme.of(context).accentColor).isDark()
        ? Colors.white
        : Colors.black;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        ListTile(
          title: Text(localization.settingsColorLabel),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            children: [
              for (int i = 0; i < Colors.primaries.length; i++)
                InkWell(
                  onTap: () => entityManager.getUniqueEntity<AppSettingsTag>()
                    ..set(ThemeColor(Colors.primaries[i])),
                  child: Container(
                    color: Colors.primaries[i],
                    foregroundDecoration: BoxDecoration(
                        border: Colors.primaries[i] ==
                                entityManager
                                    .getUniqueEntity<AppSettingsTag>()
                                    .get<ThemeColor>()
                                    .value
                            ? Border.all(
                                color: darkMode ? Colors.white : Colors.black)
                            : null),
                    width: 50,
                    height: 50,
                  ),
                )
            ],
          ),
        ),
        SwitchListTile(
          title: Text(localization.settingsDarkModeLabel),
          value: darkMode,
          onChanged: (_) => entityManager
              .getUniqueEntity<AppSettingsTag>()
              .update<DarkMode>((old) => DarkMode(value: !old.value)),
        ),
        ListTile(
          title: Text('Backup'),
        ),
        RaisedButton.icon(
          icon: Icon(Icons.save),
          color: Theme.of(context).accentColor,
          textColor: textColor,
          label: Text(localization.settingsExportLabel),
          onPressed: () {
            entityManager.setUnique(ExportNotesEvent());
          },
        ),
        RaisedButton.icon(
          icon: Icon(Icons.settings_backup_restore),
          color: Theme.of(context).accentColor,
          textColor: textColor,
          label: Text(localization.settingsImportLabel),
          onPressed: () {
            entityManager.setUnique(ImportNotesEvent());
          },
        )
      ],
    );
  }
}
