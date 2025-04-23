import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'main_page.dart';

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
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        //Locale("en", "US"),
        Locale("en", "GB"),
        Locale("de", "DE"),
        // Füge hier weitere Sprachen hinzu
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
            backgroundColor: Colors.blueGrey.shade700.withAlpha(200),  //Colors.blueGrey.shade700.withAlpha(100),
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


