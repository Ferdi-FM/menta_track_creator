import 'package:flutter/material.dart';
import 'package:time_planner/src/config/global_config.dart' as config;
import 'package:time_planner/src/time_planner_style.dart';
import 'package:time_planner/src/time_planner_task.dart';
import 'package:time_planner/src/time_planner_time.dart';
import 'package:time_planner/src/time_planner_title.dart';

/// Time planner widget
class TimePlanner extends StatefulWidget {
  /// Time start from this, it will start from 0
  final int startHour;

  /// Time end at this hour, max value is 23
  final int endHour;

  /// Create days from here, each day is a TimePlannerTitle.
  ///
  /// you should create at least one day
  final List<TimePlannerTitle> headers;

  /// List of widgets on time planner
  final List<TimePlannerTask>? tasks;

  /// Style of time planner
  final TimePlannerStyle? style;

  /// When widget loaded scroll to current time with an animation. Default is true
  final bool? currentTimeAnimation;

  final int? animateToDefinedHour;

  final int? animateToDefinedDay;

  /// Whether time is displayed in 24 hour format or am/pm format in the time column on the left.
  final bool use24HourFormat;

  //Whether the time is displayed on the axis of the tim or on the center of the timeblock. Default is false.
  final bool setTimeOnAxis;

  final Function tapOnEmptyField;
  final bool blockScroll;

  /// Time planner widget
  const TimePlanner({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.headers,
    this.tasks,
    this.style,
    this.use24HourFormat = false,
    this.setTimeOnAxis = false,
    this.currentTimeAnimation,
    this.animateToDefinedHour,
    this.animateToDefinedDay,
    required this.tapOnEmptyField,
    required this.blockScroll,
  });
  @override
  TimePlannerState createState() => TimePlannerState();
}

class TimePlannerState extends State<TimePlanner> {
  ScrollController mainHorizontalController = ScrollController();
  ScrollController mainVerticalController = ScrollController();
  ScrollController dayHorizontalController = ScrollController();
  ScrollController timeVerticalController = ScrollController();
  TimePlannerStyle style = TimePlannerStyle();
  List<TimePlannerTask> tasks = [];
  bool? isAnimated = true;
  int? isDefinedAnimated;
  int? isDefinedAnimatedDay;

  /// check input value rules
  void _checkInputValue() {
    if (widget.startHour > widget.endHour) {
      throw FlutterError("Start hour should be lower than end hour");
    } else if (widget.startHour < 0) {
      throw FlutterError("Start hour should be larger than 0");
    } else if (widget.endHour > 23) {
      throw FlutterError("Start hour should be lower than 23");
    } else if (widget.headers.isEmpty) {
      throw FlutterError("header can't be empty");
    }
  }

  /// create local style
  void _convertToLocalStyle() {
    style.backgroundColor = widget.style?.backgroundColor;
    style.cellHeight = widget.style?.cellHeight ?? 80;
    style.cellWidth = widget.style?.cellWidth ?? 90;
    style.horizontalTaskPadding = widget.style?.horizontalTaskPadding ?? 0;
    style.borderRadius = widget.style?.borderRadius ??
        const BorderRadius.all(Radius.circular(8.0));
    style.dividerColor = widget.style?.dividerColor;
    style.showScrollBar = widget.style?.showScrollBar ?? false;
    style.interstitialOddColor = widget.style?.interstitialOddColor;
    style.interstitialEvenColor = widget.style?.interstitialEvenColor;
  }

  /// store input data to static values
  void _initData() {
    _checkInputValue();
    _convertToLocalStyle();
    config.horizontalTaskPadding = style.horizontalTaskPadding;
    config.cellHeight = style.cellHeight;
    config.cellWidth = style.cellWidth;
    config.totalHours = (widget.endHour - widget.startHour).toDouble();
    config.totalDays = widget.headers.length;
    config.startHour = widget.startHour;
    config.use24HourFormat = widget.use24HourFormat;
    config.setTimeOnAxis = widget.setTimeOnAxis;
    config.borderRadius = style.borderRadius;
    isAnimated = widget.currentTimeAnimation;
    isDefinedAnimated = widget.animateToDefinedHour;
    isDefinedAnimatedDay = widget.animateToDefinedDay;
    tasks = widget.tasks ?? [];
  }

