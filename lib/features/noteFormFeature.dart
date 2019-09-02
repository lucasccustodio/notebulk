import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kt_dart/kt.dart';
import 'package:notebulk/ecs/ecs.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';
import 'package:notebulk/widgets/util.dart';
import 'package:path_provider/path_provider.dart';

// Note form, will get intially populated if the note already exists or start blank if creating a new one
class NoteFormFeature extends StatefulWidget {
  const NoteFormFeature({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NoteFormFeatureState createState() => _NoteFormFeatureState();
}

class _NoteFormFeatureState extends State<NoteFormFeature> {
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
                  appTheme: appTheme,
                  noLabel: localization.no,
                  yesLabel: localization.yes,
                  message: localization.promptLeaveUnsaved,
                  onYes: () {
                    entityManager
                        .getUniqueEntity<FeatureEntityTag>()
                        .remove<PersistMe>();
                    closeFeature();
                  },
                  onNo: closeDialog));
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
                        blacklist: const [Contents, Tags, Todo],
                        builder: (noteEntity, context) => FlatButton(
                          child: Text(
                            localization.saveChangesFeatureLabel,
                            style: appTheme.appTitleTextStyle.copyWith(
                                fontSize: 24,
                                color: noteEntity.hasT<Changed>()
                                    ? appTheme.primaryButtonColor
                                    : BaseTheme.lightGrey),
                          ),
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

  Widget buildTagsField(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    // Tags are separated by comma
    return TextFormField(
      initialValue: noteEntity.get<Tags>()?.value?.join(', ') ?? '',
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.text,
      maxLines: null,
      minLines: 2,
      decoration: InputDecoration(
          filled: true,
          fillColor: appTheme.baseStyle.color.withOpacity(0.1),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(6),
              gapPadding: 0),
          hintText: localization.featureTagsHint,
          hintStyle: appTheme.biggerBodyTextStyle
              .copyWith(color: appTheme.baseStyle.color.withOpacity(0.5)),
          hintMaxLines: 2),
      onSaved: (contents) {
        // Sanitize, process and update note's tags
        noteEntity.set(Tags(contents
            .trim()
            .split(',')
            .where((tag) => tag.isNotEmpty)
            .toList()));
      },
      onChanged: (_) {
        noteEntity.set(Changed());
      },
      textAlign: TextAlign.left,
      style: appTheme.biggerBodyTextStyle,
    );
  }

