
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/plan_view.dart';
import 'package:menta_track_creator/range_tile.dart';
import 'package:menta_track_creator/termin_dialogue.dart';
import 'package:sqflite/sqflite.dart';
import 'create_qr_code.dart';
import 'main.dart';

class PersonDetailPage extends StatefulWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  PersonDetailPageState createState() => PersonDetailPageState();
}

class PersonDetailPageState extends State<PersonDetailPage> {
  List<DateTimeRange> ranges = [];
  List<DateTimeRange> selectedRanges = [];

  @override
  void initState() {
   loadRanges();
    super.initState();
  }

  Future<void> loadRanges() async {
    List<Map<String, dynamic>> maps = await DatabaseHelper().getPlans(widget.person.name);
    for(Map map in maps){
      ranges.add(DateTimeRange(start: DateTime.parse(map["startDate"]), end: DateTime.parse(map["endDate"])));
    }
    setState(() {
      ranges;
    });
  }

  void _showDateRangePicker([int? index]) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      locale: const Locale("de", "DE"),
      initialDateRange: ranges.isNotEmpty ? DateTimeRange(start: ranges.last.end.add(Duration(days: 1)), end: ranges.last.end.add(Duration(days: 7))) : DateTimeRange(start: DateTime.now(), end: DateTime.now().add(Duration(days: 6))),
      firstDate: DateTime(2025),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      Database db = await DatabaseHelper().database;
      List<Map<String,dynamic>> maps = await db.query(
          "createdPlans",
          where:  """
              personName = ?
              AND datetime(?) <= datetime(endDate) 
              AND datetime(?) >= datetime(startDate)
            """,
          whereArgs: [
            widget.person.name,
            picked.start.toIso8601String(),
            picked.end.toIso8601String(),]
      );
      if(maps.isNotEmpty){
        if(mounted)Utilities().showSnackBar(context, "Die Pläne überschneiden sich!");
      } else {
        if(index == null){
          DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.name);
          setState(() {
            ranges.add(picked);
          });
        } else {
          List<Termin> tList = await DatabaseHelper().getWeekPlan(widget.person.name, ranges[index].start, ranges[index].end);
          DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.name);
          DateTime normalStart = DateTime(tList.first.startTime.year,tList.first.startTime.month,tList.first.startTime.day);
          for(Termin t in tList){
            int dif = DateTime(t.startTime.year,t.startTime.month,t.startTime.day).difference(normalStart).inDays;
            Duration dif2 = picked.start.difference(normalStart);
            DateTime newTime = normalStart.add(dif2).add(Duration(days: dif));
            DateTime startTime = newTime.add(Duration(hours: t.startTime.hour, minutes: t.startTime.minute));
            DateTime endTime = newTime.add(Duration(hours: t.endTime.hour, minutes: t.endTime.minute));
            if(endTime.isBefore(startTime))endTime = endTime.add(Duration(days: 1));
            Termin newT = Termin(
                name: t.name,
                startTime: startTime,
                endTime: endTime,
            );
            DatabaseHelper().insertTermin(newT, widget.person.name);
          }
          setState(() {
            ranges.add(picked);
          });

        }

      }
    }
  }

  List<Termin> copyTermineToNewWeek({
    required List<Termin> termine,
    required DateTime fromWeekStart,
    required DateTime toWeekStart,
  }) {
    return termine.map((t) {
      int daysOffset = DateTime(t.startTime.year, t.startTime.month, t.startTime.day)
          .difference(fromWeekStart)
          .inDays;
      DateTime newBase = toWeekStart.add(Duration(days: daysOffset));
      return Termin(
        name: t.name,
        startTime: DateTime(
            newBase.year, newBase.month, newBase.day,
            t.startTime.hour, t.startTime.minute),
        endTime: DateTime(
            newBase.year, newBase.month, newBase.day,
            t.endTime.hour, t.endTime.minute),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.person.name),
          leading: IconButton(
              onPressed: (){
                if(selectedRanges.isNotEmpty){
                  setState(() {
                    selectedRanges.clear();
                  });
                } else {
                  navigatorKey.currentState?.pop();
                }
              },
              icon: Icon(Icons.arrow_back)),
          actions: [
              Utilities().getHelpBurgerMenu(context, "PersonPage")
          ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if(ranges.isEmpty) Padding(padding: EdgeInsets.symmetric(vertical: 100), child: Text("Noch keine Wochenpläne", textAlign: TextAlign.center, style: TextStyle(fontSize: 28))),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent
                      ],
                      stops: [0.0, 0.04, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child:ListView.builder(
                    itemCount: ranges.length,
                    itemBuilder: (context, index) {
                      final range = ranges[index];
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 20 : 0),
                        child: RangeTile(
                          isSelected: selectedRanges.contains(range),
                          onItemTap: (ev)  {
                            openCalendar(range.start, range.end);
                          },
                          deleteItemTap: (){
                            setState(() {
                              ranges.removeAt(index);
                              DatabaseHelper().deleteWeekPlan(range.start, range.end, widget.person.name);
                            });
                          },
                          copyPressed: () => _showDateRangePicker(index),
                          start: range.start,
                          end: range.end,
                          user: widget.person.name,
                          longPressItem: () async {
                            setState(() {
                              if(selectedRanges.contains(range)){
                                selectedRanges.remove(range);
                              } else {
                                selectedRanges.add(range);
                              }
                            });
                            //List<Termin> l = await DatabaseHelper().getWeekPlan(user, start, end);
                            //CreateQRCode().showQrCode(context, l);
                          },
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
          if(selectedRanges.isNotEmpty) Positioned(
            bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  color: Theme.of(context).listTileTheme.tileColor
                ),
                height: MediaQuery.of(context).size.height*0.08,
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  FittedBox(
                    fit: BoxFit.contain,
                    child: TextButton(
                        onPressed: (){
                          setState(() {
                            selectedRanges.clear();
                          });
                        },
                        child: Icon(Icons.close, size: 30,)),),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        for(DateTimeRange ran in selectedRanges)...{
                          Text("${DateFormat("dd.MM").format(ran.start)} - ${DateFormat("dd.MM").format(ran.end)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)
                        }
                      ],
                    ),
                  ),
                  FittedBox(
                      fit: BoxFit.contain,
                      child: TextButton(
                          onPressed: () async {
                            List<Termin> allList = [];
                            for(DateTimeRange range in selectedRanges){
                              List<Termin> l = await DatabaseHelper().getWeekPlan(widget.person.name, range.start, range.end);
                              allList.addAll(l);
                            }
                            if(context.mounted)CreateQRCode().showQrCode(context, allList);
                          },
                          child: Icon(Icons.qr_code_2, size: 32,))),
                    ],
                )
                ),
              )
          )
        ],
      ),
      floatingActionButton: selectedRanges.isEmpty ? FloatingActionButton(
        onPressed: _showDateRangePicker,
        tooltip: 'Datum wählen',
        child: Icon(Icons.add_task),
      ) : SizedBox(),
    );
  }

  void openCalendar(DateTime start, DateTime end) {
    navigatorKey.currentState?.push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PlanView(
            start: start,
            end: end,
            userName: widget.person.name
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
  }
}