  @override
  void initState() {
    _initData();
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      int hour = isDefinedAnimated ?? DateTime.now().hour;
      int day = isDefinedAnimatedDay ?? 0;
      if (isAnimated != null && isAnimated == true) {
        if (hour > widget.startHour) {
          double scrollOffset = (hour - widget.startHour) * config.cellHeight!.toDouble();
          double scrollHorizontalOffset = (day) * config.cellWidth!.toDouble();
          mainVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
          timeVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
          mainHorizontalController.animateTo(
            scrollHorizontalOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
          dayHorizontalController.animateTo(
            scrollHorizontalOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // we need to update the tasks list in case the tasks have changed
    tasks = widget.tasks ?? [];
    mainHorizontalController.addListener(() {
      dayHorizontalController.jumpTo(mainHorizontalController.offset);
    });
    mainVerticalController.addListener(() {
      timeVerticalController.jumpTo(mainVerticalController.offset);
    });

    return Container(
        color: style.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SingleChildScrollView(
              controller: dayHorizontalController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 70,
                  ),
                  for (int i = 0; i < config.totalDays; i++) widget.headers[i],
                ],
              ),
            ),
            Container(
              height: 1,
              color: style.dividerColor ?? Theme.of(context).primaryColor,
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: timeVerticalController,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              //first number is start hour and second number is end hour
                              for (int i = widget.startHour; i <= widget.endHour; i++)
                                Padding(
                                  // we need some additional padding horizontally if we're showing in am/pm format
                                  padding: EdgeInsets.symmetric(
                                    horizontal: !config.use24HourFormat ? 4 : 6,
                                  ),
                                  child: TimePlannerTime(
                                    // this returns the formatted time string based on the use24HourFormat argument.
                                    time: formattedTime(i),
                                    setTimeOnAxis: config.setTimeOnAxis,
                                  ),
                                )
                            ],
                          ),
                          Container(
                            height:
                            (config.totalHours * config.cellHeight!) + config.cellHeight! + 10,
                            width: 1,
                            color: style.dividerColor ??
                                Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: buildMainBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget buildMainBody() {
    int day = 0;
    int hour = 0;
    if (style.showScrollBar!) {
      return Stack(
        children: [
          Scrollbar(
              controller: mainVerticalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: widget.blockScroll ? NeverScrollableScrollPhysics() : null,
                controller: mainVerticalController,
                child: Scrollbar(
                  controller: mainHorizontalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: mainHorizontalController,
                    physics: widget.blockScroll ? NeverScrollableScrollPhysics() : null,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              height: (config.totalHours * config.cellHeight!) + config.cellHeight! + 30,
                              width: (config.totalDays * config.cellWidth!).toDouble(),
                              child: Stack(
                                children: <Widget>[
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      for (var i = 0; i < config.totalHours+1; i++)
                                        GestureDetector(
                                            onLongPress: (){
                                              widget.tapOnEmptyField(day, hour);
                                            },
                                            onLongPressDown: (ev){
                                              hour = i;
                                              day = (ev.localPosition.dx/config.cellWidth!).toInt();
                                            },
                                            child: Column( //In GestureDetector wickeln, damit man durch klick auf Zeit einen eintrag hinzufügen kann
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                Container(
                                                  height: (config.cellHeight! - 1).toDouble(),
                                                  color: i.isOdd ? style.interstitialOddColor : style.interstitialEvenColor,
                                                ),
                                                Divider(
                                                  height: 1,
                                                )
                                              ],
                                            )
                                        ), //Angepasst
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      for (var i = 0; i < config.totalDays; i++)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            SizedBox(
                                              width: (config.cellWidth! - 1).toDouble(),
                                            ),
                                            // The vertical lines that divides the columns
                                            Container(
                                              width: 1,
                                              height: (config.totalHours *
                                                  config.cellHeight!) +
                                                  config.cellHeight!,
                                              color: Colors.black12,
                                            )
                                          ],
                                        ),
                                    ],
                                  ),
                                  Positioned( ///ZEITANZEIGE
                                    top: DateTime.now().hour * config.cellHeight! + (config.cellHeight! * DateTime.now().minute / 60), // Position der Linie in der Mitte des Containers (200 / 2 = 100)
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,         // Dicke der Linie
                                      color: Theme.of(context).primaryColor.withAlpha(220), // Farbe der Linie
                                    ),
                                  ),
                                  for (int i = 0; i < tasks.length; i++) ...{
                                    tasks[i]
                                  },
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return SingleChildScrollView(
      controller: mainVerticalController,
      child: SingleChildScrollView(
        controller: mainHorizontalController,
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: (config.totalHours * config.cellHeight!) + config.cellHeight! + 10,
                  width: (config.totalDays * config.cellWidth!).toDouble(),
                  child: Stack(
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (var i = 0; i < config.totalHours; i++)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(
                                  height: (config.cellHeight! - 1).toDouble(),
                                ),
                                const Divider(
                                  height: 1,
                                ),
                              ],
                            )
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (var i = 0; i < config.totalDays; i++)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(
                                  width: (config.cellWidth! - 1).toDouble(),
                                ),
                                Container(
                                  width: 1,
                                  height:
                                  (config.totalHours * config.cellHeight!) +
                                      config.cellHeight!,
                                  color: Colors.black12,
                                )
                              ],
                            )
                        ],
                      ),
                      for (int i = 0; i < tasks.length; i++) ...{
                          tasks[i]
                      },
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formattedTime(int hour) {
    /// this method formats the input hour into a time string
    /// modifing it as necessary based on the use24HourFormat flag .
    if (config.use24HourFormat) {
      // we use the hour as-is
      return "$hour:00";
    } else {
      // we format the time to use the am/pm scheme
      if (hour == 0) return "12:00 am";
      if (hour < 12) return "$hour:00 am";
      if (hour == 12) return "12:00 pm";
      return "${hour - 12}:00 pm";
    }
  }
}
