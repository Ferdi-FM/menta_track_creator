import 'package:menta_track_creator/person.dart';
import 'package:menta_track_creator/termin.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, "person_plans_v1.db"),
      onCreate: (db, version) async {
        await db.execute('''
         CREATE TABLE Persons(
           id INTEGER PRIMARY KEY,
           name TEXT
         )
       ''');

        await db.execute('''
          CREATE TABLE createdPlans(
            id INTEGER PRIMARY KEY,
            personId INTEGER,
            startDate TEXT,
            endDate TEXT,
            FOREIGN KEY(personId) REFERENCES Persons(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE createdTermine(
            id INTEGER PRIMARY KEY,
            personId INTEGER,
            terminName TEXT,
            timeBegin TEXT,
            timeEnd TEXT,
            FOREIGN KEY(personId) REFERENCES Persons(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE comments(
            id INTEGER PRIMARY KEY,
            personId INTEGER,
            commentTitle TEXT,
            commentText TEXT,
            sortIndex INTEGER,
            FOREIGN KEY(personId) REFERENCES Persons(id)
          )
        ''');
      },
      version: 1,
    );
  }

  Future<void> updateComment(int personId, String title, String comment, String editTitle, String editComment) async {
    final db = await database;
    await db.update(
      "comments",
        {
          "commentTitle": editTitle,
          "commentText": editComment
        },
        where: "personId = ? AND commentTitle = ? AND commentText = ?",
        whereArgs: [personId,title,comment]);
  }

  Future<void> updateCommentList(int personId, List<Map<String,dynamic>> updatedList) async {
    final db = await database;
    final batch = db.batch();

    for (int i = 0; i < updatedList.length; i++){
      Map<String, dynamic> map = updatedList[i];
      String title = map["commentTitle"];
      String comment = map["commentText"];
      batch.update(
          "comments",
          {
            "sortIndex": i
          },
          where: "personId = ? AND commentTitle = ? AND commentText = ?",
          whereArgs: [personId,title,comment]
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getComment(int personId) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      "comments",
      where: "personId = ?",
      whereArgs: [personId],
    );
    return maps;
  }

  Future<void> insertComment(int personId, String title, String comment, int index) async {
    final db = await database;
    await db.insert(
      "comments",
      {
        "personId": personId,
        "commentTitle":title,
        "commentText":comment,
        "sortIndex": index
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

  }

  Future<void> deleteComment(int personId, String title, String comment) async {
    final db = await database;
    await db.delete (
      "comments",
      where: "personId = ? AND commentTitle = ? AND commentText = ?",
      whereArgs: [personId, title,comment]
    );
  }

  Future<void> insertPlan(DateTime startTime, DateTime endDate, int personId) async {
    final db = await database;
    await db.insert(
      "createdPlans",
      {
        "personId": personId,
        "startDate": startTime.toIso8601String(),
        "endDate": endDate.toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Termin>> getWeekPlan(int personId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    String startDateString = startDate.toIso8601String();
    DateTime endDateTime = DateTime(endDate.year,endDate.month,endDate.day,23,59,59);
    String endDateString = endDateTime.toIso8601String();
    List<Map<String, dynamic>> maps = await db.query(
      "createdTermine",
      where: "personId = ? AND (datetime(timeBegin) BETWEEN datetime(?) AND datetime(?))",
      whereArgs: [personId, startDateString, endDateString],
    );
    return toTerminList(maps);
  }
  
  List<Termin> toTerminList(List<Map<String, dynamic>> list){
    List<Termin> terminList = [];
    for(Map map in list){
      Termin t = Termin(
          name: map["terminName"], 
          startTime: DateTime.parse(map["timeBegin"]),
          endTime: DateTime.parse(map["timeEnd"]),
      );
      terminList.add(t);
    }
    return terminList;
  }

  Future<List<Map<String, dynamic>>> getPlans(int personId) async {
    final db = await database;
    List<Map<String,dynamic>> maps = await db.query(
      "createdPlans",
      where: "personId = ?",
      whereArgs: [personId],
    );

    return maps;
  }

  Future<void> insertTermin(Termin termin, int personId) async {
    final db = await database;

    //Erstellt die Tabelle mit dem ersten Tag der Woche in der Tabelle WeeklyPlans.
    await db.insert(
      "createdTermine",
      {
        "personId": personId,
        "terminName": termin.name,
        "timeBegin": termin.startTime.toIso8601String(),
        "timeEnd": termin.endTime.toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getTermine(DateTime startDate, DateTime endDate, String firstN) async {
    final db = await database;
    return await db.query("createdTermine");
  }

  Future<int> insertPerson(String name, String lastName) async {
    final db = await database;

    //Erstellt die Tabelle mit dem ersten Tag der Woche in der Tabelle WeeklyPlans.
    return await db.insert(
      "Persons",
      {"name": "$name $lastName"},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

  }

  Future<List<Person>> getPersons(String search) async {
    final db = await database;
    List<Map<String,dynamic>> maps = [];
    if(search == ""){
      maps = await db.query("Persons");
    } else {
      maps = await db.query(
          "Persons",
          where: "name LIKE ?",
          whereArgs: ["%$search%"]
      );
    }
    List<Person> personList = [];
    for(Map map in maps){
      Person p = Person(name: map["name"], id: map["id"]);
      personList.add(p);
    }
    return personList;
  }

  Future<void> updateTermin(int personId, Termin oldTermin, Termin updatedTermin) async {
    final db = await database;
    await db.update(
      "createdTermine",
      {
        "terminName": updatedTermin.name,
        "timeBegin": updatedTermin.startTime.toIso8601String(),
        "timeEnd": updatedTermin.endTime.toIso8601String()
      },
      where: "personId = ? AND terminName = ? AND timeBegin = ? AND timeEnd = ?",
      whereArgs: [personId, oldTermin.name, oldTermin.startTime.toIso8601String(), oldTermin.endTime.toIso8601String()],
    );
  }

  //Future<void> updatePerson(String oldFirstName, String oldLastName, String newFirstName, String newLastName) async {
  //  final db = await database;
  //  await db.update(
  //    "Persons",
  //    {"firstName": newFirstName, "lastName": newLastName},
  //    where: "firstName = ? AND lastName = ?",
  //    whereArgs: [oldFirstName, oldLastName],
  //  );
  //}

  Future<void> deleteTermin(int personId, Termin termin) async {
    final db = await database;
    await db.delete(
      "createdTermine",
      where: "personId = ? AND terminName = ? AND timeBegin = ? AND timeEnd = ?",
      whereArgs: [personId, termin.name, termin.startTime.toIso8601String(), termin.endTime.toIso8601String()],
    );
  }

  Future<void> deleteWeekPlan(DateTime startDate, DateTime endDate, int personId) async {
    final db = await database;
    await db.delete(
        "createdPlans",
        where: "personId = ? AND startDate = ? AND endDate = ?",
        whereArgs: [personId, startDate.toIso8601String(), endDate.toIso8601String()]
    );
    await db.delete(
        "createdTermine",
        where: """
              personId = ?
              AND datetime(?) >= datetime(timeBegin) 
              AND datetime(?) <= datetime(timeEnd)
            """,
        whereArgs: [personId, startDate.toIso8601String(), endDate.toIso8601String()]
    );
  }

  Future<void> deletePerson(int personId) async {
    final db = await database;
    await db.delete(
        "createdPlans",
        where: "personId = ?",
        whereArgs: [personId]
    );
    await db.delete(
        "createdTermine",
        where: "personId = ?",
        whereArgs: [personId]
    );
    await db.delete(
        "Persons",
        where: "personId = ?",
        whereArgs: [personId]
    );
  }

}