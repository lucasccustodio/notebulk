import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:kt_dart/kt.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/ecs/matchers.dart';
import 'package:notebulk/ecs/util.dart';
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

          for (final reminder in reminderList) {
            final date = reminder.get<Timestamp>().value;

            if (reminder.hasT<Toggle>()) {
              completedReminders.add(reminder);
              continue;
            }

            if (date.year == currentYear &&
                date.month == currentMonth &&
                date.day == currentDay) {
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
                    buildNotesGridView(currentReminders, buildEventCard)
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
                    buildNotesGridView(lateReminders, buildEventCard)
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
                    buildNotesGridView(completedReminders, buildEventCard)
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
                    entityManager
                        .setUnique(NavigationEvent.push(Routes.createEvent));
                  },
                ),
              )
            ],
          );
        });
  }

  Widget buildEventCard(Entity note) {
    return InkWell(
      onLongPress: () {
        selectNote(note);
      },
      onTap: () {
        if (entityManager.getUniqueEntity<DisplayStatusTag>().hasT<Toggle>()) {
          selectNote(note);
        } else {
          if (!note.hasT<Toggle>())
            entityManager
              ..setUniqueOnEntity(FeatureEntityTag(), note)
              ..setUnique(NavigationEvent.push(Routes.editEvent));
        }
      },
      child: EventCardWidget(
        noteEntity: note,
      ),
    );
  }
}
