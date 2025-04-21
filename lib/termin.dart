///Klasse für Termin-Objekt
library;


class Termin {
  final String name;
  final DateTime startTime;
  final DateTime endTime;

  Termin({required this.name, required this.startTime, required this.endTime});

  @override
  String toString() {
    return "Termin(name: $name, startTime: $startTime, endTime: $endTime)";
  }
}

class Termin1 {
  String userName;
  String terminName;
  DateTime timeBegin;
  DateTime timeEnd;
  String comment;


  Termin1({
    required this.userName,
    required this.terminName,
    required this.timeBegin,
    required this.timeEnd,
    required this.comment,
  });

  @override
  String toString() {
    return "Termin(terminName: $terminName, timeBegin: $timeBegin, timeEnd: $timeEnd, userName: $userName)";
  }
}