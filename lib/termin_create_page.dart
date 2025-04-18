
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/termin_dialogue.dart';

import 'database_helper.dart';

class TerminCreatePage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String userName;

  final DateTime? existingStartTime;
  final DateTime? existingEndTime;
  final String? existingName;
  final int? existingIndex;
  final bool terminToUpdate;

  const TerminCreatePage({
    super.key,
    required this.startDate,
    required this.endDate,
    this.existingStartTime,
    this.existingEndTime,
    this.existingName, required this.userName,
    required this.terminToUpdate, this.existingIndex});

  @override
  TerminCreateState createState() => TerminCreateState();
}

class TerminCreateState extends State<TerminCreatePage> {
  List<DateTimeRange> ranges = [];
  TextEditingController nameController = TextEditingController();
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  List<int> selectedWeekdays = [];
  final List<String> weekdays = [
    "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So",
  ];
  Map<int, int> sliderValues = {};

  double sliderValue = 0;

  @override
  void initState() {
    super.initState();
    setUpDisplay();

  }
  void setUpDisplay(){
    setState(() {
      if(widget.existingStartTime != null){
        DateTime dt = DateTime.parse(DateFormat("yyyy-MM-dd").format(widget.existingStartTime!));
        selectedDate = dt;
        startTime = TimeOfDay.fromDateTime(widget.existingStartTime!);
        if(widget.existingEndTime != null ) {
          endTime = TimeOfDay.fromDateTime(widget.existingEndTime!);
        } else {
          endTime = TimeOfDay(hour: startTime.hour+1, minute: startTime.minute);
        }
        nameController.text = widget.existingName != null ? widget.existingName! : "";
        if(widget.existingIndex != null) {
          selectedWeekdays.add(widget.existingIndex!);
          sliderValues[widget.existingIndex!] = 0;
        }
      } else {
        selectedDate = widget.startDate;
        startTime = TimeOfDay.fromDateTime(DateTime.now());
        endTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(minutes: 60)));
      }
    });
    int timeSpanLength = widget.endDate.difference(widget.startDate).inDays;
    int startDay = widget.startDate.weekday;
    weekdays.clear();
    for(int i = 0; i < timeSpanLength+1; i++){
      int weekDay = (startDay + i) % 7;
      weekDay = weekDay == 0 ? 7 : weekDay;
      String date = widget.startDate.add(Duration(days: i)).day.toString();
      setState(() {
        weekdays.add("${Utilities().getWeekDay(weekDay)}\n$date");
      });
    }
  }

    Future<DateTime?> pickDate(DateTime? initialDate) async {
      return await showDatePicker(
        context: context,
        initialDate: widget.startDate,
        firstDate: widget.startDate,
        lastDate: widget.endDate,
        barrierDismissible: false,
      );
    }

    Future<TimeOfDay?> pickTime(TimeOfDay? initialTime) async {
      return await showTimePicker(
        context: context,
        initialTime: initialTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
    }

    bool error = false;

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     resizeToAvoidBottomInset: false,
     appBar: AppBar(
       title: FittedBox(
         fit: BoxFit.fitWidth,
         child: Row(
             spacing: 25,
             children: [
               RichText(
                 text: TextSpan(
                     children: [
                       TextSpan(text: "${nameController.text}  \n", style: TextStyle(fontWeight: FontWeight.bold)),
                       TextSpan(text:  "am ${DateFormat("dd.MM").format(selectedDate)} um ${startTime.format(context)}")
                     ],
                     style: TextStyle(color: Colors.black87, fontSize: 18)),
               ),
             ]
         ) ,
       ),
     ),
     body: Padding(
       padding: EdgeInsets.all(25),
       child: Stack(
         children: [
           Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               TextField(
                 controller: nameController,
                 decoration: InputDecoration(
                     labelText: "Termin Name",
                     errorText: !error ? null : "Bitte gib einen Namen ein",
                     focusedBorder: !error ? OutlineInputBorder(
                       borderSide: BorderSide(
                         color: !error ? Colors.blue : Colors.red,
                       ),
                     ) : null,
                 ),
                 onChanged: (ev){
                   setState(() {
                     error = false;
                   });
                 },
               ),
               SizedBox(height: 10),
               if(widget.terminToUpdate)ListTile(
                 title: Text("Datum: ${DateFormat("dd.MM.yyyy").format(selectedDate)}"),
                 trailing: Icon(Icons.calendar_today),
                 onTap: () async {
                   DateTime? picked = await pickDate(selectedDate);
                   if (picked != null) {
                     setState(() => selectedDate = picked);
                   }
                 },
               ),
               ListTile(
                 title: Text("Startzeit: ${startTime.format(context)}"),
                 trailing: Icon(Icons.access_time),
                 onTap: () async {
                   TimeOfDay? picked = await pickTime(startTime);
                   if (picked != null) {
                     setState(() {
                       startTime = picked;
                       endTime = TimeOfDay(hour: picked.hour+1, minute: picked.minute);
                     });
                   }
                 },
               ),
               ListTile(
                 title: Text("Endzeit: ${endTime.format(context)}"),
                 trailing: Icon(Icons.access_time),
                 onTap: () async {
                   TimeOfDay? picked = await pickTime(endTime);
                   if (picked != null) {
                     setState(() => endTime = picked);
                   }
                 },
               ),
               SizedBox(height: 20,),
               if(!widget.terminToUpdate)...{
                 GridView.builder(
                   shrinkWrap: true,
                   physics: NeverScrollableScrollPhysics(), // damit es nicht scrollt
                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 7,
                       crossAxisSpacing: 4,
                       mainAxisSpacing: 4
                   ),
                   itemCount: weekdays.length,
                   itemBuilder: (context, index) {
                     final isSelected = selectedWeekdays.contains(index);
                     return GestureDetector(
                       onTap: () {
                         setState(() {
                           if (isSelected) {
                             selectedWeekdays.remove(index);
                             sliderValues.remove(index);

                             selectedWeekdays.sort();
                           } else {
                             selectedWeekdays.add(index);
                             sliderValues[index] = 0;
                             selectedWeekdays.sort();

                           }
                         });
                       },
                       child: Container(
                         decoration: BoxDecoration(
                           color: isSelected ? Colors.blueAccent : Colors.grey[200],
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.grey),
                         ),
                         alignment: Alignment.center,
                         child: Text(
                           weekdays[index],
                           style: TextStyle(
                             color: isSelected ? Colors.white : Colors.black,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                     );
                   },
                 ),
                 SizedBox(height: 25,),
                 if(selectedWeekdays.isNotEmpty)Material(
                   color: Theme.of(context).listTileTheme.tileColor,
                   borderRadius: BorderRadius.circular(15),
                   elevation: 5,
                   child: Padding(
                     padding: const EdgeInsets.all(10),
                     child: Column(
                       mainAxisSize: MainAxisSize.min, // Verhindert unendliches Wachsen
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             SizedBox(width: 10),
                             Text("GESTAFFELT"),
                             Tooltip(
                               message:
                               "Fügt jedem Termin die ausgewählte Dauer gestaffelt hinzu\nAlso z.B. bei 15min und drei ausgewählten Tagen: \n - 1. Tag = +0  min;\n - 2. Tag = +15 min;\n - 3. Tag = +30 min;\n etc.",
                               showDuration: Duration(seconds: 5),
                               child: Icon(Icons.help_outline_sharp),
                             ),
                           ],
                         ),
                         const SizedBox(height: 10),
                         SizedBox(
                           height: MediaQuery.of(context).size.height * 0.4, // Begrenzte Höhe für ListView
                           child: ListView.builder(
                             itemCount: selectedWeekdays.length,
                             itemBuilder: (context, index) {
                               final weekdayIndex = selectedWeekdays[index];
                               return ListTile(
                                 shape: RoundedRectangleBorder(),
                                 leading: Text(weekdays[weekdayIndex]),
                                 title: Slider(
                                   value: sliderValues[weekdayIndex]!.toDouble(),
                                   onChanged: (ev) {
                                     setState(() {
                                       sliderValues[weekdayIndex] = ev.toInt();
                                     });
                                   },
                                   divisions: 24,
                                   max: 60,
                                   min: -60,
                                   label: "${sliderValues[weekdayIndex]} min",
                                 ),
                                 trailing: Text("${sliderValues[weekdayIndex]} min"),
                               );
                             },
                           ),
                         ),
                       ],
                     ),
                   ),
                 )
               },
               SizedBox(height: 20,),


             ],
           ),
           Align(
               alignment: Alignment.bottomCenter,
               child: Column(
                 spacing: 20,
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.center,
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       TextButton(
                         style: TextButton.styleFrom(
                             elevation: 10,
                             backgroundColor: Theme.of(context).primaryColorLight,
                             minimumSize: Size(150, 40)
                         ),
                         onPressed: () => Navigator.pop(context),
                         child: Text("Abbrechen",style: TextStyle(color: Theme.of(context).primaryColorDark)),
                       ),
                       TextButton(
                         style: TextButton.styleFrom(
                             elevation: 10,
                             backgroundColor: Theme.of(context).primaryColorLight,
                             minimumSize: Size(150, 40)
                         ),
                         onPressed: () {
                           if (nameController.text.isNotEmpty) {
                             if(widget.terminToUpdate){
                               Termin t = Termin(
                                 name: nameController.text,
                                 startTime: selectedDate.add(Duration(hours: startTime.hour, minutes: startTime.minute)),
                                 endTime: selectedDate.add(Duration(hours: endTime.hour, minutes: endTime.minute)),
                               );
                               Navigator.of(context).pop(t);
                             } else {
                               if(selectedWeekdays.isEmpty) {
                                 if(mounted){
                                   Utilities().showFloatingSnackBar(context, "Keinen Tag ausgewählt!");
                                 }
                                  return;
                                }
                               for(int i = 0; i < selectedWeekdays.length; i++){
                                 int day = selectedWeekdays[i];
                                 DateTime iterativeStartTime = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, startTime.hour, startTime.minute);
                                 DateTime iterativeEndTime = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, endTime.hour, endTime.minute);
                                 if(endTime.isBefore(startTime)){
                                   iterativeEndTime = iterativeEndTime.add(Duration(days: 1));
                                 }
                                 iterativeStartTime = iterativeStartTime.add(Duration(days: day));
                                 iterativeStartTime = iterativeStartTime.add(Duration(minutes: sliderValues[selectedWeekdays[i]]!));

                                 iterativeEndTime = iterativeEndTime.add(Duration(days: day));
                                 iterativeEndTime = iterativeEndTime.add(Duration(minutes: sliderValues[selectedWeekdays[i]]!));

                                 Termin t = Termin(name: nameController.text, startTime: iterativeStartTime, endTime: iterativeEndTime);
                                 DatabaseHelper().insertTermin(t, widget.userName);
                               }
                               Navigator.of(context).pop(
                                   true
                               );
                             }
                           } else {
                              setState(() {
                                error = true;
                              });
                           }
                         },
                         child: Text("Speichern",style: TextStyle(color: Theme.of(context).primaryColorDark),),
                       ),
                     ],
                   ),
                   if(widget.terminToUpdate)TextButton(
                       onPressed: (){
                         DatabaseHelper().deleteTermin(widget.userName, Termin(name: widget.existingName!, startTime: widget.existingStartTime!, endTime: widget.existingEndTime!));
                         Navigator.of(context).pop(true);
                       },
                       child: Container(
                           width: MediaQuery.of(context).size.width*0.75,
                           height: 40,
                           decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(20),
                               color: Colors.redAccent.shade200.withAlpha(120)
                           ),
                           child: Center(child: Text("Löschen", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 20),),)

                       )
                   ),
                 ],
               )
           )
         ],
       ),
     ),
   );
  }
}