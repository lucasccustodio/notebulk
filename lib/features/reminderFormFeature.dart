import 'package:flutter/material.dart';
import 'package:notebulk/ecs/ecs.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:tinycolor/tinycolor.dart';
import 'package:notebulk/widgets/util.dart';

// Reminder form, will get intially populated if the reminder already exists or start blank if creating a new one
class ReminderFormFeature extends StatefulWidget {
  const ReminderFormFeature({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ReminderFormFeatureState createState() => _ReminderFormFeatureState();
}

class _ReminderFormFeatureState extends State<ReminderFormFeature> {
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FocusNode contentsNode;

  @override
  void initState() {
    super.initState();
    contentsNode = FocusNode();
  }

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
          return await showDialog(
              context: context,
              builder: (context) => ShouldLeavePromptDialog(
                    message: localization.promptLeaveUnsaved,
                    yesLabel: localization.yes,
                    noLabel: localization.no,
                    appTheme: appTheme,
                    onNo: closeDialog,
                    onYes: () {
                      // Exit without saving
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
        backgroundColor: appTheme.appBarColor,
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
                              style: appTheme.appTitleTextStyle.copyWith(
                                  fontSize: 24,
                                  color: noteEntity.hasT<Changed>()
                                      ? appTheme.primaryButtonColor
                                      : BaseTheme.lightGrey)),
                          onPressed: noteEntity.hasT<Changed>()
                              ? () {
                                  if (key.currentState.validate())
                                    key.currentState.save();
                                  else {
                                    contentsNode
                                      ..unfocus()
                                      ..requestFocus();
                                    return;
                                  }

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
                          builder: (noteEntity, context) =>
                              buildFormBody(noteEntity, localization, appTheme),
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

  Widget buildFormBody(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final priority = noteEntity.get<Priority>()?.value;
    final cardColor = priority != null
        ? appTheme.reminderPriorityColors[priority.index]
        : appTheme.appBarColor;
    final style = appTheme.formLabelStyle;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildTimestamp(noteEntity, localization, appTheme),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              localization.featurePriorityLabel,
              style: style,
            ),
          ),
          buildColorPicker(noteEntity, appTheme),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              localization.featureContentsLabel,
              style: style,
            ),
          ),
          buildContentsField(noteEntity, localization, appTheme),
        ],
      ),
    );
  }

  Widget buildColorPicker(Entity noteEntity, BaseTheme appTheme) {
    final reminderPriority = noteEntity.get<Priority>()?.value;
    final size = MediaQuery.of(context).size.width * 0.15;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
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
                    ? Border.all(color: appTheme.baseStyle.color, width: 2)
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
      onTap: () => showCalendarDialog(noteEntity, appTheme),
      child: Text(
        formatTimestamp(timestamp, localization),
        style: appTheme.titleTextStyle,
      ),
    );
  }

  void showCalendarDialog(Entity noteEntity, BaseTheme appTheme) async {
    final today = DateTime.now();
    final date = await showDatePicker(
        context: context,
        builder: (context, calendar) => Theme(
              data: ThemeData(
                  brightness: appTheme.brightness,
                  primaryColor: appTheme.primaryColor,
                  backgroundColor: appTheme.primaryColor,
                  fontFamily: 'Palanquin',
                  dialogTheme: DialogTheme(
                    titleTextStyle: appTheme.titleTextStyle,
                    contentTextStyle: appTheme.subtitleTextStyle,
                  ),
                  accentColor: appTheme.accentColor),
              child: calendar,
            ),
        initialDate: noteEntity.get<Timestamp>()?.value ?? today,
        firstDate: DateTime.utc(today.year),
        lastDate: DateTime.utc(today.year + 100));

    if (date != null) {
      noteEntity..set(Timestamp(date.toIso8601String()))..set(Changed());
    }
  }

  Widget buildContentsField(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final priority = noteEntity.get<Priority>()?.value?.index ?? 0;
    final cardColor = appTheme.reminderPriorityColors[priority];
    final fillColor = cardColor;

    return Theme(
      data: ThemeData(
          fontFamily: 'Palanquin'), // Fixes desktop not showing error text
      child: TextFormField(
        focusNode: contentsNode,
        autofocus: true,
        initialValue: noteEntity.get<Contents>()?.value ?? '',
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.text,
        maxLines: null,
        minLines: 5,
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(6),
              gapPadding: 0),
          hintText: localization.featureReminderHint,
        ),
        onSaved: (contents) {
          // Form validated so save modifications
          noteEntity.set(Contents(contents));
        },
        onChanged: (_) {
          // Inform that the note contents changed and enable save button
          noteEntity.set(Changed());
        },
        validator: (contents) =>
            contents.isEmpty ? localization.featureContentsError : null,
        style: appTheme.biggerBodyTextStyle.copyWith(
            color: TinyColor(cardColor).isDark() ? Colors.white : Colors.black),
        textAlign: TextAlign.left,
      ),
    );
  }
}
