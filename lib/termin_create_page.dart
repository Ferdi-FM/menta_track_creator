import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/termin.dart';
import 'database_helper.dart';
import 'generated/l10n.dart';

class TerminCreatePage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final int personId;

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
    this.existingName,
    required this.personId,
    required this.terminToUpdate,
    this.existingIndex});

  @override
  TerminCreateState createState() => TerminCreateState();
}

class TerminCreateState extends State<TerminCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final List<int> _selectedWeekdays = [];
  final List<String> _weekdays = [];
  final Map<int, int> _sliderValues = {};

  @override
  void initState() {
    super.initState();
    setUpDisplay();
  }

  void setUpDisplay(){
    setState(() {
      if(widget.existingStartTime != null){
        DateTime dt = DateTime.parse(DateFormat("yyyy-MM-dd").format(widget.existingStartTime!));
        _selectedDate = dt;
        _startTime = TimeOfDay.fromDateTime(widget.existingStartTime!);
        if(widget.existingEndTime != null ) {
          _endTime = TimeOfDay.fromDateTime(widget.existingEndTime!);
        } else {
          _endTime = TimeOfDay(hour: _startTime.hour+1, minute: _startTime.minute);
        }
        _nameController.text = widget.existingName != null ? widget.existingName! : "";
        if(widget.existingIndex != null) {
          _selectedWeekdays.add(widget.existingIndex!);
          _sliderValues[widget.existingIndex!] = 0;
        }
      } else {
        _selectedDate = widget.startDate;
        _startTime = TimeOfDay.fromDateTime(DateTime.now());
        _endTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(minutes: 60)));
      }
    });
    int timeSpanLength = widget.endDate.difference(widget.startDate).inDays;
    int startDay = widget.startDate.weekday;
    _weekdays.clear();
    for(int i = 0; i < timeSpanLength+1; i++){
      int weekDay = (startDay + i) % 7;
      weekDay = weekDay == 0 ? 7 : weekDay;
      String date = widget.startDate.add(Duration(days: i)).day.toString();
      setState(() {
        _weekdays.add("${Utilities().getWeekDay(weekDay,true)}\n$date");
      });
    }
  }

    Future<DateTime?> pickDate(DateTime? initialDate) async {
      return await showDatePicker(
        context: context,
        initialDate: widget.existingStartTime,
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
                       TextSpan(text: "${_nameController.text}  \n", style: TextStyle(fontWeight: FontWeight.bold)),
                       TextSpan(text:  "${S.current.on} ${DateFormat("dd.MM").format(_selectedDate)} ${S.current.at} ${_startTime.format(context)}")
                     ],
                     style: TextStyle(color: Colors.black87, fontSize: 18)),
               ),
             ]
         ) ,
       ),
     ),
     body: Padding(
       padding: EdgeInsets.all(25),
       child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               TextField(
                 controller: _nameController,
                 decoration: InputDecoration(
                     labelText: S.current.termin_creator_taskName,
                     errorText: !error ? null : S.current.termin_creator_addAName,
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
                 onTapOutside: (ev){
                    FocusScope.of(context).unfocus();
                 },
               ),
               SizedBox(height: 10),
               if(widget.terminToUpdate)ListTile(
                 title: Text("${S.current.date}: ${DateFormat("dd.MM.yyyy").format(_selectedDate)}"),
                 trailing: Icon(Icons.calendar_today),
                 onTap: () async {
                   DateTime? picked = await pickDate(_selectedDate);
                   if (picked != null) {
                     setState(() => _selectedDate = picked);
                   }
                 },
               ),
               ListTile(
                 title: Text("${S.current.timeStart}: ${_startTime.format(context)}"),
                 trailing: Icon(Icons.access_time),
                 onTap: () async {
                   TimeOfDay? picked = await pickTime(_startTime);
                   if (picked != null) {
                     setState(() {
                       _startTime = picked;
                       _endTime = TimeOfDay(hour: picked.hour+1, minute: picked.minute);
                     });
                   }
                 },
               ),
               ListTile(
                 title: Text("${S.current.timeEnd}: ${_endTime.format(context)}"),
                 trailing: Icon(Icons.access_time),
                 onTap: () async {
                   TimeOfDay? picked = await pickTime(_endTime);
                   if (picked != null) {
                     setState(() => _endTime = picked);
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
                   itemCount: _weekdays.length,
                   itemBuilder: (context, index) {
                     final isSelected = _selectedWeekdays.contains(index);
                     return GestureDetector(
                       onTap: () {
                         setState(() {
                           if (isSelected) {
                             _selectedWeekdays.remove(index);
                             _sliderValues.remove(index);

                             _selectedWeekdays.sort();
                           } else {
                             _selectedWeekdays.add(index);
                             _sliderValues[index] = 0;
                             _selectedWeekdays.sort();

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
                         child: FittedBox(
                           child: Text(
                             _weekdays[index],
                             style: TextStyle(
                               color: isSelected ? Colors.white : Colors.black,
                               fontWeight: FontWeight.w500,
                             ),
                             textAlign: TextAlign.center,
                           ),
                         ),
                       ),
                     );
                   },
                 ),
                 SizedBox(height: 25,),
                 _selectedWeekdays.isNotEmpty ? Flexible(
                     child: Material(
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
                                 Text(S.current.tooltip_variation),
                                 Tooltip(
                                   message: S.current.tooltip_variation_text,
                                   showDuration: Duration(seconds: 5),
                                   child: Icon(Icons.help_outline_sharp),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 10),
                             Expanded(
                               child: ListView.builder(
                                 itemCount: _selectedWeekdays.length,
                                 itemBuilder: (context, index) {
                                   final weekdayIndex = _selectedWeekdays[index];
                                   return ListTile(
                                     shape: RoundedRectangleBorder(),
                                     leading: Text(_weekdays[weekdayIndex]),
                                     title: Slider(
                                       value: _sliderValues[weekdayIndex]!.toDouble(),
                                       onChanged: (ev) {
                                         setState(() {
                                           _sliderValues[weekdayIndex] = ev.toInt();
                                         });
                                       },
                                       divisions: 24,
                                       max: 60,
                                       min: -60,
                                       label: "${_sliderValues[weekdayIndex]} min",
                                     ),
                                     trailing: Text("${_sliderValues[weekdayIndex]} min"),
                                   );
                                 },
                               ),
                             ),
                           ],
                         ),
                       ),
                     )
                 ) : Flexible(child: Container(color: Colors.transparent,))
               },
               if(widget.terminToUpdate) Spacer(),
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
                             child: Text(S.current.cancel,style: TextStyle(color: Theme.of(context).primaryColorDark)),
                           ),
                           TextButton(
                             style: TextButton.styleFrom(
                                 elevation: 10,
                                 backgroundColor: Theme.of(context).primaryColorLight,
                                 minimumSize: Size(150, 40)
                             ),
                             onPressed: () {
                               if (_nameController.text.isNotEmpty) {
                                 if(widget.terminToUpdate){
                                   DateTime newStartTime = _selectedDate.add(Duration(hours: _startTime.hour, minutes: _startTime.minute));
                                   DateTime newEndTime = _selectedDate.add(Duration(hours: _endTime.hour, minutes: _endTime.minute));
                                   if(_endTime.isBefore(_startTime)){
                                     newEndTime = newEndTime.add(Duration(days: 1));
                                   }
                                   Termin t = Termin(
                                     name: _nameController.text,
                                     startTime: newStartTime,
                                     endTime: newEndTime,
                                   );
                                   Navigator.of(context).pop(t);
                                 } else {
                                   if(_selectedWeekdays.isEmpty) {
                                     if(mounted){
                                       Utilities().showFloatingSnackBar(context, S.current.termin_creator_no_day_selected);
                                     }
                                     return;
                                   }
                                   for(int i = 0; i < _selectedWeekdays.length; i++){
                                     int day = _selectedWeekdays[i];
                                     DateTime iterativeStartTime = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, _startTime.hour, _startTime.minute);
                                     DateTime iterativeEndTime = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, _endTime.hour, _endTime.minute);
                                     if(_endTime.isBefore(_startTime)){
                                       iterativeEndTime = iterativeEndTime.add(Duration(days: 1));
                                     }
                                     iterativeStartTime = iterativeStartTime.add(Duration(days: day));
                                     iterativeStartTime = iterativeStartTime.add(Duration(minutes: _sliderValues[_selectedWeekdays[i]]!));

                                     iterativeEndTime = iterativeEndTime.add(Duration(days: day));
                                     iterativeEndTime = iterativeEndTime.add(Duration(minutes: _sliderValues[_selectedWeekdays[i]]!));

                                     Termin t = Termin(name: _nameController.text, startTime: iterativeStartTime, endTime: iterativeEndTime);
                                     DatabaseHelper().insertTermin(t, widget.personId);
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
                             child: Text(S.current.save,style: TextStyle(color: Theme.of(context).primaryColorDark),),
                           ),
                         ],
                       ),
                       if(widget.terminToUpdate)TextButton(
                           onPressed: (){
                             DatabaseHelper().deleteTermin(widget.personId, Termin(name: widget.existingName!, startTime: widget.existingStartTime!, endTime: widget.existingEndTime!));
                             Navigator.of(context).pop(true);
                           },
                           child: Container(
                               width: MediaQuery.of(context).size.width*0.75,
                               height: 40,
                               decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(20),
                                   color: Colors.redAccent.shade200.withAlpha(120)
                               ),
                               child: Center(child: Text(S.current.delete, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 20),),)

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