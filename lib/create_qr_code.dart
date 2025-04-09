import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:menta_track_creator/termin_dialogue.dart';
import 'package:qr_flutter/qr_flutter.dart';

///Klasse für alle möglichen nützlichen funktionen, die Appübergreifend genutzt werden können aber keine eigene Klasse rechtfertigen

class CreateQRCode{

  CreateQRCode();

  /// Funktion, die den QR-Code in einem Dialog anzeigt
  void showQrCode(BuildContext context, List<Termin> list) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("QR Code"),
          content:  SizedBox(
            width: MediaQuery.of(context).size.width*0.8,
            child: Padding(
              padding: EdgeInsets.all(0),
              child: QrImageView(
                backgroundColor: Colors.white,
                version: QrVersions.auto,
                data: toCompressedList(list),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Schließen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String toCompressedList(List<Termin> list){
    List<Map<String,String>> map = [];
    for(Termin t in list){
      Map<String,String> tMap = {
        "tN": t.name,
        "tB": t.startTime.toIso8601String(),
        "tE": t.endTime.toIso8601String()
      };
      map.add(tMap);
    }

    //Json zu String
    String unCompressedString = jsonEncode(map);
    // String in Bytes
    List<int> bytes = utf8.encode(unCompressedString);
    // GZip-Kompression mit GZipCodec
    var codec = GZipCodec();
    List<int> compressedData = codec.encode(bytes);
    // Komprimierte List<int> in Base64 kodieren
    String base64EncodedString = base64Encode(compressedData);

    return base64EncodedString;
  }
}