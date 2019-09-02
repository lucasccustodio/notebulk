import 'package:flutter/material.dart';
import 'package:kt_dart/kt.dart';
import 'package:notebulk/ecs/ecs.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:notebulk/widgets/util.dart';

class ReminderListPage extends StatelessWidget {
  const ReminderListPage({Key key, this.entityManager}) : super(key: key);

  final EntityManager entityManager;

  @override
  Widget build(BuildContext context) {
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;

    return GroupObservingWidget(
        matcher: Matchers.reminder,
        builder: (group, context) {
          final reminderList = group.entities;
          var currentReminders = <Entity>[];
          var lateReminders = <Entity>[];
          var completedReminders = <Entity>[];
          final today = DateTime.now();
          final currentDay = today.day;
          final currentMonth = today.month;
          final currentYear = today.year;
          final currentDate =
              DateTime.utc(currentYear, currentMonth, currentDay);

          // Sort and group reminders into current, late and completed
          for (final reminder in reminderList) {
            final reminderDueDate = reminder.get<Timestamp>().value;

            if (reminder.hasT<Toggle>()) {
              completedReminders.add(reminder);
              continue;
            }

            if (currentDate.isBefore(reminderDueDate)) {
              currentReminders.add(reminder);
            } else {
              lateReminders.add(reminder);
            }
          }

          currentReminders = KtList<Entity>.from(currentReminders)
              .sortedByDescending((e) => e.get<Timestamp>().value)
              .asList();

          lateReminders = KtList<Entity>.from(lateReminders)
              .sortedByDescending((e) => e.get<Timestamp>().value)
              .asList();

          completedReminders = KtList<Entity>.from(completedReminders)
              .sortedByDescending((e) => e.get<Timestamp>().value)
              .asList();

          return Stack(
            children: <Widget>[
              ListView(
                primary: true,
                physics: BouncingScrollPhysics(),
                key: PageStorageKey('eventsScroll'),
                children: <Widget>[
                  if (currentReminders.isNotEmpty) ...[
                    ListTile(
                      title: Text(
                        localization.currentRemindersLabel,
                        style: appTheme.titleTextStyle,
                      ),
                    ),
                    buildNotesGridView(currentReminders, buildReminderCard)
                  ] else
                    ListTile(
                      title: Text(
                        localization.currentRemindersLabel,
                        style: appTheme.titleTextStyle,
                      ),
                      subtitle: Text(localization.currentRemindersEmpty,
                          style: appTheme.subtitleTextStyle),
                    ),
                  Divider(),
                  if (lateReminders.isNotEmpty) ...[
                    ListTile(
                      title: Text(
                        localization.lateRemindersLabel,
                        style: appTheme.titleTextStyle,
                      ),
                    ),
                    buildNotesGridView(lateReminders, buildReminderCard)
                  ] else
                    ListTile(
                      title: Text(
                        localization.lateRemindersLabel,
                        style: appTheme.titleTextStyle,
                      ),
                      subtitle: Text(localization.lateRemindersEmpty,
                          style: appTheme.subtitleTextStyle),
                    ),
                  Divider(),
                  if (completedReminders.isNotEmpty) ...[
                    ListTile(
                      title: Text(
                        localization.completedRemindersLabel,
                        style: appTheme.titleTextStyle,
                      ),
                    ),
                    buildNotesGridView(completedReminders, buildReminderCard)
                  ] else
                    ListTile(
                      title: Text(
                        localization.completedRemindersLabel,
                        style: appTheme.titleTextStyle,
                      ),
                      subtitle: Text(localization.completedRemindersEmpty,
                          style: appTheme.subtitleTextStyle),
                    )
                ],
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton(
                  child: Icon(
                    AppIcons.calendar,
                    color: appTheme.buttonIconColor,
                  ),
                  backgroundColor: appTheme.primaryButtonColor,
                  onPressed: () {
                    // Open form to create a reminder
                    entityManager
                        .setUnique(NavigationEvent.push(Routes.createReminder));
                  },
                ),
              )
            ],
          );
        });
  }

  Widget buildReminderCard(Entity reminder) {
    return InkWell(
      onLongPress: () {
        toggleSelected(reminder);
      },
      onTap: () {
        if (entityManager.getUniqueEntity<StatusBarTag>().hasT<Toggle>()) {
          toggleSelected(reminder);
        } else {
          // Completed reminders can't be edited, so check first
          if (!reminder.hasT<Toggle>())
            entityManager
              ..setUniqueOnEntity(FeatureEntityTag(), reminder)
              ..setUnique(NavigationEvent.push(Routes.editReminder));
        }
      },
      child: ReminderCardWidget(
        reminderEntity: reminder,
      ),
    );
  }
}
