import 'package:flutter/material.dart';
import 'package:time_planner/src/time_planner_date_time.dart';
import 'package:time_planner/src/config/global_config.dart' as config;

/// Widget that show on time planner as the tasks
class TimePlannerTask extends StatefulWidget {
  /// Minutes duration of task or object
  final int minutesDuration;

  /// Days duration of task or object, default is 1
  final int? daysDuration;

  final int numOfOverlaps;

  final int overLapOffset;

  /// When this task will be happen
  final TimePlannerDateTime dateTime;

  /// Background color of task
  final Color? color;

  /// This will be happen when user tap on task, for example show a dialog or navigate to other page
  final Function? onTap;

  /// Show this child on the task
  ///
  /// Typically an [Text].
  final Widget? child;

  /// parameter to set space from left, to set it: config.cellWidth! * dateTime.day.toDouble()
  final double? leftSpace;

  /// parameter to set width of task, to set it: (config.cellWidth!.toDouble() * (daysDuration ?? 1)) -config.horizontalTaskPadding!
  final double? widthTask;

  final BorderRadius? borderRadius;

  /// Widget that show on time planner as the tasks
  const TimePlannerTask(
      {super.key,
        required this.minutesDuration,
        required this.dateTime,
        this.daysDuration,
        required this.numOfOverlaps,
        required this.overLapOffset,
        this.color,
        this.onTap,
        this.child,
        this.leftSpace,
        this.widthTask,
        this.borderRadius
      });

  @override
  State<TimePlannerTask> createState() => _TimePlannerTaskState();
}

class _TimePlannerTaskState extends State<TimePlannerTask> {
  late double top;
  late double left;

  @override
  void initState() {
    super.initState();
    top = ((config.cellHeight! * (widget.dateTime.hour - config.startHour)) +
        ((widget.dateTime.minutes * config.cellHeight!) / 60))
        .toDouble();
    left = config.cellWidth! * widget.dateTime.day.toDouble() +
        (widget.numOfOverlaps == 0
            ? 0
            : (config.cellWidth! / widget.numOfOverlaps) *
            widget.overLapOffset);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: SizedBox(
          width: widget.widthTask,
          child: Padding(
            padding:
            EdgeInsets.only(left: config.horizontalTaskPadding!.toDouble()),
            child: Material(
              elevation: 3,
              borderRadius: widget.borderRadius ?? config.borderRadius,
              child: Stack(
                children: [
                  InkWell(
                    onTap: widget.onTap as void Function()? ?? () {},
                    child: Container(
                      height: ((widget.minutesDuration.toDouble() * config.cellHeight!) /
                          60), //60 minutes
                      width: (config.cellWidth!.toDouble() / (widget.numOfOverlaps == 0 ? 1 : widget.numOfOverlaps)),
                      // (daysDuration! >= 1 ? daysDuration! : 1)),
                      decoration: BoxDecoration(
                          borderRadius: widget.borderRadius ?? config.borderRadius,
                          color: widget.color ?? Theme.of(context).primaryColor),
                      child: Center(
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}


/*
Logik-Beginn für DragAndDrop
GestureDetector(
        onPanUpdate: (details) {
          print("panupdate");
          setState(() {
            top += details.delta.dy;
            left += details.delta.dx;
          });
        },
        onPanEnd: (details) {
          // Logik zur Anpassung der Zeit / Koordinaten nach Raster
          final int newHour = (top / config.cellHeight!).floor() + config.startHour;
          final int newMinutes =
          (((top % config.cellHeight!) * 60) / config.cellHeight!).round();
          final int newDay = (left / config.cellWidth!).floor();

          // Optional: Callback oder State Management nutzen
          print("Neue Zeit: $newDay, $newHour:$newMinutes");
        },
        onTap: widget.onTap as void Function()? ?? () {},
 */