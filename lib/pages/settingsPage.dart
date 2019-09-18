import 'package:flutter/material.dart';
import 'package:notebulk/ecs/ecs.dart';
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
                // Toggle dark mode and persist the changes
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
            textColor: appTheme.buttonIconColor,
            label: Text(
              localization.settingsExportLabel,
              style: appTheme.actionableLabelStyle
                  .copyWith(color: appTheme.buttonLabelColor),
            ),
            onPressed: () {
              // Trigger the event to export database backup
              entityManager.setUnique(ExportBackupEvent());
            },
          ),
          Text('WIP: Doesn\'t handle duplicates'),
          FlatButton.icon(
            icon: Icon(AppIcons.upload, color: appTheme.buttonIconColor),
            color: appTheme.primaryButtonColor,
            textColor: appTheme.buttonLabelColor,
            label: Text(
              localization.settingsImportLabel,
              style: appTheme.actionableLabelStyle
                  .copyWith(color: appTheme.buttonLabelColor),
            ),
            onPressed: () {
              // Trigger the event to import database backup
              entityManager.setUnique(ImportBackupEvent());
            },
          ),
          SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}
