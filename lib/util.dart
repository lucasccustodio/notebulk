import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final String emptyNoteHintTitle;
  final String emptyNoteHintSubtitle;
  final String emptyArchiveHintTitle;
  final String emptyArchiveHintSubtitle;
  final String searchNotesHint;
  final String emptySearchHintTitle;
  final String emptySearchHintSubTitle;
  final String settingsPageTitle;
  final String settingsColorLabel;
  final String settingsDarkModeLabel;
  final String completedRemindersLabel;
  final String settingsExportLabel;
  final String settingsImportLabel;
  final String createNoteFeatureTitle;
  final String createEventFeatureTitle;
  final String editNoteFeatureTitle;
  final String editEventFeatureTitle;
  final String saveChangesFeatureLabel;
  final String featureContentsLabel;
  final String featureContentsError;
  final String featureContentsHint;
  final String featureTodoHint;
  final String featureTagsHint;
  final String featureImageLabel;
  final String featureImageCamera;
  final String featureImageGallery;
  final String featureTodoLabel;
  final String featureReminderHint;
  final String featurePriorityLabel;
  final String lateRemindersLabel;
  final String featureTagsLabel;
  final String currentRemindersLabel;
  final String archiveActionLabel;
  final String restoreActionLabel;
  final String deleteActionLabel;
  final String completeActionLabel;
  final String hideActionLabel;
  final List<String> dayNames;
  final List<String> monthNames;
  final String importedAlert;
  final String exportedAlert;
  final List<String> pageLabels;
  final String yes;
  final String no;
  final String cancel;
  final String accept;
  final String promptLeaveApp;
  final String promptLeaveUnsaved;
  final String currentRemindersEmpty,
      lateRemindersEmpty,
      completedRemindersEmpty;

  final String selectedLabel;

  factory Localization.en() => Localization._(
          yes: 'Yes',
          no: 'No',
          cancel: 'Cancel',
          accept: 'Accept',
          promptLeaveApp: 'Wanna close the app?',
          promptLeaveUnsaved:
              'You have changes pending to be saved. Leave without makings changes?',
          settingsPageTitle: 'Settings',
          createNoteFeatureTitle: 'New note',
          createEventFeatureTitle: 'New reminder',
          editNoteFeatureTitle: 'Edit note',
          editEventFeatureTitle: 'Edit reminder',
          emptyNoteHintTitle: "You don't have any notes right now.",
          emptyNoteHintSubtitle: 'Create one using the button bellow.',
          emptyArchiveHintTitle: 'Currently empty',
          emptyArchiveHintSubtitle:
              'Your archived notes will end up here and can be later restored.',
          emptySearchHintTitle: "Your search didn't find anything.",
          emptySearchHintSubTitle:
              'Try other terms or fix spelling errors if any.',
          searchNotesHint: 'Search for multiple tags ie: Work important etc.',
          featureContentsHint: 'What is this note about?',
          featureContentsLabel: 'Contents',
          featureContentsError: "Can't be empty",
          currentRemindersEmpty: 'Nothing happening right now',
          lateRemindersEmpty: 'Everything\'s in order!',
          completedRemindersEmpty:
              'Remember to complete or update your late reminders.',
          featureTagsHint: 'Ie: Work, Important, etc.',
          featureTodoHint:
              'Make lists by breaking the line and mark as checked by inserting * in the end of an item ie: Buy rice*',
          featureImageCamera: 'Take a picture',
          featureImageGallery: 'Open gallery',
          featureImageLabel: 'Picture',
          currentRemindersLabel: 'Current',
          featureTagsLabel: 'Tags',
          lateRemindersLabel: 'Late',
          featureTodoLabel: 'Todo list',
          featurePriorityLabel: 'Priority',
          featureReminderHint: 'What you want to remember?',
          saveChangesFeatureLabel: 'Save',
          settingsColorLabel: 'Theme color',
          settingsDarkModeLabel: 'Dark mode',
          completedRemindersLabel: 'Completed',
          settingsExportLabel: 'Export notes',
          settingsImportLabel: 'Import notes',
          archiveActionLabel: 'Archive',
          restoreActionLabel: 'Restore',
          deleteActionLabel: 'Delete',
          hideActionLabel: 'Hide',
          completeActionLabel: 'Complete',
          importedAlert: 'Backup restored succesfuly!',
          exportedAlert: 'Backup exported to SD card',
          selectedLabel: 'Apply to selection:',
          pageLabels: const [
            'My notes',
            'Reminders',
            'Search',
            'Archive'
          ],
          dayNames: const [
            'MON',
            'TUE',
            'WED',
            'THU',
            'FRI',
            'SAT',
            'SUN'
          ],
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
          yes: 'Sim',
          no: 'Não',
          cancel: 'Cancelar',
          accept: 'Aceitar',
          promptLeaveApp: 'Deseja sair do app?',
          promptLeaveUnsaved:
              'Você tem alterações pendentes à salvar. Quer Sair sem salvar as alterações?',
          emptySearchHintSubTitle:
              'Tente outros termos ou procure por erros de digitação.',
          emptyArchiveHintSubtitle: 'Suas notas arquivadas irão aparecer aqui.',
          emptyNoteHintSubtitle: 'Crie uma usando o botão no canto inferior.',
          settingsPageTitle: 'Configurações',
          createNoteFeatureTitle: 'Criar nota',
          createEventFeatureTitle: 'Criar lembrete',
          editNoteFeatureTitle: 'Editar nota',
          editEventFeatureTitle: 'Editar lembrete',
          emptyNoteHintTitle: 'Você não possui nenhuma nota no momento',
          emptyArchiveHintTitle: 'Nenhuma nota arquivada',
          emptySearchHintTitle: 'Sua pesquisa não retornou resultados',
          searchNotesHint: 'Ex: Trabalho importante etc.',
          featureContentsHint: 'Sobre o que é essa nota?',
          featureContentsLabel: 'Conteúdo da nota',
          featureContentsError: 'Não pode ficar vazio.',
          currentRemindersEmpty: 'Nada acontecendo no momento',
          lateRemindersEmpty: 'Tudo em ordem!',
          completedRemindersEmpty:
              'Não esqueça de completar ou atualizar os lembretes que atrasarem.',
          featureTagsHint:
              'Separe as tags por vírgulas quando houver mais de uma ex: Trabalho, Importante, etc.',
          featureTodoHint:
              'Crie items da lista quebrando a linha e marque como finalizado colocando * no final ex: Comprar arroz*',
          featureImageCamera: 'Tirar uma foto',
          featureImageGallery: 'Selecionar da galeria',
          featureImageLabel: 'Imagem',
          currentRemindersLabel: 'Atuais',
          featureTagsLabel: 'Tags',
          lateRemindersLabel: 'Em atraso',
          featureTodoLabel: 'Coisas a fazer',
          featurePriorityLabel: 'Prioridade',
          featureReminderHint: 'O que gostaria de lembrar?',
          saveChangesFeatureLabel: 'Salvar',
          settingsColorLabel: 'Cor do tema',
          settingsDarkModeLabel: 'Modo escuro',
          completedRemindersLabel: 'Concluídos',
          settingsExportLabel: 'Exportar notas',
          settingsImportLabel: 'Importar notas',
          archiveActionLabel: 'Arquivar',
          restoreActionLabel: 'Restaurar',
          deleteActionLabel: 'Excluir',
          hideActionLabel: 'Fechar',
          completeActionLabel: 'Concluir',
          importedAlert: 'Backup restaurado com sucesso!',
          exportedAlert: 'Backup exportado para o cartão SD',
          selectedLabel: 'Aplicar à seleção:',
          pageLabels: const [
            'Notas',
            'Lembretes',
            'Pesquisa',
            'Arquivo'
          ],
          dayNames: const [
            'SEG',
            'TER',
            'QUA',
            'QUI',
            'SEX',
            'SAB',
            'DOM'
          ],
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
      {@required this.featureReminderHint,
      @required this.featurePriorityLabel,
      @required this.completeActionLabel,
      @required this.emptyNoteHintSubtitle,
      @required this.emptyArchiveHintSubtitle,
      @required this.emptySearchHintSubTitle,
      @required this.currentRemindersEmpty,
      @required this.lateRemindersEmpty,
      @required this.completedRemindersEmpty,
      @required this.yes,
      @required this.no,
      @required this.cancel,
      @required this.accept,
      @required this.promptLeaveApp,
      @required this.promptLeaveUnsaved,
      @required this.emptyNoteHintTitle,
      @required this.emptyArchiveHintTitle,
      @required this.searchNotesHint,
      @required this.emptySearchHintTitle,
      @required this.settingsPageTitle,
      @required this.settingsColorLabel,
      @required this.settingsDarkModeLabel,
      @required this.completedRemindersLabel,
      @required this.settingsExportLabel,
      @required this.settingsImportLabel,
      @required this.createNoteFeatureTitle,
      @required this.createEventFeatureTitle,
      @required this.editNoteFeatureTitle,
      @required this.editEventFeatureTitle,
      @required this.saveChangesFeatureLabel,
      @required this.featureContentsHint,
      @required this.featureContentsLabel,
      @required this.featureContentsError,
      @required this.featureTodoHint,
      @required this.featureTagsHint,
      @required this.featureImageLabel,
      @required this.featureImageCamera,
      @required this.featureImageGallery,
      @required this.featureTodoLabel,
      @required this.lateRemindersLabel,
      @required this.featureTagsLabel,
      @required this.currentRemindersLabel,
      @required this.archiveActionLabel,
      @required this.restoreActionLabel,
      @required this.deleteActionLabel,
      @required this.hideActionLabel,
      @required this.selectedLabel,
      @required this.importedAlert,
      @required this.exportedAlert,
      @required this.dayNames,
      @required this.monthNames,
      @required this.pageLabels});
}

class Routes {
  static const String showNotes = 'showNotes';
  static const String createNote = 'createNote';
  static const String editNote = 'editNote';
  static const String splashScreen = 'splashScreen';
  static const String createReminder = 'createReminder';
  static const String editReminder = 'editReminder';
}
