import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../util.dart';

class NoteFormFeature extends StatefulWidget {
  final String title;

  const NoteFormFeature({Key key, this.title}) : super(key: key);

  @override
  _NoteFormFeatureState createState() => _NoteFormFeatureState();
}

class _NoteFormFeatureState extends State<NoteFormFeature>
    with WidgetsBindingObserver {
  GlobalKey<FormState> key = GlobalKey<FormState>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      retrieveLostData(context);
    }
  }

  Future<void> retrieveLostData(BuildContext context) async {
    final LostDataResponse response = await ImagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      var em = EntityManagerProvider.of(context).entityManager;

      var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      var newPath = (await getExternalStorageDirectory()).path +
          "/Pictures/$timestamp.jpeg";
      response.file.copySync(newPath);
      response.file.deleteSync();
      em
          .getUniqueEntity<FeatureEntityComponent>()
          .set(PictureComponent(newPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    var entityManager = EntityManagerProvider.of(context).entityManager;

    void closeFeature() {
      Navigator.of(context).pop();
    }

    return WillPopScope(
      onWillPop: () async {
        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(
                    'Descartar as alterações?',
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text("Não"),
                      onPressed: () {
                        return Navigator.of(context).pop(false);
                      },
                    ),
                    FlatButton(
                      child: Text("Sim"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                ));
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
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: const Radius.circular(45),
                          bottomRight: const Radius.circular(45))),
                  leading: BackButton(),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.save),
                      onPressed: () {
                        if (key.currentState.validate())
                          key.currentState.save();
                        else
                          return;

                        entityManager.setUnique(HasDataComponent());
                        closeFeature();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: closeFeature,
                    )
                  ],
                ),
                SliverPadding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 4, bottom: 4),
                    sliver: SliverToBoxAdapter(
                      child: EntityObservingWidget(
                        provider: (em) =>
                            em.getUniqueEntity<FeatureEntityComponent>(),
                        builder: (noteEntity, context) =>
                            buildNoteCard(noteEntity),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card buildNoteCard(Entity noteEntity) {
    var timestamp = DateTime.now();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      margin: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildTimestamp(timestamp),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16),
            child: Text("Imagem"),
          ),
          buildPicField(noteEntity),
          buildContentsField(noteEntity),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16),
            child: Text("Lista"),
          ),
          buildListField(noteEntity),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16),
            child: Text("Tags"),
          ),
          buildTagsField(noteEntity),
        ],
      ),
    );
  }

  Widget buildTimestamp(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: Text(
        formatTimestamp(timestamp),
      ),
    );
  }

  Widget buildContentsField(Entity noteEntity) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: TextFormField(
        initialValue: noteEntity.get<ContentsComponent>()?.contents ?? '',
        decoration: InputDecoration(
          hintText: "Sobre o que é essa anotação?",
          labelText: "Conteúdo",
        ),
        onSaved: (contents) => noteEntity.set(ContentsComponent(contents)),
        validator: (contents) =>
            contents.isEmpty ? "Não pode ficar vazio." : null,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget buildListField(Entity noteEntity) {
    var items = noteEntity.get<ListComponent>()?.items;

    if (items == null)
      return FlatButton.icon(
        icon: Icon(Icons.add),
        label: Text("Adicionar lista"),
        onPressed: () {
          noteEntity.set(ListComponent(items: [ListItem("")]));
        },
      );

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
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
                      hintText: "Nome do item",
                      labelText: "Item nº ${index + 1}",
                    ),
                    onSaved: (item) => noteEntity.update<ListComponent>(
                        (old) => old..items[index].label = item),
                    style: Theme.of(context).textTheme.body1.copyWith(
                        decoration: items[index].isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none),
                  ),
                  onChanged: (value) => noteEntity.update<ListComponent>(
                      (old) => old..items[index].isChecked = value)),
            FlatButton.icon(
              icon: Icon(Icons.add),
              label: Text("Novo item da lista"),
              onPressed: () {
                noteEntity.update<ListComponent>(
                    (old) => old..items.add(ListItem("")));
              },
            )
          ]),
    );
  }

  Padding buildTagsField(Entity noteEntity) {
    var tags = noteEntity.get<TagsComponent>()?.tags ?? [];

    return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
        child: Wrap(
          children: <Widget>[
            for (int i = 0; i < tags.length; i++)
              TextFormField(
                initialValue: tags[i],
                decoration: InputDecoration(
                  hintText: "Nome da tag",
                  labelText: "Tag",
                ),
                onSaved: (tag) => noteEntity
                    .update<TagsComponent>((old) => old..tags[i] = tag),
                textAlign: TextAlign.left,
              ),
            FlatButton.icon(
              icon: Icon(Icons.add),
              label: Text("Nova tag"),
              onPressed: () {
                noteEntity.update<TagsComponent>((old) => old..tags.add(""));
              },
            )
          ],
        ));
  }

  Widget buildPicField(Entity noteEntity) {
    var picFile = noteEntity.get<PictureComponent>()?.pic;

    if (picFile == null)
      return ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
              icon: Icon(Icons.camera),
              onPressed: () async {
                var image =
                    await ImagePicker.pickImage(source: ImageSource.camera);

                var em = EntityManagerProvider.of(context).entityManager;

                var timestamp =
                    DateTime.now().millisecondsSinceEpoch.toString();
                var newPath = (await getExternalStorageDirectory()).path +
                    "/Pictures/$timestamp.jpeg";
                image.copySync(newPath);
                image.deleteSync();
                em
                    .getUniqueEntity<FeatureEntityComponent>()
                    .set(PictureComponent(newPath));
              }),
          IconButton(
            icon: Icon(Icons.photo_album),
            onPressed: () async {
              var image =
                  await ImagePicker.pickImage(source: ImageSource.gallery);

              if (image == null) return;

              var em = EntityManagerProvider.of(context).entityManager;

              var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
              var newPath = (await getExternalStorageDirectory()).path +
                  "/Pictures/$timestamp.jpeg";
              image.copySync(newPath);
              em
                  .getUniqueEntity<FeatureEntityComponent>()
                  .set(PictureComponent(newPath));
            },
          )
        ],
      );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
      child: Image.file(picFile, fit: BoxFit.fill),
    );
  }
}
