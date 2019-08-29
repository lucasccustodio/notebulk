import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:tinycolor/tinycolor.dart';
import 'package:notebulk/widgets/util.dart';

class EventFormFeature extends StatefulWidget {
  const EventFormFeature({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _EventFormFeatureState createState() => _EventFormFeatureState();
}

class _EventFormFeatureState extends State<EventFormFeature> {
  GlobalKey<FormState> key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;

    void closeFeature() {
      Navigator.of(context).pop(true);
    }

    void closeDialog() {
      Navigator.of(context).pop(false);
    }

    return WillPopScope(
      onWillPop: () async {
        if (!entityManager
            .getUniqueEntity<FeatureEntityTag>()
            .hasT<Changed>()) {
          return true;
        } else {
          return showDialog(
              context: context,
              builder: (context) => ShouldLeavePromptDialog(
                    message: localization.promptLeaveUnsaved,
                    yesLabel: localization.yes,
                    noLabel: localization.no,
                    appTheme: appTheme,
                    onNo: closeDialog,
                    onYes: () {
                      entityManager
                          .getUniqueEntity<FeatureEntityTag>()
                          .remove<PersistMe>();
                      closeFeature();
                    },
                  ));
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Form(
          key: key,
          child: SafeArea(
            top: false,
            bottom: true,
            maintainBottomViewPadding: false,
            child: Theme(
              data: ThemeData(accentColor: appTheme.primaryColor),
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    leading: IconButton(
                      icon: Icon(
                        AppIcons.left,
                        color: appTheme.baseStyle.color,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    backgroundColor: appTheme.appBarColor,
                    actions: <Widget>[
                      EntityObservingWidget(
                        provider: (em) =>
                            em.getUniqueEntity<FeatureEntityTag>(),
                        builder: (noteEntity, context) => FlatButton(
                          child: Text(localization.saveChangesFeatureLabel,
                              style: Theme.of(context).textTheme.title.copyWith(
                                  color: noteEntity.hasT<Changed>()
                                      ? appTheme.primaryButtonColor
                                      : BaseTheme.lightGrey)),
                          onPressed: noteEntity.hasT<Changed>()
                              ? () {
                                  if (key.currentState.validate())
                                    key.currentState.save();
                                  else
                                    return;

                                  entityManager
                                      .getUniqueEntity<FeatureEntityTag>()
                                      .set(PersistMe());

                                  closeFeature();
                                }
                              : null,
                        ),
                      ),
                    ],
                    title: EntityObservingWidget(
                      provider: (em) => em.getUniqueEntity<FeatureEntityTag>(),
                      builder: (noteEntity, context) => Text(
                        "${widget.title}${noteEntity.hasT<Changed>() ? '*' : ''}",
                        style: appTheme.appTitleTextStyle
                            .copyWith(fontFamily: 'Palanquin'),
                      ),
                    ),
                  ),
                  SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: EntityObservingWidget(
                          provider: (em) =>
                              em.getUniqueEntity<FeatureEntityTag>(),
                          builder: (noteEntity, context) => buildEventCard(
                              noteEntity, localization, appTheme),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Card buildEventCard(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final priority = noteEntity.get<Priority>()?.value;
    final cardColor = priority != null
        ? appTheme.reminderPriorityColors[priority.index]
        : appTheme.appBarColor;
    final style = appTheme.formLabelStyle.copyWith(
        color: (TinyColor(cardColor).isDark() ? Colors.white : Colors.black)
            .withOpacity(0.7));

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildTimestamp(noteEntity, localization, appTheme),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                localization.featurePriorityLabel,
                style: style,
              ),
            ),
            buildColorPicker(noteEntity, appTheme),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                localization.featureContentsLabel,
                style: style,
              ),
            ),
            buildContentsField(noteEntity, localization, appTheme),
          ],
        ),
      ),
    );
  }

  Widget buildColorPicker(Entity noteEntity, BaseTheme appTheme) {
    final reminderPriority = noteEntity.get<Priority>()?.value;
    final size = MediaQuery.of(context).size.width * 0.1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final priority in ReminderPriority.values)
          InkWell(
            onTap: () {
              noteEntity..set(Priority(priority))..set(Changed());
            },
            child: Container(
              decoration: BoxDecoration(
                color: appTheme.reminderPriorityColors[priority.index],
                border: priority == reminderPriority
                    ? Border.all(color: Colors.white)
                    : null,
              ),
              width: size,
              height: size,
            ),
          )
      ],
    );
  }

  Widget buildTimestamp(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final timestamp = noteEntity.get<Timestamp>()?.value ?? DateTime.now();
    final priority = noteEntity.get<Priority>()?.value;
    final cardColor = priority != null
        ? appTheme.reminderPriorityColors[priority.index]
        : appTheme.appBarColor;
    final textColor =
        (TinyColor(cardColor).isDark() ? Colors.white : Colors.black)
            .withOpacity(0.7);

    return InkWell(
      onTap: () => showCalendarDialog(noteEntity),
      child: Text(
        formatTimestamp(timestamp, localization),
        style: appTheme.titleTextStyle.copyWith(color: textColor),
      ),
    );
  }

  void showCalendarDialog(Entity noteEntity) async {
    final today = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: noteEntity.get<Timestamp>()?.value ?? today,
        firstDate: DateTime.utc(today.year),
        lastDate: DateTime.utc(today.year + 100));

    if (date != null) {
      noteEntity..set(Timestamp(date.toIso8601String()))..set(Changed());
    }
  }

  Widget buildContentsField(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final priority = noteEntity.get<Priority>()?.value;
    final cardColor = priority != null
        ? appTheme.reminderPriorityColors[priority.index]
        : appTheme.appBarColor;
    final fillColor =
        TinyColor(cardColor).isDark() ? Colors.white : Colors.black;

    return TextFormField(
      initialValue: noteEntity.get<Contents>()?.value ?? '',
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.text,
      maxLines: null,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor.withOpacity(0.25),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(6),
            gapPadding: 0),
        hintText: localization.featureReminderHint,
      ),
      onSaved: (contents) {
        noteEntity.set(Contents(contents));
      },
      onChanged: (_) {
        noteEntity.set(Changed());
      },
      validator: (contents) =>
          contents.isEmpty ? localization.featureContentsError : null,
      style: appTheme.biggerBodyTextStyle,
      textAlign: TextAlign.left,
    );
  }
}
