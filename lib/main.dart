import 'dart:async';
import 'package:devinci/pages/login.dart';
import 'package:devinci/libraries/feedback/feedback.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:devinci/extra/globals.dart' as globals;
import 'package:devinci/libraries/devinci/extra/functions.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:quick_actions/quick_actions.dart';
import './config.dart';

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  globals.prefs = await SharedPreferences.getInstance();
  String setTheme = globals.prefs.getString("theme") ?? "Système";
  if (setTheme != "Système") {
    globals.currentTheme.setDark(setTheme == "Sombre");
  } else {
    globals.currentTheme.setDark(
        SchedulerBinding.instance.window.platformBrightness == Brightness.dark);
  }
  //init quick_actions
  final QuickActions quickActions = new QuickActions();
  quickActions.initialize(quick_actions_callback);
  quickActions.setShortcutItems(<ShortcutItem>[
    const ShortcutItem(
        type: 'action_edt', localizedTitle: 'EDT', icon: 'icon_edt'),
    const ShortcutItem(
        type: 'action_notes', localizedTitle: 'Notes', icon: 'icon_notes'),
  ]);
  SyncfusionLicense.registerLicense(
      Config.syncfusionLicense); //initialisation des widgets

  // initialisation du système de notifications.
  globals.notificationAppLaunchDetails = await globals
      .flutterLocalNotificationsPlugin
      .getNotificationAppLaunchDetails();
  // Note: Les permissions pour les notifications ne sont pas demandées à ce niveau parce qu'elles sont déjà demandées en bas niveau, en swift dans AppDelegate.swift pour iOS et en Kotlin dans MainActivity.kt lors du premier démarrage de l'app
  await globals.flutterLocalNotificationsPlugin.initialize(
      globals.initializationSettings,
      onSelectNotification: onSelectNotification);

  // Fin init notifications

  // Ceci capture les erreurs renvoyées par Flutter
  FlutterError.onError = (FlutterErrorDetails details) async {
    if (isInDebugMode) {
      // en developpement on print dans la console
      FlutterError.dumpErrorToConsole(details);
    } else {
      // En mode production on renvoit les données à la Zone qui va s'occuper de les transferer a Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  // This creates a [Zone] that contains the Flutter application and stablishes
  // an error handler that captures errors and reports them.
  //
  // Using a zone makes sure that as many errors as possible are captured,
  // including those thrown from [Timer]s, microtasks, I/O, and those forwarded
  // from the `FlutterError` handler.
  //
  // More about zones:
  //
  // - https://api.dartlang.org/stable/1.24.2/dart-async/Zone-class.html
  // - https://www.dartlang.org/articles/libraries/zones
  runZonedGuarded<Future<Null>>(() async {
    runApp(
      BetterFeedback(
          // BetterFeedback est une librairie qui permet d'envoyer un feedback avec une capture d'écran de l'app, c'est pourquoi on lance l'app dans BetterFeedback pour qu'il puisse se lancer par dessus et prendre la capture d'écran.
          child: Phoenix(
            // Phoenix permet de redemarrer l'app sans vraiment en sortir, c'est utile si l'utilisateur se déconnecte afin de lui représenter la page de connexion.
            child: MyApp(),
          ),
          onFeedback: betterFeedbackOnFeedback),
    );
  }, (error, stackTrace) async {
    //si une erreur est détectée par la Zone
    await reportError(error, stackTrace);
  });
  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    globals.currentTheme.addListener(() {
      print("changes");
      setState(() {});
    });
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    globals.currentContext = context;
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('fr'),
      ],
      locale: const Locale('fr'),
      title: 'Devinci',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: Colors.teal,
        accentColor: Colors.teal[800],
        textSelectionColor: Colors.teal[900],
        textSelectionHandleColor: Colors.teal[800],
        cursorColor: Colors.teal,
        scaffoldBackgroundColor: Color(0xffFAFAFA),
        cardColor: Colors.white,
        indicatorColor: Colors.teal[800],
        accentIconTheme: IconThemeData(color: Colors.black),
        unselectedWidgetColor: Colors.black,
        fontFamily: 'ProductSans',
        textTheme: TextTheme(
          headline1: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 36,
            color: Colors.black,
          ),
          bodyText1: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        accentColor: Colors.tealAccent[200],
        textSelectionColor: Colors.tealAccent[700],
        textSelectionHandleColor: Colors.tealAccent[200],
        cursorColor: Colors.teal,
        backgroundColor: Color(0xff121212),
        scaffoldBackgroundColor: Color(0xff121212),
        cardColor: Color(0xff1E1E1E),
        indicatorColor: Colors.tealAccent[200],
        accentIconTheme: IconThemeData(color: Colors.white),
        unselectedWidgetColor: Colors.white,
        fontFamily: 'ProductSans',
        textTheme: TextTheme(
          headline1: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 36,
            color: Colors.white,
          ),
          bodyText1: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: globals.currentTheme.currentTheme(),
      home: LoginPage(title: 'Devinci'),
      debugShowCheckedModeBanner: false,
    );
  }
}