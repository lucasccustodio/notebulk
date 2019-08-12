import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';

String formatTimestamp(DateTime timestamp, Localization localization,
    {bool includeDay = true, bool includeWeekDay = true}) {
  final day = timestamp.day;
  final weekDay = timestamp.weekday;
  final month = timestamp.month;
  final year = timestamp.year;
  final buffer = StringBuffer();

  if (includeWeekDay) {
    buffer.write('${localization.dayNames[weekDay - 1]}. ');
  }

  buffer.write('${localization.monthNames[month - 1]} ');

  if (includeDay) {
    buffer.write('$day, ');
  }

  buffer.write(year);

  return buffer.toString();
}

class Localization extends Component {
  factory Localization.en() => Localization._(
      showNotesTitle: 'My notes',
      archivedNotesTitle: 'Archived notes',
      searchNotesTitle: 'Search notes',
      settingsPageTitle: 'Settings',
      createNoteFeatureTitle: 'New note',
      editNoteFeatureTitle: 'Edit note',
      emptyNoteHint: "You don't have any notes right now.",
      emptyArchiveHint:
          'Your archived notes will end up here and can be later restored.',
      emptySearchHint: "Your search didn't find anything.",
      searchNotesHint: 'Search for tags',
      featureContentsHint: 'What is this note about?',
      featureContentsLabel: 'Contents',
      featureContentsError: "Can't be empty",
      defaultHelpTags: const ['Tips', 'Help', 'Information'],
      emptyNoteTodo: [
        ListItem('Make a new note using the + button on the right corner ;)')
      ],
      emptySearchTodo: [
        ListItem('Check the spelling and capitalization'),
        ListItem('Try another search term')
      ],
      featureTagItemLabel: 'Tag name',
      featureTodoItemLabel: 'Todo item name',
      featureImageCamera: 'Take a picture',
      featureImageGallery: 'Open gallery',
      featureImageLabel: 'Picture',
      featureTagsEnable: 'New tag',
      featureTagsLabel: 'Tags',
      featureTodoEnable: 'New todo item',
      featureTodoLabel: 'Todo list',
      saveChangesFeatureLabel: 'Save',
      settingsColorLabel: 'Theme color',
      settingsDarkModeLabel: 'Dark mode',
      settingsExportLabel: 'Export notes',
      settingsImportLabel: 'Import notes',
      archiveActionLabel: 'Archive',
      restoreActionLabel: 'Restore',
      deleteActionLabel: 'Delete',
      hideActionLabel: 'Hide',
      importingAlert: 'Importing notes...',
      exportMessage: 'Backup exported to SD card.',
      selectedLabel: 'selected',
      dayNames: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
      monthNames: const [
        'JANUARY',
        'FEBRUARY',
        'MARCH',
        'APRIL',
        'MAY',
        'JUNE',
        'JULY',
        'AUGUST',
        'SEPTEMBER',
        'OCTOBER',
        'NOVEMBER',
        'DECEMBER'
      ]);

  factory Localization.ptBR() => Localization._(
      showNotesTitle: 'Minhas notas',
      archivedNotesTitle: 'Notas arquivadas',
      searchNotesTitle: 'Pesquisar notas',
      settingsPageTitle: 'Configurações',
      createNoteFeatureTitle: 'Criar nota',
      editNoteFeatureTitle: 'Editar nota',
      emptyNoteHint: 'Você não possui nenhuma nota no momento.',
      emptyArchiveHint:
          'Suas notas arquivadas irão aparecer aqui e podem ser restauradas depois.',
      emptySearchHint: 'Sua pesquisa não retornou resultados',
      searchNotesHint: 'Pesquise por tags',
      featureContentsHint: 'Sobre o que é essa nota?',
      featureContentsLabel: 'Conteúdo da nota',
      featureContentsError: 'Não pode ficar vazio.',
      defaultHelpTags: const ['Dicas', 'Ajuda', 'Informativo'],
      emptyNoteTodo: [
        ListItem('Crie uma nota usando o botão + no canto direito ;)')
      ],
      emptySearchTodo: [
        ListItem('Procure erros de digitação e tente mudar a capitalização'),
        ListItem('Tente outro termo de pesquisa')
      ],
      featureTagItemLabel: 'Nome da tag',
      featureTodoItemLabel: 'Nome do item',
      featureImageCamera: 'Tirar uma foto',
      featureImageGallery: 'Selecionar da galeria',
      featureImageLabel: 'Imagem',
      featureTagsEnable: 'Nova tag',
      featureTagsLabel: 'Tags',
      featureTodoEnable: 'Novo item da lista',
      featureTodoLabel: 'Coisas a fazer',
      saveChangesFeatureLabel: 'Salvar',
      settingsColorLabel: 'Cor do tema',
      settingsDarkModeLabel: 'Modo escuro',
      settingsExportLabel: 'Exportar notas',
      settingsImportLabel: 'Importar notas',
      archiveActionLabel: 'Arquivar',
      restoreActionLabel: 'Restaurar',
      deleteActionLabel: 'Excluir',
      hideActionLabel: 'Fechar',
      importingAlert: 'Importando notas...',
      exportMessage: 'Backup exportado para o cartão SD.',
      selectedLabel: 'selecionada(s)',
      dayNames: const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'],
      monthNames: const [
        'JANEIRO',
        'FEVEREIRO',
        'MARÇO',
        'ABRIL',
        'MAIO',
        'JUNHO',
        'JULHO',
        'AGOSTO',
        'SETEMBRO',
        'OUTUBRO',
        'NOVEMBRO',
        'DEZEMBRO'
      ]);

