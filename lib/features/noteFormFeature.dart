import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/util.dart';
import 'package:path_provider/path_provider.dart';

class NoteFormFeature extends StatefulWidget {
  const NoteFormFeature({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NoteFormFeatureState createState() => _NoteFormFeatureState();
}

class _NoteFormFeatureState extends State<NoteFormFeature> {
  GlobalKey<FormState> key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

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
              builder: (context) => AlertDialog(
                    title: Text(
                      'Você fez alterações que ainda não foram salvas. Sair mesmo assim?',
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Não'),
                        onPressed: closeDialog,
                      ),
                      FlatButton(
                        child: Text('Sim'),
                        onPressed: () {
                          entityManager
                              .getUniqueEntity<FeatureEntityTag>()
                              .remove<PersistMe>();
                          closeFeature();
                        },
                      ),
                    ],
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
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  leading: BackButton(),
                  backgroundColor:
                      Theme.of(context).accentColor.withOpacity(0.5),
                  actions: <Widget>[
                    EntityObservingWidget(
                      provider: (em) => em.getUniqueEntity<FeatureEntityTag>(),
                      builder: (noteEntity, context) => FlatButton(
                        child: Text(localization.saveChangesFeatureLabel),
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
                  title: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: EntityObservingWidget(
                      provider: (em) => em.getUniqueEntity<FeatureEntityTag>(),
                      builder: (noteEntity, context) => Text(
                        "${widget.title}${noteEntity.hasT<Changed>() ? '*' : ''}",
                        style: Theme.of(context)
                            .textTheme
                            .headline
                            .copyWith(fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 4, bottom: 4),
                    sliver: SliverToBoxAdapter(
                      child: EntityObservingWidget(
                        provider: (em) =>
                            em.getUniqueEntity<FeatureEntityTag>(),
                        builder: (noteEntity, context) =>
                            buildNoteCard(noteEntity, localization),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card buildNoteCard(Entity noteEntity, Localization localization) {
    final timestamp = DateTime.now();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildTimestamp(timestamp, localization),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(localization.featureImageLabel),
            ),
            buildPicField(noteEntity, localization),
            buildContentsField(noteEntity, localization),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(localization.featureTodoLabel),
            ),
            buildListField(noteEntity, localization),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(localization.featureTagsLabel),
            ),
            buildTagsField(noteEntity, localization),
          ],
        ),
      ),
    );
  }

  Widget buildTimestamp(DateTime timestamp, Localization localization) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        formatTimestamp(timestamp, localization),
        style: Theme.of(context).textTheme.title.copyWith(
            fontFamily: 'OpenSans', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget buildContentsField(Entity noteEntity, Localization localization) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: TextFormField(
        initialValue: noteEntity.get<Contents>()?.value ?? '',
        decoration: InputDecoration(
          hintText: localization.featureContentsHint,
          labelText: localization.featureContentsLabel,
        ),
        onSaved: (contents) {
          noteEntity.set(Contents(contents));
        },
        onChanged: (_) {
          noteEntity.set(Changed());
        },
        validator: (contents) =>
            contents.isEmpty ? localization.featureContentsError : null,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget buildListField(Entity noteEntity, Localization localization) {
    final items = noteEntity.get<Todo>()?.value ?? [];

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < items.length; index++)
              CheckboxListTile(
                  value: items[index].isChecked,
                  title: TextFormField(
                    initialValue: items[index].label,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: localization.featureTodoLabel,
                      labelText: localization.featureTodoItemLabel,
                    ),
                    onSaved: (item) {
                      noteEntity.update<Todo>(
                          (old) => old..value[index].label = item);
                    },
                    onChanged: (_) => noteEntity.set(Changed()),
                    style: Theme.of(context).textTheme.body1.copyWith(
                        decoration: items[index].isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none),
                  ),
                  secondary: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      noteEntity
                        ..update<Todo>((old) => old..value.removeAt(index))
                        ..set(Changed());
                    },
                  ),
                  onChanged: (value) {
                    noteEntity
                      ..update<Todo>(
                          (old) => old..value[index].isChecked = value)
                      ..set(Changed());
                  }),
            FlatButton.icon(
              icon: Icon(Icons.add),
              label: Text(localization.featureTodoEnable),
              onPressed: () {
                if (noteEntity.hasT<Todo>())
                  noteEntity
                      .update<Todo>((old) => old..value.add(ListItem('')));
                else
                  noteEntity.set(Todo(value: [ListItem('')]));
              },
            )
          ]),
    );
  }

  Widget buildTagsField(Entity noteEntity, Localization localization) {
    final tags = noteEntity.get<Tags>()?.value ?? [];

    return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Wrap(
          children: <Widget>[
            for (int i = 0; i < tags.length; i++)
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    noteEntity
                      ..update<Tags>((old) => old..value.removeAt(i))
                      ..set(Changed());
                  },
                ),
                title: TextFormField(
                  initialValue: tags[i],
                  decoration: InputDecoration(
                    hintText: localization.featureTagItemLabel,
                    labelText: localization.featureTagsLabel,
                  ),
                  onChanged: (_) => noteEntity.set(Changed()),
                  onSaved: (tag) {
                    return noteEntity
                      ..update<Tags>((old) => old..value[i] = tag)
                      ..set(Changed());
                  },
                  textAlign: TextAlign.left,
                ),
              ),
            FlatButton.icon(
              icon: Icon(Icons.add),
              label: Text(localization.featureTagsEnable),
              onPressed: () {
                if (noteEntity.hasT<Tags>())
                  noteEntity.update<Tags>((old) => Tags(old.value..add('')));
                else
                  noteEntity.set(Tags(const ['']));
              },
            )
          ],
        ));
  }

  Widget buildPicField(Entity noteEntity, Localization localization) {
    final picFile = noteEntity.get<Picture>()?.value;

    if (picFile == null)
      return ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          FlatButton(
              child: Text('Tirar foto'),
              onPressed: () async {
                final image =
                    await ImagePicker.pickImage(source: ImageSource.camera);

                final em = EntityManagerProvider.of(context).entityManager;

                final timestamp =
                    DateTime.now().millisecondsSinceEpoch.toString();
                final path = (await getExternalStorageDirectory()).path;
                final newPath = '$path/Media/$timestamp.jpeg';
                image
                  ..copySync(newPath)
                  ..deleteSync();
                em.getUniqueEntity<FeatureEntityTag>().set(Picture(newPath));
              }),
          FlatButton(
            child: Text('Selecionar foto'),
            onPressed: () async {
              final image =
                  await ImagePicker.pickImage(source: ImageSource.gallery);

              if (image == null) {
                return;
              }

              final em = EntityManagerProvider.of(context).entityManager;

              final timestamp =
                  DateTime.now().millisecondsSinceEpoch.toString();
              final path = (await getExternalStorageDirectory()).path;
              final newPath = '$path/Media/$timestamp.jpeg';
              image
                ..copySync(newPath)
                ..deleteSync();
              em.getUniqueEntity<FeatureEntityTag>().set(Picture(newPath));
            },
          )
        ],
      );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child:
          Hero(tag: picFile.path, child: Image.file(picFile, fit: BoxFit.fill)),
    );
  }
}
