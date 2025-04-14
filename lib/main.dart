import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/person_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.dark;//Darkmode als standard
  MaterialColor accentColorOne = Colors.lightBlue;
  Color accentColorTwo = Colors.lightBlue;
  MaterialColor seedColor = Colors.cyan;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MentATrack Creator",
      navigatorKey: navigatorKey,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [
        const Locale("de", "DE"),
        const Locale("en", "GB"),
      ],
      theme: ThemeData(
        fontFamily: "Comfortaa",
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light),
        primaryColor: accentColorTwo,
        appBarTheme: AppBarTheme(color: accentColorOne.shade300,foregroundColor: Colors.black87),
        scaffoldBackgroundColor: accentColorOne.shade50,
        listTileTheme: ListTileThemeData(
          tileColor: Colors.white,
          textColor: Colors.black,
          iconColor: accentColorTwo,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: accentColorOne.shade100,
          selectedItemColor:accentColorOne.shade700 ,
          unselectedItemColor: Colors.black87,
          enableFeedback: true,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: "Comfortaa",
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        primaryColor: accentColorTwo,
        appBarTheme: AppBarTheme(color: accentColorOne.shade400, foregroundColor: Colors.black87, iconTheme: IconThemeData(color: Colors.black87)),
        scaffoldBackgroundColor: Colors.blueGrey.shade800,
        listTileTheme: ListTileThemeData(
          tileColor: Colors.grey.shade600,
          textColor: Colors.white,
          iconColor: accentColorTwo,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.transparent,  //Colors.blueGrey.shade700.withAlpha(100),
            selectedItemColor: accentColorOne.shade400,
            unselectedItemColor: Colors.white70,
            enableFeedback: true
        ),
        iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
                foregroundColor: accentColorOne.shade300
            )
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: MyHomePage(),
    );
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      this.themeMode = themeMode;
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<Person> persons = [];
  TextEditingController searchController = TextEditingController();
  bool themeModeBool = true;

  @override
  void initState(){
    super.initState();
    loadList();
    loadTheme();
  }

  Future<void> loadTheme() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    themeModeBool = pref.getBool("darkMode") ?? ThemeMode.system == ThemeMode.dark ? true : false;
    if(mounted) MyApp.of(context).changeTheme(themeModeBool ? ThemeMode.dark : ThemeMode.light);
    setState(() {
      themeModeBool;
    });
  }

  Future<void> loadList() async {
    persons = await DatabaseHelper().getPersons("");
    setState(() {
      persons;
    });
  }

  Future<void> searchPersons(String s)async {
    persons = await DatabaseHelper().getPersons(s);
    setState(() {
      persons;
    });
  }

  void _addPerson(String firstName, String lastName) {
    setState(() {
      persons.add(Person(name: "$firstName $lastName"));
      DatabaseHelper().insertPerson(firstName, lastName);
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
          title: Text('Neue Person hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'Vorname'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Nachname'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hinzufügen'),
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
          title: Text("Personen"),
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
                                value: themeModeBool,
                                onChanged: (ev) async {
                                  themeModeBool = ev;
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
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search",
                border: OutlineInputBorder(),
              ),
              onChanged: (ev){
                searchPersons(ev);
              },
            ),
            SizedBox(height: 20,),
            if(persons.isEmpty) Padding(padding: EdgeInsets.symmetric(vertical: 100), child: Text("Noch keine Personen gespeichert", textAlign: TextAlign.center, style: TextStyle(fontSize: 28))),
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
                    itemCount: persons.length,
                    itemBuilder: (context, index) {
                      final person = persons[index];
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
                                      persons.removeAt(index);
                                      DatabaseHelper().deletePerson(person.name);
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
        tooltip: "Neue Person",
        child: Icon(Icons.person_add_alt_1),
      ),
    );
  }
}

class Person {
  String name;

  Person({required this.name});
}
