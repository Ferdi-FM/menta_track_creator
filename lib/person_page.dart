import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/comment_page.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/person.dart';
import 'package:menta_track_creator/plan_view.dart';
import 'package:menta_track_creator/range_tile.dart';
import 'package:menta_track_creator/termin.dart';
import 'package:sqflite/sqflite.dart';
import 'create_qr_code.dart';
import 'generated/l10n.dart';
import 'main.dart';

class PersonDetailPage extends StatefulWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  PersonDetailPageState createState() => PersonDetailPageState();
}

class PersonDetailPageState extends State<PersonDetailPage> {
  final List<DateTimeRange> _ranges = [];
  final List<DateTimeRange> _selectedRanges = [];
  PageController pageController = PageController(
    initialPage: 0
  );
  int currentPage = 0;

  @override
  void initState() {
   loadRanges();
   super.initState();
  }

  Future<void> loadRanges() async {
    List<Map<String, dynamic>> maps = await DatabaseHelper().getPlans(widget.person.id);
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
              personId = ?
              AND datetime(?) <= datetime(endDate) 
              AND datetime(?) >= datetime(startDate)
            """,
          whereArgs: [
            widget.person.id,
            picked.start.toIso8601String(),
            picked.end.toIso8601String(),]
      );
      if(maps.isNotEmpty){
        if(mounted)Utilities().showSnackBar(context, S.current.plans_overlap);
      } else {
        if(index == null){
          DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.id);
          setState(() {
            _ranges.add(picked);
          });
        } else {
          List<Termin> tList = await DatabaseHelper().getWeekPlan(widget.person.id, _ranges[index].start, _ranges[index].end);
          DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.id);
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
            DatabaseHelper().insertTermin(newT, widget.person.id);
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
    return Stack(children: [Scaffold(
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
              Utilities().getHelpBurgerMenu(context, currentPage == 0 ? "PersonPage" : "NotePage")
          ],
      ),
      body: Stack(
        children: [
          PageView(
            onPageChanged: (ev){
              setState(() {
                currentPage = ev;
                if(currentPage == 1){
                  _selectedRanges.clear();
                }
              });
            },
            controller: pageController,
            children: [
              Column(
                children: [
                  SizedBox(height: 20,),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                        "Wochenpläne",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).appBarTheme.backgroundColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ),
                  ),
                  SizedBox(height: 20),
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
                      child:ListView.separated(
                        itemCount: _ranges.length,
                        itemBuilder: (context, index) {
                          final range = _ranges[index];
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 20 : 0),
                            child: RangeTile(
                              isSelected: _selectedRanges.contains(range),
                              onItemTap: (ev)  {
                                if(_selectedRanges.isNotEmpty){
                                  setState(() {
                                    if(!_selectedRanges.contains(range)){
                                      _selectedRanges.add(range);
                                    } else {
                                      _selectedRanges.remove(range);
                                    }
                                  });
                                } else {
                                  openCalendar(range.start, range.end);}
                              },
                              deleteItemTap: (){
                                setState(() {
                                  _ranges.removeAt(index);
                                  DatabaseHelper().deleteWeekPlan(range.start, range.end, widget.person.id);
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
                        }, separatorBuilder: (BuildContext context, int index) { return SizedBox(height: 15,); },
                      ),
                    ),
                  ),

                ],
              ),
              CommentPage(person: widget.person)
            ],
          )
          ,
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(top:0),
        decoration: BoxDecoration(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15) ,topRight:Radius.circular(15) )
        ),
        child: BottomNavigationBar(
          showUnselectedLabels: true,
          elevation: 15,
          backgroundColor: Colors.transparent,
          currentIndex: currentPage,
          onTap: (int index) async {
            setState(() {
              currentPage = index;
            });
            pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
          items: [
            BottomNavigationBarItem(
              icon: currentPage == 0 ? Icon(Icons.calendar_view_week) : Icon(Icons.calendar_view_week_outlined),
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              label:  "Wochenpläne",
            ),
            BottomNavigationBarItem(
              icon: currentPage == 1 ? Icon(Icons.comment) : Icon(Icons.comment_outlined),
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              label:  "Kommentare",
            ),
          ],
        ),
      ),
      floatingActionButton: (_selectedRanges.isEmpty && currentPage == 0) ? FloatingActionButton(
        onPressed: _showDateRangePicker,
        tooltip: S.current.choose_date,
        child: Icon(Icons.add_task),
      ) : SizedBox(),
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
                                List<Termin> l = await DatabaseHelper().getWeekPlan(widget.person.id, range.start, range.end);
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
    ]
    );
  }

  void openCalendar(DateTime start, DateTime end) {
    navigatorKey.currentState?.push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PlanView(
            start: start,
            end: end,
            person: widget.person
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