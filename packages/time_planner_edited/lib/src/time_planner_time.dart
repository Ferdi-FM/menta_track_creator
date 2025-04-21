import 'package:flutter/material.dart';
import 'package:time_planner/src/config/global_config.dart' as config;

/// Show the hour for each row of time planner
class TimePlannerTime extends StatelessWidget {
  /// Text it will be show as hour
  final String? time;
  final bool? setTimeOnAxis;

  /// Show the hour for each row of time planner
  const TimePlannerTime({
    super.key,
    this.time,
    this.setTimeOnAxis,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.cellHeight!.toDouble(),
      width: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0.0),
        child: setTimeOnAxis! ? Text(time!) : Center(child: Text(time!)),
      ),
    );
  }
}
