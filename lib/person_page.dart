import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/plan_view.dart';
import 'package:menta_track_creator/range_tile.dart';
import 'package:menta_track_creator/termin.dart';
import 'package:sqflite/sqflite.dart';
import 'create_qr_code.dart';
import 'generated/l10n.dart';
import 'main.dart';
import 'main_page.dart';

class PersonDetailPage extends StatefulWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  PersonDetailPageState createState() => PersonDetailPageState();
}

class PersonDetailPageState extends State<PersonDetailPage> {
  final List<DateTimeRange> _ranges = [];
  final List<DateTimeRange> _selectedRanges = [];

  @override
  void initState() {
   loadRanges();
    super.initState();
  }

  Future<void> loadRanges() async {
    List<Map<String, dynamic>> maps = await DatabaseHelper().getPlans(widget.person.name);
    for(Map map in maps){
      _ranges.add(DateTimeRange(start: DateTime.parse(map["startDate"]), end: DateTime.parse(map["endDate"])));
    }
    setState(() {
      _ranges;
    });
  }

  void _showDateRangePicker([int? index]) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      locale: const Locale("de", "DE"),
      initialDateRange: _ranges.isNotEmpty ? DateTimeRange(start: _ranges.last.end.add(Duration(days: 1)), end: _ranges.last.end.add(Duration(days: 7))) : DateTimeRange(start: DateTime.now(), end: DateTime.now().add(Duration(days: 6))),
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
        if(mounted)Utilities().showSnackBar(context, S.current.plans_overlap);
      } else {
        if(index == null){
          DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.name);
          setState(() {
            _ranges.add(picked);
          });
        } else {
          List<Termin> tList = await DatabaseHelper().getWeekPlan(widget.person.name, _ranges[index].start, _ranges[index].end);
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
            _ranges.add(picked);
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
                if(_selectedRanges.isNotEmpty){
                  setState(() {
                    _selectedRanges.clear();
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
              if(_ranges.isEmpty) Padding(padding: EdgeInsets.symmetric(vertical: 100), child: Text(S.current.no_plans_yet, textAlign: TextAlign.center, style: TextStyle(fontSize: 28))),
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
                    itemCount: _ranges.length,
                    itemBuilder: (context, index) {
                      final range = _ranges[index];
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 20 : 0),
                        child: RangeTile(
                          isSelected: _selectedRanges.contains(range),
                          onItemTap: (ev)  {
                            if(_selectedRanges.isNotEmpty){
                              if(!_selectedRanges.contains(range)){
                                _selectedRanges.add(range);
                              }
                            } else {
                              openCalendar(range.start, range.end);}
                          },
                          deleteItemTap: (){
                            setState(() {
                              _ranges.removeAt(index);
                              DatabaseHelper().deleteWeekPlan(range.start, range.end, widget.person.name);
                            });
                          },
                          copyPressed: () => _showDateRangePicker(index),
                          start: range.start,
                          end: range.end,
                          user: widget.person.name,
                          longPressItem: () async {
                            setState(() {
                              if(_selectedRanges.contains(range)){
                                _selectedRanges.remove(range);
                              } else {
                                _selectedRanges.add(range);
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
          if(_selectedRanges.isNotEmpty) Positioned(
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
                            _selectedRanges.clear();
                          });
                        },
                        child: Icon(Icons.close, size: 30,)),),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        for(DateTimeRange ran in _selectedRanges)...{
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
                            for(DateTimeRange range in _selectedRanges){
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
      floatingActionButton: _selectedRanges.isEmpty ? FloatingActionButton(
        onPressed: _showDateRangePicker,
        tooltip: S.current.choose_date,
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