import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/helper_utilities.dart';

import 'generated/l10n.dart';

class RangeTile extends StatelessWidget {
  final int index;
  final DateTime start;
  final DateTime end;
  final bool newest;
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
    required this.onItemTap, required this.newest,
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
                                AutoSizeText("${newest ? S.current.to : S.current.from}:", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13),
                                AutoSizeText(
                                  "${Utilities().getWeekDay(newest ? end.weekday : start.weekday, true)} ${DateFormat("dd.MM.yy").format(newest ? end : start)}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  maxFontSize: 13,
                                )
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AutoSizeText("${newest ? S.current.from : S.current.to}:", style: TextStyle(fontWeight: FontWeight.bold), maxFontSize: 13),
                                AutoSizeText(
                                  "${Utilities().getWeekDay(newest ? start.weekday : end.weekday, true)} ${DateFormat("dd.MM.yy").format(newest ? start : end)}",
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