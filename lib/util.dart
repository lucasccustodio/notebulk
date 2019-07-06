String formatTimestamp(DateTime timestamp) {
  //TODO: Move these somewhere else so it can be localized instead.
  final dayNames = ["SEG", "TER", "QUA", "QUI", "SEX", "SAB", "DOM"];
  final monthNames = [
    "JANEIRO",
    "FEVEREIRO",
    "MARÇO",
    "ABRIL",
    "MAIO",
    "JUNHO",
    "JULHO",
    "AGOSTO",
    "SETEMBRO",
    "OUTUBRO",
    "NOVEMBRO",
    "DEZEMBRO"
  ];

  var day = timestamp.day;
  var weekDay = timestamp.weekday;
  var month = timestamp.month;
  var year = timestamp.year;

  return "${dayNames[weekDay - 1]}. ${monthNames[month - 1]} $day, $year";
}
