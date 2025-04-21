import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/helper_utilities.dart';

import 'generated/l10n.dart';

class RangeTile extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final String user;
  final bool isSelected;
  final Function onItemTap;
  final VoidCallback deleteItemTap;
  final VoidCallback longPressItem;
  final VoidCallback copyPressed;

  const RangeTile({
    super.key,
    required this.start,
    required this.end,
    required this.user,
    required this.isSelected,
    required this.deleteItemTap,
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
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5.5, horizontal: 16.0),
      elevation: 10,
      child: Container(
        decoration: BoxDecoration( //rechte seite
          border: Border(right: BorderSide(color: Theme.of(context).primaryColor, width: 7)),
          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Container(
          decoration: BoxDecoration( //linke Seite
            border: Border(left: BorderSide(color: Theme.of(context).primaryColor,width: 5)),                    //Borderside darf immmer nur einfarbig sein
            borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
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
              leading: Icon(Icons.calendar_view_week),
              title: FittedBox(child: Text("${S.current.from}:  ${Utilities().getWeekDay(start.weekday,true)} ${DateFormat("dd.MM.yy").format(start)}\n${S.current.to}:   ${Utilities().getWeekDay(end.weekday,true)} ${DateFormat("dd.MM.yy").format(end)}", style: TextStyle(fontWeight: FontWeight.bold))),
              trailing: SizedBox(
                height: 70,
                width: 100,
                child: FittedBox(
                    child:  Row(
                  spacing: 0,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitHeight,
                        child: TextButton(
                            onPressed: () {copyPressed();},
                            child: Icon(Icons.copy, size: 32,)),
                      ),
                    FittedBox(
                        child: TextButton(
                            onLongPress: (){
                              deleteItemTap();
                            },
                            onPressed: () {  },
                            child: Icon(Icons.delete, size: 32,)),
                      )
                  ],
                )
                ),
              )
            ),
          ),
        ),
      ),
    );
  }
}