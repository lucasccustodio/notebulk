import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
              dense: true,
              activeColor: appTheme.primaryButtonColor,
              title: Text(
                localization.settingsDarkModeLabel,
                style: appTheme.titleTextStyle,
              ),
              value: appTheme.brightness == Brightness.dark,
              onChanged: (enabled) {
                entityManager
                    .getUniqueEntity<AppSettingsTag>()
                    .set(AppTheme(enabled ? DarkTheme() : LightTheme()));
                entityManager.setUnique(PersistUserSettingsEvent());
              }),
          Divider(),
          ListTile(
            dense: true,
            title: Text(
              'Backup',
              style: appTheme.titleTextStyle,
            ),
          ),
          FlatButton.icon(
            icon: Icon(
              AppIcons.download,
              color: appTheme.buttonIconColor,
            ),
            color: appTheme.primaryButtonColor,
            textColor: appTheme.buttonLabelColor,
            label: Text(localization.settingsExportLabel),
            onPressed: () {
              entityManager.setUnique(ExportNotesEvent());
            },
          ),
          FlatButton.icon(
            icon: Icon(AppIcons.upload, color: appTheme.buttonIconColor),
            color: appTheme.primaryButtonColor,
            textColor: appTheme.buttonLabelColor,
            label: Text(localization.settingsImportLabel),
            onPressed: () {
              entityManager.setUnique(ImportNotesEvent());
            },
          ),
          SizedBox(
            height: 16,
          )
        ],
      ),
    );
  }
}
