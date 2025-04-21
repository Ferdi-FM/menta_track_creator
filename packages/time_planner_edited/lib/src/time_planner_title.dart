import 'package:flutter/material.dart';
import 'package:time_planner/src/config/global_config.dart' as config;

/// Title widget for time planner
class TimePlannerTitle extends StatelessWidget {
  /// Title of each day, typically is name of the day for example sunday
  ///
  /// but you can set any things here
  final String title;

  /// Text style for title
  final TextStyle? titleStyle;

  /// Date of each day like 03/21/2021 but you can leave it empty or write other things
  final String? date;

  final String? displayDate;

  /// Text style for date text
  final TextStyle? dateStyle;

  final void Function(String) voidAction;

  /// Title widget for time planner
  const TimePlannerTitle({
    super.key,
    required this.title,
    this.date,
    this.displayDate,
    this.titleStyle,
    this.dateStyle,
    required this.voidAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 50,
        width: config.cellWidth!.toDouble(),
        child: Padding(
          padding: EdgeInsets.all(5),
          child: ElevatedButton(
                  onPressed: (){
                    voidAction(date!);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    backgroundColor:Theme.of(context).listTileTheme.tileColor?.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: SizedBox(
                      height: double.infinity,
                      width: double.infinity,
                      child: FittedBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FittedBox(
                                child: Text(
                                  title,
                                  style: titleStyle ?? const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            const SizedBox(
                              height: 3,
                            ),
                              Text(displayDate ?? '',
                              style: dateStyle ??
                                  const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        )
                      )
                  )
              ),
            ),
    );
  }
}
