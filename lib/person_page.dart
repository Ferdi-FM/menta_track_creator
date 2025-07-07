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
  final List<bool> _isSelected = [true, false]; // [Newest, Oldest]

  @override
  void initState() {
   loadRanges();
   super.initState();
  }

  Future<void> loadRanges() async {
    List<Map<String, dynamic>> maps = await DatabaseHelper().getPlans(widget.person.id);
    setState(() {
      _ranges.clear();
      for(Map map in maps){
        _ranges.add(DateTimeRange(start: DateTime.parse(map["startDate"]), end: DateTime.parse(map["endDate"])));
      }

      _ranges.sort((a,b) {
        DateTime timeA = a.start;
        DateTime timeB = b.start;
        return timeB.compareTo(timeA);
      });
    });
  }

  void _showDateRangePicker([int? index]) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      locale: const Locale("de", "DE"),
      initialDateRange: _ranges.isNotEmpty ? DateTimeRange(start: _ranges.first.end.add(Duration(days: 1)), end: _ranges.first.end.add(Duration(days: 7))) : DateTimeRange(start: DateTime.now(), end: DateTime.now().add(Duration(days: 6))),
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
          await DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.id);
          setState(() {
            loadRanges();
          });
        } else {
          List<Termin> tList = await DatabaseHelper().getWeekPlan(widget.person.id, _ranges[index].start, _ranges[index].end);
          await DatabaseHelper().insertPlan(picked.start, picked.end, widget.person.id);
          if(tList.isNotEmpty){
            for(Termin t in tList){
              Duration originalDifference = t.startTime.difference(_ranges[index].start);
              DateTime newStart = picked.start.add(originalDifference);
              DateTime newEnd = newStart.add(t.endTime.difference(t.startTime));

              if(newStart.isAfter(picked.end.add(Duration(days: 1)))) continue; //Wenn der Termin außerhalb der neuen Range liegt/ +1day da .end um 0:00 ist
              Termin newT = Termin(
                name: t.name,
                startTime: newStart,
                endTime: newEnd,
              );
              await DatabaseHelper().insertTermin(newT, widget.person.id);
            }
          }
          setState(() {
            _ranges.insert(0,picked);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:[Theme.of(context).scaffoldBackgroundColor, Theme.of(context).primaryColorLight],
            stops: [0.5,1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
        children: [
          PageView(
            hitTestBehavior: HitTestBehavior.opaque,
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
                        S.current.weekly_plans,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).appBarTheme.backgroundColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(S.current.sort_by, textAlign: TextAlign.center),
                  ToggleButtons(
                    isSelected: _isSelected,
                    onPressed: (index) {
                      setState(() {
                        for (int i = 0; i < _isSelected.length; i++) {
                          _isSelected[i] = i == index;
                        }
                        if (index == 0) {
                          _ranges.sort((a, b) => b.start.compareTo(a.start)); // Newest first
                        } else {
                          _ranges.sort((a, b) => a.start.compareTo(b.start)); // Oldest first
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    constraints: BoxConstraints(minHeight: 42.0, minWidth: MediaQuery.of(context).size.width*0.4),
                    borderColor: Theme.of(context).appBarTheme.backgroundColor,
                    fillColor: Theme.of(context).appBarTheme.backgroundColor,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(S.current.newest),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(S.current.oldest),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if(_ranges.isEmpty) Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(S.current.no_plans_yet, style: TextStyle(fontSize: 24), textAlign: TextAlign.center,),
                    ),
                  ),
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
                      child: ListView.builder(
                        itemCount: _ranges.length,
                        itemBuilder: (context, index) {
                          final range = _ranges[index];
                          return Padding(
                            key: Key("$range"),
                            padding: EdgeInsets.only(top: index == 0 ? 15 : 5, bottom: 5, left: 13, right: 13),
                            child: Material(
                              elevation: 10,
                              borderRadius: BorderRadius.circular(12),
                              child: ClipRRect(
                                key: Key("$range"),
                                borderRadius: BorderRadius.circular(12),
                                child: Dismissible(
                                  key: Key("$range"),
                                  direction: DismissDirection.startToEnd,
                                  confirmDismiss: (ev) async {
                                    return await Utilities().showDeleteConfirmation(context, S.current.entry_toDelete(DateFormat("dd.MM").format(range.start), DateFormat("dd.MM").format(range.end)));
                                  },
                                  onDismissed: (direction) async {
                                    setState(() {
                                      _ranges.removeAt(index);
                                    });
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(S.current.entry_deleted),
                                        action: SnackBarAction(
                                          label: S.current.comment_undo,
                                          onPressed: () {
                                            setState(() {
                                              _ranges.insert(index, range);
                                            });
                                          },
                                        ),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    await Future.delayed(Duration(seconds: 3), (){
                                      if(!_ranges.contains(range)){
                                        DatabaseHelper().deleteWeekPlan(range.start, range.end, widget.person.id);
                                      }
                                    });
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.red,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: RangeTile(
                                        index: index,
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
                                        },
                                    newest: _isSelected[0],
                                  ),
                                ),
                                )
                            ),
                          );
                        }
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
      )
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
              label:  S.current.weekly_plans,
            ),
            BottomNavigationBarItem(
              icon: currentPage == 1 ? Icon(Icons.comment) : Icon(Icons.comment_outlined),
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              label:  S.current.comments_note(2),
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
            height: MediaQuery.of(context).size.height*0.12,
            child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
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