import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/helper_utilities.dart';

import 'generated/l10n.dart';

class RangeTile extends StatelessWidget {
  final int index;
  final DateTime start;
  final DateTime end;
  final String user;
  final bool isSelected;
  final Function onItemTap;
  final VoidCallback longPressItem;
  final VoidCallback copyPressed;

  const RangeTile({
    super.key,
    required this.start,
    required this.end,
    required this.user,
    required this.isSelected,
    required this.index,
    required this.longPressItem,
    required this.copyPressed,
    required this.onItemTap,
  });

  String getDateAndTimeFromDay(String dayString){
    DateTime dateTime = DateTime.parse(dayString);
    String correctedString = "am ${DateFormat("dd.MM").format(dateTime)} um ${DateFormat("HH:mm").format(dateTime)}";
    return correctedString;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
            onTapUp: (ev) => {
              onItemTap(ev),
            },
            onLongPress: (){
              longPressItem();
            },
            child: Container(
                constraints: BoxConstraints(
                    minHeight: 72
                ),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Theme.of(context).primaryColor,
                      isSelected ? Theme.of(context).primaryColorLight.withAlpha(210) : Theme.of(context).listTileTheme.tileColor ?? Colors.blueGrey,
                      isSelected ? Theme.of(context).primaryColorLight.withAlpha(210) : Theme.of(context).listTileTheme.tileColor ?? Colors.blueGrey,
                      Theme.of(context).primaryColor
                    ],
                        stops: [0.0,0.07,0.93,1.0])
                ),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 12,),
                      Icon(isSelected ? Icons.check_circle : Icons.view_week, color: Theme.of(context).primaryColor),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AutoSizeText("${S.current.from}:", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13),
                                AutoSizeText(
                                  "${Utilities().getWeekDay(start.weekday, true)} ${DateFormat("dd.MM.yy").format(start)}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  maxFontSize: 13,
                                )
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AutoSizeText("${S.current.to}:", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13),
                                AutoSizeText(
                                  "${Utilities().getWeekDay(end.weekday, true)} ${DateFormat("dd.MM.yy").format(end)}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  maxFontSize: 13,
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: copyPressed,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.transparent
                            ),
                            child: Icon(Icons.copy, size: 32, color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

/*
OLD TILE:
return Container(
        decoration: BoxDecoration( //rechte seite
          border: Border(right: BorderSide(color: Theme.of(context).primaryColor, width: 10)),
          //borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Container(
          decoration: BoxDecoration( //linke Seite
            border: Border(left: BorderSide(color: Theme.of(context).primaryColor,width: 10)),                    //Borderside darf immmer nur einfarbig sein
            //borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
          ),
          child: GestureDetector(
            onTapUp: (ev) => {
              onItemTap(ev),
            },
            onLongPress: (){
              longPressItem();
            },
            child: ListTile(
              selected: isSelected,
              selectedTileColor: Theme.of(context).primaryColorLight,
              minTileHeight: 72,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              leading: Icon(Icons.view_week),//Icon(Icons.calendar_view_week),
              title: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           AutoSizeText("${S.current.from}:", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13,),
                           AutoSizeText("${Utilities().getWeekDay(start.weekday,true)} ${DateFormat("dd.MM.yy").format(start)}", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13,)
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AutoSizeText("${S.current.to}:", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13,),
                          AutoSizeText("${Utilities().getWeekDay(end.weekday,true)} ${DateFormat("dd.MM.yy").format(end)}", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13,)
                        ],
                      )
                    ],
              ),
              trailing: Padding(padding: EdgeInsets.only(top: 12, bottom: 12, left: 8, right: 10),
                  child: FittedBox(
                    child:   Row(
                      spacing: 13,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.fitHeight,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                              onTap: () {copyPressed();},
                              child: Padding(padding: EdgeInsets.all(3),
                                child: Icon(Icons.copy, size: 32,),)

                              ),
                        ),
                      ],
                    ),)
                ),
              )
            ),
          ),
    );
 */