  Widget buildFormBody(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final timestamp = DateTime.now();
    final style = appTheme.formLabelStyle;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildTimestamp(timestamp, localization, appTheme),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              localization.featureImageLabel,
              style: style,
            ),
          ),
          buildPicField(noteEntity, localization, appTheme),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              localization.featureContentsLabel,
              style: style,
            ),
          ),
          buildContentsField(noteEntity, localization, appTheme),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              localization.featureTodoLabel,
              style: style,
            ),
          ),
          buildListField(noteEntity, localization, appTheme),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              localization.featureTagsLabel,
              style: style,
            ),
          ),
          buildTagsField(noteEntity, localization, appTheme),
        ],
      ),
    );
  }

  Widget buildTimestamp(
      DateTime timestamp, Localization localization, BaseTheme appTheme) {
    return Text(
      formatTimestamp(timestamp, localization),
      style: appTheme.cardWidgetTimestampStyle.copyWith(fontSize: 14),
    );
  }

  Widget buildContentsField(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
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
            fillColor: appTheme.baseStyle.color.withOpacity(0.1),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(6),
                gapPadding: 0),
            hintText: localization.featureContentsHint,
            hintStyle: appTheme.biggerBodyTextStyle
                .copyWith(color: appTheme.baseStyle.color.withOpacity(0.5)),
            hintMaxLines: 2),
        onSaved: (contents) {
          // Form validated so save modifications
          noteEntity.set(Contents(contents));
        },
        onChanged: (_) {
          // Inform that the field changed and enable save button
          noteEntity.set(Changed());
        },
        validator: (contents) =>
            contents.isEmpty ? localization.featureContentsError : null,
        textAlign: TextAlign.left,
        style: appTheme.biggerBodyTextStyle,
      ),
    );
  }

  Widget buildListField(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final todo = KtList<ListItem>.from(noteEntity.get<Todo>()?.value ?? []);

    // List items are separated by newline and completed if ended with *
    return TextFormField(
      initialValue: todo
              .map<String>(
                  (item) => "${item.label}${item.isChecked ? '*' : ''}")
              .filter((label) => label.isNotEmpty)
              .joinToString(separator: '\n\n') ??
          '',
      minLines: 5,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.text,
      maxLines: null,
      decoration: InputDecoration(
          filled: true,
          fillColor: appTheme.baseStyle.color.withOpacity(0.1),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(6),
              gapPadding: 0),
          hintText: localization.featureTodoHint,
          hintStyle: appTheme.biggerBodyTextStyle
              .copyWith(color: appTheme.baseStyle.color.withOpacity(0.5)),
          hintMaxLines: 5),
      onSaved: (contents) {
        // Sanitize, process and update note's todo list
        noteEntity.set(Todo(
            value: KtList.from(contents.split('\n'))
                .map((item) => ListItem(item.replaceAll('*', ''),
                    isChecked: item.endsWith('*')))
                .filter((item) => item.label.isNotEmpty)
                .asList()));
      },
      onChanged: (_) {
        // Inform that the field changed and enable save button
        noteEntity.set(Changed());
      },
      textAlign: TextAlign.left,
      style: appTheme.biggerBodyTextStyle,
    );
  }

  void setPicture(String path) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    if (path == null)
      entityManager.getUniqueEntity<FeatureEntityTag>().remove<Picture>();
    else
      entityManager.getUniqueEntity<FeatureEntityTag>().set(Picture(path));

    entityManager.getUniqueEntity<FeatureEntityTag>().set(Changed());
  }

  Widget buildPicField(
      Entity noteEntity, Localization localization, BaseTheme appTheme) {
    final picFile = noteEntity.get<Picture>()?.value;
    final style = appTheme.actionableLabelStyle;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (picFile != null) ...[
            Hero(
                tag: picFile.path,
                child: Image.file(picFile, fit: BoxFit.fill)),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  AppIcons.cancel,
                  color: Colors.red,
                ),
                onPressed: () {
                  picFile.deleteSync();
                  noteEntity
                    ..remove<Picture>()
                    ..set(Changed());
                },
              ),
            )
          ],
          Container(
            color: appTheme.primaryColor.withOpacity(0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (Platform.isAndroid || Platform.isIOS)
                  FlatButton(
                      child:
                          Text(localization.featureImageCamera, style: style),
                      onPressed: () async {
                        final image = await ImagePicker.pickImage(
                            source: ImageSource.camera);

                        final em =
                            EntityManagerProvider.of(context).entityManager;

                        final timestamp =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        final path = (await getExternalStorageDirectory()).path;
                        final newPath = '$path/Pictures/$timestamp.jpeg';
                        image
                          ..copySync(newPath)
                          ..deleteSync();
                        em
                            .getUniqueEntity<FeatureEntityTag>()
                            .set(Picture(newPath));
                      }),
                FlatButton(
                  child: Text(
                    localization.featureImageGallery,
                    style: style,
                  ),
                  onPressed: () async {
                    if (Platform.isFuchsia ||
                        Platform.isWindows ||
                        Platform.isLinux) {
                      selectImageDesktop(setPicture);
                    } else
                      selectImage(setPicture);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void selectImage(Function(String) callback) async {
    final image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final originPath = (await getExternalStorageDirectory()).path;
    final newPath = '$originPath/Pictures/$timestamp.jpeg';
    image
      ..copySync(newPath)
      ..deleteSync();

    callback(newPath);
  }

  void selectImageDesktop(Function(String) callback) {
    /* 
    Uncomment if Desktop
    showOpenPanel((result, paths) {
      if (result == FileChooserResult.ok && paths.isNotEmpty) {
        final originPath = paths.first;
        final image = File(originPath);
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final newPath = './Files/Pictures/$timestamp.jpeg';
        image.copySync(newPath);

        callback(newPath);
      }
    }); */
    return null;
  }
}
