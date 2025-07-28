import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/termin.dart';
import 'generated/l10n.dart';
import 'helper_utilities.dart';

class PlanViewList extends StatefulWidget{
  final DateTime start;
  final DateTime end;
  final List<Termin> weekAppointments;
  final Function updateTermin;

  const PlanViewList({
    super.key,
    required this.start,
    required this.end,
    required this.weekAppointments,
    required this.updateTermin
  });

  @override
  PlanViewListState createState() => PlanViewListState();

}

class PlanViewListState extends State<PlanViewList>{

  Widget buildTaskList(){
    Map<String,List<Termin>> taskMap = {};
    DateTime modularTime = widget.start;
    while(modularTime.isBefore(widget.end.add(Duration(days: 1)))){
      String weekDay = "${Utilities().getWeekDay(modularTime.weekday, false)} ${DateFormat("dd.MM").format(modularTime)}";
      taskMap[weekDay] = [];
      for(Termin t in widget.weekAppointments){
        if(t.startTime.day == modularTime.day){ //Solang Zeitperiode nicht länger als 1 Monat ist sollte das funktioniere
          taskMap[weekDay]?.add(t);
        }
      }
      modularTime = modularTime.add(Duration(days: 1));
    }
    return ShaderMask(
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
            stops: [0.0, 0.01, 1.0, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child:ListView.separated(
          key: UniqueKey(),
          itemCount: taskMap.length,
          itemBuilder: (context, index){
            String key = taskMap.keys.elementAt(index);
            return Material(
              elevation: 10,
              color: Theme.of(context).listTileTheme.tileColor,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  SizedBox(height: 8,),
                  Text(key,style: TextStyle(fontSize: 18),),
                  if(taskMap[key] != null)...{
                    if(taskMap[key]!.isEmpty) Text(S.current.planView_nothingPlaned, textAlign: TextAlign.center,),
                    for(Termin t in taskMap[key]!)...{
                      InkWell(
                        onTapUp: (ev){
                          widget.updateTermin(t.name, t.startTime,t.endTime, MediaQuery.of(context).size.width/2, ev.globalPosition.dy);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child:Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          child:  Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).listTileTheme.textColor,
                                  ),
                                  width: 10,
                                  height: 10,
                                ),
                                SizedBox(width: 10,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.name, style: TextStyle(decoration: TextDecoration.underline), softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,),
                                    Text("${DateFormat("HH:mm").format(t.startTime)} - ${DateFormat("HH:mm").format(t.endTime)}", style: TextStyle(fontStyle: FontStyle.italic),softWrap: true)
                                  ],
                                )
                              ]
                          ),
                        ),
                      )
                    }
                  }
                ],
              ),
            );
          }, separatorBuilder: (BuildContext context, int index) { return SizedBox(height: 20,); },

        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: buildTaskList(),
    );
  }

}