  Localization._(
      {@required this.showNotesTitle,
      @required this.emptyNoteHint,
      @required this.emptyArchiveHint,
      @required this.emptyNoteTodo,
      @required this.emptySearchTodo,
      @required this.searchNotesTitle,
      @required this.searchNotesHint,
      @required this.emptySearchHint,
      @required this.defaultHelpTags,
      @required this.archivedNotesTitle,
      @required this.settingsPageTitle,
      @required this.settingsColorLabel,
      @required this.settingsDarkModeLabel,
      @required this.settingsExportLabel,
      @required this.settingsImportLabel,
      @required this.createNoteFeatureTitle,
      @required this.editNoteFeatureTitle,
      @required this.saveChangesFeatureLabel,
      @required this.featureContentsHint,
      @required this.featureContentsLabel,
      @required this.featureContentsError,
      @required this.featureTodoItemLabel,
      @required this.featureTagItemLabel,
      @required this.featureImageLabel,
      @required this.featureImageCamera,
      @required this.featureImageGallery,
      @required this.featureTodoLabel,
      @required this.featureTodoEnable,
      @required this.featureTagsLabel,
      @required this.featureTagsEnable,
      @required this.archiveActionLabel,
      @required this.restoreActionLabel,
      @required this.deleteActionLabel,
      @required this.hideActionLabel,
      @required this.selectedLabel,
      @required this.importingAlert,
      @required this.exportMessage,
      @required this.dayNames,
      @required this.monthNames});

  final String showNotesTitle;

  final String emptyNoteHint;

  final String emptyArchiveHint;

  final List<ListItem> emptyNoteTodo;
  final List<ListItem> emptySearchTodo;
  final String searchNotesTitle;
  final String searchNotesHint;
  final String emptySearchHint;
  final List<String> defaultHelpTags;
  final String archivedNotesTitle;
  final String settingsPageTitle;
  final String settingsColorLabel;
  final String settingsDarkModeLabel;
  final String settingsExportLabel;
  final String settingsImportLabel;
  final String createNoteFeatureTitle;
  final String editNoteFeatureTitle;
  final String saveChangesFeatureLabel;
  final String featureContentsLabel;
  final String featureContentsError;
  final String featureContentsHint;
  final String featureTodoItemLabel;
  final String featureTagItemLabel;
  final String featureImageLabel;
  final String featureImageCamera;
  final String featureImageGallery;
  final String featureTodoLabel;
  final String featureTodoEnable;
  final String featureTagsLabel;
  final String featureTagsEnable;
  final String archiveActionLabel;
  final String restoreActionLabel;
  final String deleteActionLabel;
  final String hideActionLabel;
  final List<String> dayNames;
  final List<String> monthNames;
  final String selectedLabel;
  final String importingAlert;
  final String exportMessage;
}

class Routes {
  static const String showNotes = 'showNotes';
  static const String createNote = 'createNote';
  static const String createList = 'createList';
  static const String editNote = 'editNote';
  static const String editList = 'editList';
  static const String takePicPage = 'takePic';
  static const String pickPicPage = 'pickPic';
  static const String errorPage = 'errorPage';
  static const String splashScreen = 'splashScreen';
  static const String testPage = 'testPage';
}
