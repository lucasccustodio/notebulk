import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notebulk/util.dart';
import 'package:path_provider/path_provider.dart';

class NoteFormFeature extends StatefulWidget {
  const NoteFormFeature({Key key, this.title}) : super(key: key);

  final String title;

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
    final response = await ImagePicker.retrieveLostData();

    if (response == null) {
      return;
    }
    if (response.file != null) {
      final em = EntityManagerProvider.of(context).entityManager;

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = await getExternalStorageDirectory();
      final newPath = '$path/Pictures/$timestamp.jpeg';
      response.file
        ..copySync(newPath)
        ..deleteSync();
      em.getUniqueEntity<FeatureEntityTag>().set(Picture(newPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;

    void closeFeature() {
      Navigator.of(context).pop(true);
    }

    return WillPopScope(
      onWillPop: () async {
        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(
                    'Salvar as alterações?',
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Não'),
                      onPressed: closeFeature,
                    ),
                    FlatButton(
                      child: Text('Sim'),
                      onPressed: () {
                        if (key.currentState.validate())
                          key.currentState.save();
                        else
                          return;

                        entityManager.setUnique(HasDataTag());
                        closeFeature();
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
                  leading: BackButton(),
                  backgroundColor: Colors.black54,
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
                ),
                SliverPadding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 4, bottom: 4),
                    sliver: SliverToBoxAdapter(
                      child: EntityObservingWidget(
                        provider: (em) =>
                            em.getUniqueEntity<FeatureEntityTag>(),
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
            buildTimestamp(timestamp),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Imagem'),
            ),
            buildPicField(noteEntity),
            buildContentsField(noteEntity),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Lista'),
            ),
            buildListField(noteEntity),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Tags'),
            ),
            buildTagsField(noteEntity),
          ],
        ),
      ),
    );
  }

  Widget buildTimestamp(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        formatTimestamp(timestamp),
        style: Theme.of(context).textTheme.title.copyWith(
            fontFamily: 'OpenSans', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget buildContentsField(Entity noteEntity) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: TextFormField(
        initialValue: noteEntity.get<Contents>()?.value ?? '',
        decoration: InputDecoration(
          hintText: 'Sobre o que é essa anotação?',
          labelText: 'Conteúdo',
        ),
        onSaved: (contents) => noteEntity.set(Contents(contents)),
        validator: (contents) =>
            contents.isEmpty ? 'Não pode ficar vazio.' : null,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget buildListField(Entity noteEntity) {
    final items = noteEntity.get<Todo>()?.value;

    if (items == null)
      return FlatButton.icon(
        icon: Icon(Icons.add),
        label: Text('Adicionar lista'),
        onPressed: () {
          noteEntity.set(Todo(value: [ListItem('')]));
        },
      );

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
                      hintText: 'Nome do item',
                      labelText: 'Item nº ${index + 1}',
                    ),
                    onSaved: (item) => noteEntity
                        .update<Todo>((old) => old..value[index].label = item),
                    style: Theme.of(context).textTheme.body1.copyWith(
                        decoration: items[index].isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none),
                  ),
                  secondary: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      noteEntity
                          .update<Todo>((old) => old..value.removeAt(index));
                    },
                  ),
                  onChanged: (value) => noteEntity.update<Todo>(
                      (old) => old..value[index].isChecked = value)),
            FlatButton.icon(
              icon: Icon(Icons.add),
              label: Text('Novo item da lista'),
              onPressed: () {
                noteEntity.update<Todo>((old) => old..value.add(ListItem('')));
              },
            )
          ]),
    );
  }

  Widget buildTagsField(Entity noteEntity) {
    final tags = noteEntity.get<Tags>()?.value;

    if (tags == null)
      return FlatButton.icon(
        icon: Icon(Icons.add),
        label: Text('Adicionar tag'),
        onPressed: () {
          noteEntity.set(Tags(const ['']));
        },
      );

    return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Wrap(
          children: <Widget>[
            for (int i = 0; i < tags.length; i++)
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    noteEntity.update<Tags>((old) => old..value.removeAt(i));
                  },
                ),
                title: TextFormField(
                  initialValue: tags[i],
                  decoration: InputDecoration(
                    hintText: 'Nome da tag',
                    labelText: 'Tag',
                  ),
                  onSaved: (tag) =>
                      noteEntity.update<Tags>((old) => old..value[i] = tag),
                  textAlign: TextAlign.left,
                ),
              ),
            FlatButton.icon(
              icon: Icon(Icons.add),
              label: Text('Nova tag'),
              onPressed: () {
                noteEntity.update<Tags>((old) => old..value.add(''));
              },
            )
          ],
        ));
  }

  Widget buildPicField(Entity noteEntity) {
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
                final newPath = '$path/Pictures/$timestamp.jpeg';
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
              final newPath = '$path/Pictures/$timestamp.jpeg';
              image..copySync(newPath)
              ..deleteSync();
              em.getUniqueEntity<FeatureEntityTag>().set(Picture(newPath));
            },
          )
        ],
      );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Image.file(picFile, fit: BoxFit.fill),
    );
  }
}
