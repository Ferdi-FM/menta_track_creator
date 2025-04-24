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
                        //FittedBox(
                        //  child: InkWell(
                        //      onLongPress: (){
                        //        deleteItemTap();
                        //      },
                        //      child: Padding(padding: EdgeInsets.all(3),
                        //        child: Icon(Icons.delete_outline, size: 32,),)),
                        //)
                      ],
                    ),)
                ),
              )
            ),
          ),
    );
  }
}


/* Alternativer Title
Table(
                columnWidths: {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: FlexColumnWidth()
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child:  Text("${S.current.from}:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("${Utilities().getWeekDay(start.weekday,true)}", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("${DateFormat("dd.MM.yy").format(start)}", style: TextStyle(fontWeight: FontWeight.bold))
                    )

                  ]),
                  TableRow(children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child:  Text("${S.current.to}:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("${Utilities().getWeekDay(end.weekday,true)}", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text("${DateFormat("dd.MM.yy").format(end)}", style: TextStyle(fontWeight: FontWeight.bold))
                    )
                  ]),
                ],
              ),

 */