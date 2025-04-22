import 'package:flutter/material.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/person.dart';
import 'package:menta_track_creator/person_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'generated/l10n.dart';
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
    });
  }

  Future<void> searchPersons(String s)async {
    _persons = await DatabaseHelper().getPersons(s);
    setState(() {
      _persons;
    });
  }

  Future<void> _addPerson(String firstName, String lastName) async {
    final id = await DatabaseHelper().insertPerson(firstName, lastName);
    setState(() {
      _persons.add(Person(id: id,name: "$firstName $lastName"));
    });
  }

  Future<void> _showAddPersonDialog() async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.current.main_newPerson),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: S.current.main_firstname),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: S.current.main_surname),
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
              child: Text(S.current.add),
              onPressed: () {
                _addPerson(firstNameController.text, lastNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
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
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: MenuAnchor(
                menuChildren: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 10,),
                      Icon(Icons.dark_mode),
                      SizedBox(width: 10),
                      Switch(
                          value: _themeModeBool,
                          onChanged: (ev) async {
                            _themeModeBool = ev;
                            MyApp.of(context).changeTheme(ev ? ThemeMode.dark : ThemeMode.light);
                            SharedPreferences pref = await SharedPreferences.getInstance();
                            pref.setBool("darkMode", ev);
                          })
                    ],
                  ),
                ],
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return TextButton(
                    focusNode: FocusNode(),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: Icon(Icons.menu, size: 30, color: Theme.of(context).appBarTheme.foregroundColor,),
                  );
                }
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: S.current.main_search,
                border: OutlineInputBorder(),
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
                  child: ListView.builder(
                    itemCount: _persons.length,
                    itemBuilder: (context, index) {
                      final person = _persons[index];
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
                        child: Card(
                            color: Colors.white38,
                            elevation: 10,
                            margin: EdgeInsets.symmetric(vertical: 4,horizontal: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                            GestureDetector(
                              onTapDown: (ev){
                                var pos = ev.globalPosition;
                                navigatorKey.currentState?.push(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          PersonDetailPage(person: person),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const curve = Curves.easeInOut;

                                        // Erstelle eine Skalierungs-Animation
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
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7)
                                ),
                                leading: Icon(Icons.person),
                                title: Text(person.name),
                                trailing: IconButton(
                                    onPressed: (){
                                      setState(() {
                                        _persons.removeAt(index);
                                        DatabaseHelper().deletePerson(person.id);
                                      });
                                    },
                                    icon: Icon(Icons.delete)),
                              ),
                            )
                        ),
                      )

                      ;
                    },
                  ),
                )
            )
          ],
        ),)
      ,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonDialog,
        tooltip: S.current.main_newPerson,
        child: Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
