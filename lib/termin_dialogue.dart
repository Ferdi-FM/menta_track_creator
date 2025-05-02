import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menta_track_creator/termin.dart';

class TerminDialog {
  final DateTime startDate;
  final DateTime endDate;

  final DateTime? existingStartTime;
  final DateTime? existingEndTime;

  const TerminDialog({
    required this.startDate,
    required this.endDate,
    this.existingStartTime,
    this.existingEndTime
  });

  Future<Termin?> show(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    DateTime selectedDate;
    TimeOfDay startTime;
    TimeOfDay endTime;

    if(existingStartTime != null){
      selectedDate = existingStartTime!;
      startTime = TimeOfDay.fromDateTime(existingStartTime!);
      endTime = TimeOfDay.fromDateTime(existingEndTime!);
    } else {
      selectedDate = startDate;
      startTime = TimeOfDay.fromDateTime(DateTime.now());
      endTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(minutes: 30)));
    }


    Future<DateTime?> pickDate(DateTime? initialDate) async {
      return await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: startDate,
        lastDate: endDate,
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

    return showDialog<Termin>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Termin festlegen"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Termin Name"),
                    onTapOutside: (ev){
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  SizedBox(height: 10),
                  ListTile(
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
                        setState(() => startTime = picked);
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Abbrechen"),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Navigator.pop(
                        context,
                        Termin(
                          name: nameController.text,
                          startTime: selectedDate.add(Duration(hours: startTime.hour, minutes: startTime.minute)),
                          endTime: selectedDate.add(Duration(hours: endTime.hour, minutes: endTime.minute)),
                        ),
                      );
                    }
                  },
                  child: Text("Speichern"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
