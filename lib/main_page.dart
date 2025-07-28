import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/person.dart';
import 'package:menta_track_creator/person_tile.dart';
import 'package:menta_track_creator/photo_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'generated/l10n.dart';
import 'helper_utilities.dart';
import 'main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<Person> _persons = [];
  final TextEditingController _searchController = TextEditingController();
  bool _themeModeBool = true;
  late Database db;

  @override
  void initState(){
    super.initState();
    loadList();
    loadTheme();
  }

  Future<void> loadTheme() async {
    db = await DatabaseHelper().database;
    SharedPreferences pref = await SharedPreferences.getInstance();
    _themeModeBool = pref.getBool("darkMode") ?? ThemeMode.system == ThemeMode.dark ? true : false;
    if(mounted) MyApp.of(context).changeTheme(_themeModeBool ? ThemeMode.dark : ThemeMode.light);
    setState(() {
      _themeModeBool;
    });
  }

  Future<void> loadList() async {
    _persons = await DatabaseHelper().getPersons("");
    setState(() {
      _persons;
      _persons.sort((a,b) => a.sortIndex.compareTo(b.sortIndex));
    });
  }

  Future<void> searchPersons(String s)async {
    _persons = await DatabaseHelper().getPersons(s);
    setState(() {
      _persons;
      _persons.sort((a,b) => a.sortIndex.compareTo(b.sortIndex));
    });
  }

  Future<void> _addPerson(String name, String imagePath) async {
    final id = await DatabaseHelper().insertPerson(name, imagePath, _persons.length);
    setState(() {
      _persons.add(Person(id: id, name: name, imagePath: imagePath, sortIndex: _persons.length));
    });
  }

  Future<bool?> _showAddPersonDialog([Person? person]) async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    XFile? image;
    String imagePath = "";
    if(person != null){
      firstNameController.text = person.name.split(" ").first;
      lastNameController.text = person.name.split(" ").last;
      imagePath = person.imagePath!;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: Text(S.current.main_newPerson),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(labelText: S.current.main_firstname),
                      onTapOutside: (ev) => FocusScope.of(context).unfocus(),
                    ),
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(labelText: S.current.main_surname),
                      onTapOutside: (ev) => FocusScope.of(context).unfocus(),
                    ),
                    SizedBox(height: 20,),
                    Row(
                      children: [
                        Text(imagePath.isEmpty ? S.current.main_addImage : S.current.main_changeImage),
                        Spacer(),
                        if(imagePath.isNotEmpty) IconButton(
                            onPressed: (){
                              setState((){
                                image = null;
                                imagePath = "";
                              });

                            },
                            icon: Icon(Icons.delete)),
                        IconButton(
                          onPressed: () async {
                            Map<String, dynamic> photo = await  PhotoHelper().takePhotoAndSave();
                            if(photo.isNotEmpty){
                              setState(() {
                                image = photo["photo"];
                                imagePath = photo["imagePath"];
                              });
                            }
                          },
                          icon: Icon(Icons.add_a_photo),
                        )
                      ],
                    ),
                    SizedBox(height: 10,),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height*0.3
                        ),
                        child: person != null && imagePath.isNotEmpty && image == null
                            ? Image.file(File(imagePath))
                            :  Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.fromBorderSide(
                              BorderSide(
                                width: 2,
                                color: Colors.black87
                              )
                            )
                          ),
                          child: image == null
                              ? Padding(padding: EdgeInsets.all(5),child: Text(S.current.main_imageInfo, textAlign: TextAlign.center,),)
                              : Image.file(File(image!.path)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.current.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: person == null ? Text(S.current.add) : Text(S.current.update),
                  onPressed: () {
                    String name = "${firstNameController.text} ${lastNameController.text}";
                    person == null
                        ? _addPerson(name, imagePath)
                        : DatabaseHelper().updatePerson(person.id, name, imagePath);
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.main_persons),
        actions: [
          Utilities().getHelpBurgerMenu(context, "mainPage")
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:[Theme.of(context).scaffoldBackgroundColor, Theme.of(context).primaryColorLight],
            stops: [0.5,1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              SizedBox(height: 10,),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: S.current.main_search,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                ),
                onChanged: (ev){
                  searchPersons(ev);
                },
                onTapOutside: (ev){
                  FocusScope.of(context).unfocus();
                },
              ),
              SizedBox(height: 20,),
              if(_persons.isEmpty) Padding(padding: EdgeInsets.symmetric(vertical: 100), child: Text(S.current.main_noPerson, textAlign: TextAlign.center, style: TextStyle(fontSize: 28))),
              Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent
                        ],
                        stops: [0.0, 0.04, 0.95, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ReorderableListView.builder(
                        itemCount: _persons.length,
                        itemBuilder: (context, index) {
                          final person = _persons[index];
                          return PersonTile(
                              key: Key(person.id.toString()),
                              person: person,
                              index: index,
                              deleteEntry: () async {
                                setState(() {
                                  _persons.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(S.current.entry_deleted),
                                    action: SnackBarAction(
                                      label: S.current.comment_undo,
                                      onPressed: () {
                                        setState(() {
                                          _persons.insert(index, person);
                                        });
                                      },
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                await Future.delayed(Duration(seconds: 3), () async {
                                  if(!_persons.contains(person)){
                                    await DatabaseHelper().deletePerson(person.id);
                                    if(context.mounted) DatabaseHelper().updatePersonList(_persons, context);
                                  }
                                });
                              },
                              editEntry: () async {
                                bool? result = await _showAddPersonDialog(person);
                                if(result != null){
                                  loadList();
                                }
                              });
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 15,
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        onReorder: (int oldIndex, int newIndex) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _persons.removeAt(oldIndex);
                            _persons.insert(newIndex, item);
                            DatabaseHelper().updatePersonList(_persons, context);
                          });
                        }

                    ),
                  )
              ).animate().fadeIn(delay: (300).ms, duration: 700.ms, curve: Curves.easeInOut, begin: 0),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonDialog,
        tooltip: S.current.main_newPerson,
        child: Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
