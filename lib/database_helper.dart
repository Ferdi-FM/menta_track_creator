import 'package:menta_track_creator/termin_dialogue.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'main.dart';


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
      join(path, "person_plans_ver3.db"),
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
            personName TEXT,
            startDate TEXT,
            endDate TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE createdTermine(
            id INTEGER PRIMARY KEY,
            personName TEXT,
            terminName TEXT,
            timeBegin TEXT,
            timeEnd TEXT
          )
        ''');
      },
      version: 2,
    );
  }



  Future<void> insertPlan(DateTime startTime, DateTime endDate, String name) async {
    final db = await database;
    await db.insert(
      "createdPlans",
      { "personName": name,
        "startDate": startTime.toIso8601String(),
        "endDate": endDate.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Termin>> getWeekPlan(String name, DateTime startDate, DateTime endDate) async {
    final db = await database;
    String startDateString = startDate.toIso8601String();
    String endDateString = endDate.toIso8601String();
    List<Map<String, dynamic>> maps = await db.query(
      "createdTermine",
      where: "personName = ? AND (datetime(timeBegin) BETWEEN datetime(?) AND datetime(?))",
      whereArgs: [name, startDateString, endDateString],
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

  Future<List<Map<String, dynamic>>> getPlans(String name) async {
    final db = await database;
    List<Map<String,dynamic>> maps = await db.query(
      "createdPlans",
      where: "personName = ?",
      whereArgs: [name],
    );

    return maps;
  }

  Future<void> insertTermin(Termin termin, String name) async {
    final db = await database;

    //Erstellt die Tabelle mit dem ersten Tag der Woche in der Tabelle WeeklyPlans.
    await db.insert(
      "createdTermine",
      {
        "personName": name,
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

  Future<void> insertPerson(String name, String lastName) async {
    final db = await database;

    //Erstellt die Tabelle mit dem ersten Tag der Woche in der Tabelle WeeklyPlans.
    await db.insert(
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
      Person p = Person(name: map["name"]);
      personList.add(p);
    }
    return personList;
  }

  Future<void> updateTermin(String userName, Termin oldTermin, Termin updatedTermin) async {
    final db = await database;
    await db.update(
      "createdTermine",
      {
        "terminName": updatedTermin.name,
        "timeBegin": updatedTermin.startTime.toIso8601String(),
        "timeEnd": updatedTermin.endTime.toIso8601String()
      },
      where: "personName = ? AND terminName = ? AND timeBegin = ? AND timeEnd = ?",
      whereArgs: [userName, oldTermin.name, oldTermin.startTime.toIso8601String(), oldTermin.endTime.toIso8601String()],
    );
  }

  Future<void> updatePerson(String oldFirstName, String oldLastName, String newFirstName, String newLastName) async {
    final db = await database;
    await db.update(
      "Persons",
      {"firstName": newFirstName, "lastName": newLastName},
      where: "firstName = ? AND lastName = ?",
      whereArgs: [oldFirstName, oldLastName],
    );
  }

  Future<void> deleteTermin(String name, Termin termin) async {
    final db = await database;
    await db.delete(
      "createdTermine",
      where: "personName = ? AND terminName = ? AND timeBegin = ? AND timeEnd = ?",
      whereArgs: [name, termin.name, termin.startTime.toIso8601String(), termin.endTime.toIso8601String()],
    );
  }

  Future<void> deleteWeekPlan(DateTime startDate, DateTime endDate, String name) async {
    final db = await database;
    await db.delete(
        "createdPlans",
        where: "personName = ? AND startDate = ? AND endDate = ?",
        whereArgs: [name, startDate.toIso8601String(), endDate.toIso8601String()]
    );
    await db.delete(
        "createdTermine",
        where: """
              personName = ?
              AND datetime(?) >= datetime(timeBegin) 
              AND datetime(?) <= datetime(timeEnd)
            """,
        whereArgs: [name, startDate.toIso8601String(), endDate.toIso8601String()]
    );
  }

  Future<void> deletePerson(String personName) async {
    final db = await database;
    await db.delete(
        "createdPlans",
        where: "personName = ?",
        whereArgs: [personName]
    );
    await db.delete(
        "createdTermine",
        where: "personName = ?",
        whereArgs: [personName]
    );
    await db.delete(
        "Persons",
        where: "name = ?",
        whereArgs: [personName]
    );
  }

}