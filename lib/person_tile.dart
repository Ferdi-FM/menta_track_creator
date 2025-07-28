import 'dart:io';
import 'dart:typed_data';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:menta_track_creator/full_screen_image_viewer.dart';
import 'package:menta_track_creator/helper_utilities.dart';
import 'package:menta_track_creator/person.dart';
import 'package:menta_track_creator/person_page.dart';
import 'main.dart';

class PersonTile extends StatelessWidget {
   final Person person;
   final int index;
   final VoidCallback deleteEntry;
   final VoidCallback editEntry;

  const PersonTile({
    super.key,
    required this.person,
    required this.index,
    required this.deleteEntry,
    required this.editEntry,
  });

   Future<Uint8List?> compressImage(String filePath, BuildContext context, int? width) async {
     final file = File(filePath);
     if (!await file.exists() || !context.mounted) return null;

     int targetWidth = width ?? (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(); //Wenn keine width angegebn wird, ist das Bild maximal so groß wie die Bildschirmauflösung

     final result = await FlutterImageCompress.compressWithFile(
       file.absolute.path,
       minWidth: targetWidth,
       quality: 75,
       format: CompressFormat.jpeg,
     );

     return result;
   }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key(person.id.toString()),
      padding: EdgeInsets.only(top: index == 0 ? 20 : 0),
      child:  GestureDetector(
          onTapUp: (ev){
            var pos = ev.globalPosition;
            navigatorKey.currentState?.push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PersonDetailPage(person: person),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const curve = Curves.easeInOut;

                    var tween = Tween<double>(begin: 0.1, end: 1.0).chain(CurveTween(curve: curve));
                    var scaleAnimation = animation.drive(tween);

                    return ScaleTransition(
                      scale: scaleAnimation,
                      alignment: Alignment(0, pos.dy / MediaQuery.of(context).size.height * 2 - 1),
                      child: child,
                    );
                  },
                )
            );
          },
          child:Card(
              color: Colors.red,
              elevation: 10,
              margin: EdgeInsets.symmetric(vertical: 4,horizontal: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child:
              Dismissible(
                  direction: DismissDirection.startToEnd,
                  onDismissed: (ev){
                    deleteEntry();
                  },
                  confirmDismiss: (ev) async {
                    return await Utilities().showDeleteConfirmation(context,person.name);
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.red
                    ),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  key: Key(person.id.toString()),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        //color: Theme.of(context).listTileTheme.tileColor
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Theme.of(context).primaryColorLight,
                              Theme.of(context).listTileTheme.tileColor ?? Colors.blueGrey,
                            ]
                        )
                    ),
                    child:  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            height: MediaQuery.of(context).size.height * 0.15,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              child: person.imagePath!.isNotEmpty
                                  ? GestureDetector(
                                      onTapDown: (ev){
                                        FullScreenImageViewer(path: person.imagePath!,).showFullScreenImage(ev.globalPosition);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.fromBorderSide(
                                                BorderSide(
                                                    width: 0.75
                                                )
                                            )
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child:  FutureBuilder<Uint8List?>(
                                            future: compressImage(person.imagePath!, context, 70),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return Center(child: CircularProgressIndicator(),);
                                              } else if (snapshot.hasData && snapshot.data != null) {
                                                return Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.fitHeight,
                                                );
                                              } else {
                                                return Icon(Icons.person, size: 50,);
                                              }
                                            },
                                          ),
                                        ),
                                      ) ,
                                    )
                                  : Icon(Icons.person, size: 50,),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: AutoSizeText(person.name, textAlign: TextAlign.start, minFontSize: 16,),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: Padding(
                                padding: EdgeInsets.all(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        editEntry();
                                      },
                                      icon: Icon(Icons.edit, size: 30,),
                                    )
                                  ],
                                )
                            ),
                          ),
                        ],
                      ),
                    ) ,
                  )
              )
          )
    );
  }
}