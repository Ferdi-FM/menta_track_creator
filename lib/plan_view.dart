import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/create_qr_code.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/termin_create_page.dart';
import 'package:menta_track_creator/termin_dialogue.dart';
import 'package:time_planner/time_planner.dart';

import 'main.dart';

//Example-Code von: https://pub.dev/packages/time_planner/example

class PlanView extends StatefulWidget {
  const PlanView({
    super.key,
    required this.start,
    required this.end,
    required this.userName,
    this.scrollToSpecificDayAndHour
  });

  final DateTime start;
  final DateTime end;
  final String userName;
  final DateTime? scrollToSpecificDayAndHour;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<PlanView>{
  DateTime calendarStart = DateTime(0);
  List<TimePlannerTitle> calendarHeaders = [];
  List<TimePlannerTask> tasks = [];
  bool updated = false;
  int rememberAnsweredTasks = 0;
  bool hapticFeedback = false;
  int scrollToSpecificDay = 0;
  int scrollToSpecificHour = 0;

  @override
  void initState() {
    super.initState();
    setUpCalendar1(widget.start, widget.end);
  }

  void setUpCalendar(DateTime start, DateTime end) async{
    calendarStart = start;
    int timeperiodInDays = end.difference(start).inDays;
    calendarHeaders = [];

    for(int i = 0; i < timeperiodInDays;i++){
      DateTime date = calendarStart.add(Duration(days: i));
      String displayDate = DateFormat("dd.MM.yy").format(date);
      String weekDay = getWeekdayName(date);
      calendarHeaders.add(
          TimePlannerTitle(
            title: weekDay,
            date: displayDate,
            voidAction: clickOnCalendarHeader,
          ));
    }
  }

  ///Setup vom Kalendar und den Einträgen
  void setUpCalendar1(DateTime start, DateTime end) async{
    DatabaseHelper databaseHelper = DatabaseHelper();
    calendarStart = start;
    int timeperiodInDays = end.difference(start).inDays;
    calendarHeaders = [];
    calendarHeaders = [];

    if(widget.scrollToSpecificDayAndHour != null){
      scrollToSpecificHour = widget.scrollToSpecificDayAndHour!.hour;
      scrollToSpecificDay = widget.scrollToSpecificDayAndHour!.difference(calendarStart).inDays;
    }

    ///Erstellt die Köpfe der einzelnen Spalten
    for(int i = 0; i < timeperiodInDays+1;i++){
      DateTime date = calendarStart.add(Duration(days: i));
      String displayDate = DateFormat("dd.MM.yy").format(date);
      String weekDay = getWeekdayName(date);
      calendarHeaders.add(
          TimePlannerTitle(
            title: weekDay,
            date: displayDate,
            displayDate: displayDate,
            voidAction: clickOnCalendarHeader,
          ));
    }

    List<Termin> weekAppointments = await databaseHelper.getWeekPlan(widget.userName, widget.start, widget.end);
    // Liste für Gruppen von überschneidenden Terminen
    List<List<String>> overlapGroups = [];
    Set<String> groupedTerminNames = {};

    // Funktion, um zu überprüfen, ob zwei Termine sich überschneiden
    bool isOverlapping(Termin t1, Termin t2) {
      return t1.startTime.isBefore(t2.endTime) && t1.endTime.isAfter(t2.startTime);
    }

    // Gruppierung der Termine
    for (var t1 in weekAppointments) {
      String t1SafeName = "${t1.name}${t1.startTime.toIso8601String()}";
      if (groupedTerminNames.contains(t1SafeName)) continue;

      // Neue Gruppe mit t1 starten
      List<String> currentGroup = [t1SafeName];
      Queue<Termin> toCheck = Queue.of([t1]);

      while (toCheck.isNotEmpty) {
        var current = toCheck.removeFirst();
        String currentSafeName = "${current.name}${current.startTime.toIso8601String()}"; //Unique String zum Vergleichen

        for (var t2 in weekAppointments) {
          String t2SafeName = "${t2.name}${t2.startTime.toIso8601String()}";

          if (groupedTerminNames.contains(t2SafeName) || currentSafeName == t2SafeName) continue;

          if (isOverlapping(current, t2)) {
            if(!currentGroup.contains(t2SafeName)){
              currentGroup.add(t2SafeName);
            }
            groupedTerminNames.add(t2SafeName);
            toCheck.add(t2);
          }
        }
      }

      // Gruppe nur hinzufügen, wenn sie mehr als einen Termin enthält
      if (currentGroup.length > 1) {
        overlapGroups.add(currentGroup);
      }

      // Ursprünglichen Termin als verarbeitet markieren
      groupedTerminNames.add(t1SafeName);
    }

    for (Termin t in weekAppointments) {
      String title = t.name;
      DateTime startTime = t.startTime;
      DateTime endTime = t.endTime;


      int overlapPos =  0;
      int overlapOffset = 0;
      String safeName = "${t.name}${t.startTime.toIso8601String()}";
      for (var group in overlapGroups) {
        if(group.contains(safeName)){
          overlapPos = group.length;
          overlapOffset = group.indexOf(safeName);
        }
      }

      _addObject(title, startTime, endTime, overlapPos, overlapOffset);
    }
  }

  void clickOnCalendarHeader(String dateString){
  }

  void updateCalendar() {
    setState(() {
      tasks.clear();
    });
    setUpCalendar1(widget.start,widget.end);
  }


  String getWeekdayName(DateTime dateTime) {
    List<String> weekdays = [
      "Montag",
      "Dienstag",
      "Mittwoch",
      "Donnerstag",
      "Freitag",
      "Samstag",
      "Sonntag"
    ];
    return weekdays[dateTime.weekday - 1]; //-1 weil index bei 0 beginnt aber weekday bei 1 beginnt
  }

  //Konvertiert eine DateTime zu der vom package erwartetem Format (integer). errechnet differenz zwischen der 0ten Stunde am Kalender und dem Termin
  Map<String, int> convertToCalendarFormat(DateTime calendarStart, DateTime terminDate) {
    Duration difference = terminDate.difference(calendarStart);

    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;

    return {
      "Days": days,
      "Hours": hours,
      "Minutes": minutes,
    };
  }

  //erzeugt Event im Kalender
  void _addObject(String title, DateTime startTime, DateTime endTime, int numberofOverlaps, int overlapOffset) { //
    Map<String, int> convertedDate = convertToCalendarFormat(calendarStart, startTime);
    int day = convertedDate["Days"]!;
    int hour = convertedDate["Hours"]!;
    int minutes = convertedDate["Minutes"]!;
    int duration = endTime.difference(startTime).inMinutes;
    //if(color == Colors.lightGreen) rememberAnsweredTasks += 1; //Merkt sich, wieviele Taks geantwortet wurden

    int textheight = duration - 24;

    setState(() {
      tasks.add(
          TimePlannerTask(
            color: Colors.white70,
            dateTime: TimePlannerDateTime(
                day: day,
                hour: hour,
                minutes: minutes),
            minutesDuration: duration,
            numOfOverlaps: numberofOverlaps,
            overLapOffset: overlapOffset,
            daysDuration: 1,
            child:
            GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (event) async {
                  Offset pos = event.globalPosition;
                  Termin oldTermin = Termin(name: title, startTime: startTime, endTime: endTime);
                  final result = await Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => TerminCreatePage(
                            startDate: widget.start,
                            endDate: widget.end,
                          userName: widget.userName,
                          terminToUpdate: true,
                          existingStartTime: startTime,
                          existingEndTime: endTime,
                          existingName: title,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const curve = Curves.easeInOut;
                          var tween = Tween<double>(begin: 0.1, end: 1.0).chain(CurveTween(curve: curve));
                          var scaleAnimation = animation.drive(tween);
                          return ScaleTransition(
                            scale: scaleAnimation,
                            alignment: Alignment(pos.dx / MediaQuery.of(context).size.width * 2 - 1,
                                pos.dy / MediaQuery.of(context).size.height * 2 - 1), // Die Tap-Position relativ zur Bildschirmgröße
                            child: child,
                          );},
                      )
                  );
                  if(result != null){
                    if(result == true) {
                    } else {
                      await DatabaseHelper().updateTermin(widget.userName, oldTermin, result);
                    }
                    updateCalendar();
                  }
                },
                child: Stack( //Uhrzeit und Text könnten bei zu kurzen Terminen überlappen
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                        top: -6,
                        right: -3,
                        child: SizedBox(),//Icon(color == Colors.blueGrey.shade200 ? Icons.priority_high : null)
                    ),
                    ///Start and Endzeit, beide, damit falls sich einträge Überlappen, sie auseinandergehalten werden können
                    Positioned(
                      top: 1,
                      left: 5,
                      child: Text(DateFormat("HH:mm").format(startTime), style: TextStyle(fontWeight: FontWeight.w200, color: Colors.black87, fontStyle: FontStyle.italic, fontSize: duration/8 < 10 ? duration/8 : 9,),), //Ursprünglich 7 : 9
                    ),
                    Positioned(
                      bottom: 1,
                      left: 5,
                      child: Text(DateFormat("HH:mm").format(endTime), style: TextStyle(fontWeight: FontWeight.w200, color: Colors.black87, fontStyle: FontStyle.italic,  fontSize: duration/8 < 10 ? duration/8 : 9),), //${DateFormat("HH:mm").format(startTime)} -
                    ),
                    Container(
                      height: textheight.toDouble(),
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(left: 10, right: 10, bottom: duration > 30 ? 12: duration/3, top: duration > 30 ? 10 : duration/4), //Ursprünglich 8 : 12
                      child: Text(
                        overflow: TextOverflow.ellipsis,
                        maxLines: (duration/30).toInt(),
                        title,
                        style: TextStyle(
                          fontSize: duration > 30 ? 10 : duration/7,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                )
            ),
          )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit:BoxFit.contain,child: Text("${DateFormat("dd.MM.yy").format(widget.start)} - ${DateFormat("dd.MM.yy").format(widget.end)}", style: TextStyle(fontSize: 25, color: Theme.of(context).appBarTheme.foregroundColor),)),
        centerTitle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15))),
        actions: [
          Padding( //Nicht die Funktion aus Utilities, da ich auf hinzufügen von Eintrag reagieren muss, was nicht durch RouteAware/DidPopNext aufgefangen wird
            padding: EdgeInsets.only(right: 5),
            child: MenuAnchor(
                menuChildren: <Widget>[
                  MenuItemButton(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.help_rounded),
                          SizedBox(width: 10),
                          Text("QR-Code generieren")
                        ],
                      ),
                    ),
                    onPressed: () async {
                      List<Termin> terminList = await DatabaseHelper().getWeekPlan(widget.userName, widget.start, widget.end);
                      if(context.mounted){
                        CreateQRCode().showQrCode(context, terminList);
                      }
                    },
                  ),
                ],
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return TextButton(
                    focusNode: FocusNode(),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: Icon(Icons.menu, size: 30, color: Theme.of(context).appBarTheme.foregroundColor),
                  );
                }
            ),
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints){
        bool isPortrait = constraints.maxWidth < 600;
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20)),
              color: Theme.of(context).scaffoldBackgroundColor
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 0, right: 0),
            child: TimePlanner( //index startet bei 0, 0-23 ist also 24/7
              startHour: 0,
              endHour: 23,
              use24HourFormat: true,
              setTimeOnAxis: true,
              currentTimeAnimation: true,
              animateToDefinedHour: scrollToSpecificHour,
              animateToDefinedDay: scrollToSpecificDay,
              style: TimePlannerStyle(
                cellHeight: 60,
                cellWidth:  isPortrait ? 125 : ((MediaQuery.of(context).size.width - 60)/7).toInt(), //leider nur wenn neu gebuildet wird
                showScrollBar: true,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                interstitialEvenColor: MyApp.of(context).themeMode == ThemeMode.light ? Colors.grey[50] : Colors.blueGrey.shade400,
                interstitialOddColor: MyApp.of(context).themeMode == ThemeMode.light ? Colors.grey[200] : Colors.blueGrey.shade500,
              ),
              headers: calendarHeaders,
              tasks: tasks,
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TerminCreatePage(
                  startDate: widget.start,
                  endDate: widget.end,
                  userName: widget.userName,
                  terminToUpdate: false,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              )
          );
          if(result != null){
            //DatabaseHelper().insertTermin(result, widget.userName);
            updateCalendar();
          }

        },
        child: FittedBox( //Damit bei unterschiedlichen Displaygrößen die Icongröße nicht Über den Button ragt
          fit: BoxFit.fitHeight,
          child: Icon(Icons.add_task, size: 28),
        ),
      ),
    );
  }
}



