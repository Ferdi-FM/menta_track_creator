import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/create_qr_code.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/person.dart';
import 'package:menta_track_creator/termin.dart';
import 'package:menta_track_creator/termin_create_page.dart';
import 'package:time_planner/time_planner.dart';
import 'generated/l10n.dart';
import 'main.dart';

class PlanView extends StatefulWidget {
  const PlanView({
    super.key,
    required this.start,
    required this.end,
    required this.person,
    this.scrollToSpecificDayAndHour
  });

  final DateTime start;
  final DateTime end;
  final Person person;
  final DateTime? scrollToSpecificDayAndHour;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<PlanView>{
  DateTime _calendarStart = DateTime(0);
  List<TimePlannerTitle> _calendarHeaders = [];
  final List<TimePlannerTask> _tasks = [];
  int _scrollToSpecificDay = 0;
  int _scrollToSpecificHour = 0;
  bool _loaded = false;
  List<List<String>> _overlapGroups = [];
  List<Termin> _weekAppointments = [];
  bool _blockScroll = false;
  double _overallZoom = 1;

  @override
  void initState() {
    super.initState();
    setUpCalendar1(widget.start, widget.end);
  }

  ///Setup vom Kalendar und den Einträgen
  void setUpCalendar1(DateTime start, DateTime end) async{
    DatabaseHelper databaseHelper = DatabaseHelper();
    _calendarStart = start;
    int timePeriodInDays = end.difference(start).inDays;
    _calendarHeaders = [];
    _calendarHeaders = [];

    if(widget.scrollToSpecificDayAndHour != null){
      _scrollToSpecificHour = widget.scrollToSpecificDayAndHour!.hour;
      _scrollToSpecificDay = widget.scrollToSpecificDayAndHour!.difference(_calendarStart).inDays;
    }

    ///Erstellt die Köpfe der einzelnen Spalten
    for(int i = 0; i < timePeriodInDays+1;i++){
      DateTime date = _calendarStart.add(Duration(days: i));
      String displayDate = DateFormat("dd.MM.yy").format(date);
      String weekDay = Utilities().getWeekDay(date.weekday,false);
      _calendarHeaders.add(
          TimePlannerTitle(
            title: weekDay,
            date: displayDate,
            displayDate: displayDate,
            voidAction: clickOnCalendarHeader,
          ));
    }

    _weekAppointments = await databaseHelper.getWeekPlan(widget.person.id, widget.start, widget.end);
    // Liste für Gruppen von überschneidenden Terminen
    _overlapGroups = [];
    Set<String> groupedTerminNames = {};

    // Funktion, um zu überprüfen, ob zwei Termine sich überschneiden
    bool isOverlapping(Termin t1, Termin t2) {
      return t1.startTime.isBefore(t2.endTime) && t1.endTime.isAfter(t2.startTime);
    }

    // Gruppierung der Termine
    for (var t1 in _weekAppointments) {
      String t1SafeName = "${t1.name}${t1.startTime.toIso8601String()}";
      if (groupedTerminNames.contains(t1SafeName)) continue;

      // Neue Gruppe mit t1 starten
      List<String> currentGroup = [t1SafeName];
      Queue<Termin> toCheck = Queue.of([t1]);

      while (toCheck.isNotEmpty) {
        var current = toCheck.removeFirst();
        String currentSafeName = "${current.name}${current.startTime.toIso8601String()}"; //Unique String zum Vergleichen

        for (var t2 in _weekAppointments) {
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
        _overlapGroups.add(currentGroup);
      }

      // Ursprünglichen Termin als verarbeitet markieren
      groupedTerminNames.add(t1SafeName);
    }
    for (Termin t in _weekAppointments) {
      String title = t.name;
      DateTime startTime = t.startTime;
      DateTime endTime = t.endTime;


      int overlapPos =  0;
      int overlapOffset = 0;
      String safeName = "${t.name}${t.startTime.toIso8601String()}";
      for (var group in _overlapGroups) {
        if(group.contains(safeName)){
          overlapPos = group.length;
          overlapOffset = group.indexOf(safeName);
        }
      }
      _addObject(title, startTime, endTime, overlapPos, overlapOffset);
    }

    setState(() {
      _loaded = true;
    });
  }

  void clickOnCalendarHeader(String dateString){
    setState(() {
      cellHeight = 120;
    });
  }

  void updateCalendar() {
    setState(() {
      _tasks.clear();
    });
    setUpCalendar1(widget.start,widget.end);
  }

  ///Update wenn keine neuen Tasks hinzukommen
  void updateTasks(){
    setState(() {
      _tasks.clear();
      for (Termin t in _weekAppointments) {
        String title = t.name;
        DateTime startTime = t.startTime;
        DateTime endTime = t.endTime;

        int overlapPos =  0;
        int overlapOffset = 0;
        String safeName = "${t.name}${t.startTime.toIso8601String()}";
        for (var group in _overlapGroups) {
          if(group.contains(safeName)){
            overlapPos = group.length;
            overlapOffset = group.indexOf(safeName);
          }
        }
        _addObject(title, startTime, endTime, overlapPos, overlapOffset);
      }
    });
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
      "startsOutSideOfWeek": difference.isNegative ? -1 : 1,
    };
  }

  //erzeugt Event im Kalender
  //Sehr uneleagnt
  void _addObject(String title, DateTime startTime, DateTime endTime, int numberofOverlaps, int overlapOffset) { //
    Map<String, int> convertedDate = convertToCalendarFormat(_calendarStart, startTime);
    List<int> dayList = [convertedDate["Days"]!];
    List<int> hourList = [convertedDate["Hours"]!];
    List<int> minuteList = [convertedDate["Minutes"]!];
    List<int> durationList = [endTime.difference(startTime).inMinutes];
    if(startTime.day != endTime.day){
      dayList.clear(); hourList.clear(); minuteList.clear(); durationList.clear();
      DateTime midNightNewDay = DateTime(endTime.year,endTime.month,endTime.day);
      ///Erster Teil des Termins
      durationList.add(midNightNewDay.difference(startTime).inMinutes);
      //Es wird gecheckt, ob der Termin außerhalb der Range startet
      convertedDate["startsOutSideOfWeek"] == 1 ? dayList.add(convertedDate["Days"]!): dayList.add(0);
      convertedDate["startsOutSideOfWeek"] == 1 ? hourList.add(convertedDate["Hours"]!): hourList.add(0);
      convertedDate["startsOutSideOfWeek"] == 1 ? minuteList.add(convertedDate["Minutes"]!): minuteList.add(0);
      ///Zweiter Teil des Termins
      Map<String, int> convertedSecondDate = convertToCalendarFormat(_calendarStart, midNightNewDay);
      durationList.add(endTime.difference(midNightNewDay).inMinutes);
      dayList.add(convertedSecondDate["Days"]!);
      hourList.add(convertedSecondDate["Hours"]!);
      minuteList.add(convertedSecondDate["Minutes"]!);
    }
    for(int i = 0; i < dayList.length; i++){
      int duration = durationList[i];
      if(duration.isNegative){
        Termin toDeleteTermin = Termin(name: title, startTime: startTime, endTime: endTime);
        DatabaseHelper().deleteTermin(widget.person.id, toDeleteTermin);
        Utilities().showSnackBar(context, S.current.week_view_wrong);
        return;
      }
      double fontSize = min(cellHeight * 0.25, duration * cellHeight * 0.01);
      fontSize = fontSize.clamp(7.0, 14.0);
      setState(() {
        _tasks.add(
            TimePlannerTask(
              color: Colors.white70,
              dateTime: TimePlannerDateTime(
                  day: dayList[i],
                  hour: hourList[i],
                  minutes: minuteList[i]),
              minutesDuration: durationList[i],
              numOfOverlaps: numberofOverlaps,
              overLapOffset: overlapOffset,
              daysDuration: 1,
              borderRadius: dayList.length > 1 ? i == 0 ? BorderRadius.vertical(top: Radius.circular(5)) : BorderRadius.vertical(bottom: Radius.circular(5)) : null,
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
                            personId: widget.person.id,
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
                        await DatabaseHelper().updateTermin(widget.person.id, oldTermin, result);
                      }
                      updateCalendar();
                    }
                  },
                  child: SizedBox(
                      height: cellHeight.toDouble()*duration/60,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -6,
                            right: -3,
                            child: SizedBox(),
                          ),
                          ///Start and Endzeit, beide, damit falls sich einträge Überlappen, sie auseinandergehalten werden können
                          Positioned(
                            top: 1,
                            left: 5,
                            child: ((dayList.length == 2 && i == 0)  || dayList.length == 1) ? Text(DateFormat("HH:mm").format(startTime), style: TextStyle(fontWeight: FontWeight.w200, color: Colors.black87, fontStyle: FontStyle.italic, fontSize: cellHeight*duration/60 < 40 ? fontSize.clamp(2, 6) : fontSize.clamp(4, 9),),) : Text(""), //Ursprünglich 7 : 9
                          ),
                          Positioned(
                            bottom: 1,
                            left: 5,
                            child: ((dayList.length == 2 && i == 1) || dayList.length == 1) ? Text(DateFormat("HH:mm").format(endTime), style: TextStyle(fontWeight: FontWeight.w200, color: Colors.black87, fontStyle: FontStyle.italic,  fontSize: cellHeight*duration/60 < 40 ? fontSize.clamp(2, 6) : fontSize.clamp(4, 9)),): Text(""), //${DateFormat("HH:mm").format(startTime)} -
                          ),
                          Align(
                            alignment: Alignment.center,
                            //smargin: EdgeInsets.only(left: 10, right: 10, bottom: duration > 30 ? 12: duration/1, top: duration > 30 ? 10 : duration/1), //Ursprünglich 8 : 12
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: cellHeight*duration/60 < 40 ? fontSize.clamp(0, 4) : 10),
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                maxLines: (duration/30).toInt() == 0 ? 1 : (duration/30).toInt(),
                                title,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          )
                        ],
                      ))
              ),
            )
        );
      }
      );
    }
  }

  int cellHeight = 60;
  TimePlanner createTimePlaner(int cellHeight, int cellWidth, bool blockScroll){
    return TimePlanner( //index startet bei 0, 0-23 ist also 24/7
      key: UniqueKey(),
      blockScroll: blockScroll,
      startHour: 0,
      endHour: 23,
      use24HourFormat: true,
      setTimeOnAxis: true,
      currentTimeAnimation: true,
      animateToDefinedHour: _scrollToSpecificHour,
      animateToDefinedDay: _scrollToSpecificDay,
      style: TimePlannerStyle(
        cellHeight: cellHeight,
        cellWidth:  cellWidth, //leider nur wenn neu gebuildet wird
        showScrollBar: true,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        interstitialEvenColor: MyApp.of(context).themeMode == ThemeMode.light ? Colors.grey[50] : Colors.blueGrey.shade400,
        interstitialOddColor: MyApp.of(context).themeMode == ThemeMode.light ? Colors.grey[200] : Colors.blueGrey.shade500,
      ),
      headers: _calendarHeaders,
      tasks: _tasks,
      tapOnEmptyField: (day, hour)async{
        DateTime clickedTime = widget.start.add(Duration(days: day, hours: hour));
        final result = await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => TerminCreatePage(
                startDate: widget.start,
                endDate: widget.end,
                personId: widget.person.id,
                existingStartTime: clickedTime,
                existingEndTime: clickedTime.add(Duration(hours: 1)),
                existingName: "",
                existingIndex: day,
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
          updateCalendar();
        }
      },
    );
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
          Padding(
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
                          Text(S.current.generate_qrCode)
                        ],
                      ),
                    ),
                    onPressed: () async {
                      List<Termin> terminList = await DatabaseHelper().getWeekPlan(widget.person.id, widget.start, widget.end);
                      if(context.mounted){
                        CreateQRCode().showQrCode(context, terminList);
                      }
                    },
                  ),
                  MenuItemButton(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.help_rounded),
                          SizedBox(width: 10),
                          Text(S.current.help)
                        ],
                      ),
                    ),
                    onPressed: () => Utilities().showHelpDialog(context, "planView"),
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
      body:LayoutBuilder(builder: (context, constraints){
      bool isPortrait = constraints.maxWidth < 600;
      return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20)),
              color: Theme.of(context).scaffoldBackgroundColor
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 0, right: 0),
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onScaleStart: (ev){
                  if(ev.pointerCount > 1){
                      setState(() {
                        _blockScroll = true;
                      });
                  }
                },
                onScaleEnd: (ev){
                  setState(() {
                    _blockScroll = false;
                  });
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _overallZoom = details.scale;
                    _overallZoom = _overallZoom.clamp(0.98, 1.04);
                    cellHeight = (cellHeight * _overallZoom).toInt().clamp(35, 250);
                    updateTasks();
                  });
                },
              child: _loaded ? createTimePlaner(cellHeight, isPortrait ? 125 : ((MediaQuery.of(context).size.width - 60)/7).toInt(), _blockScroll) : SizedBox() //index startet bei 0, 0-23 ist also 24/7
            )
          ),
        );}
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TerminCreatePage(
                  startDate: widget.start,
                  endDate: widget.end,
                  personId: widget.person.id,
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

/*TimePlanner(
                startHour: 0,
                endHour: 23,
                use24HourFormat: true,
                setTimeOnAxis: true,
                currentTimeAnimation: true,
                animateToDefinedHour: scrollToSpecificHour,
                animateToDefinedDay: scrollToSpecificDay,
                style: TimePlannerStyle(
                  cellHeight: cellHeight,
                  cellWidth:  125, //leider nur wenn neu gebuildet wird
                  showScrollBar: true,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  interstitialEvenColor: MyApp.of(context).themeMode == ThemeMode.light ? Colors.grey[50] : Colors.blueGrey.shade400,
                  interstitialOddColor: MyApp.of(context).themeMode == ThemeMode.light ? Colors.grey[200] : Colors.blueGrey.shade500,
                ),
                headers: calendarHeaders,
                tasks: tasks,
              ),*/

