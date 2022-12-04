import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:google_fonts/google_fonts.dart';


import 'firebase_options.dart';
import 'home.dart';
import 'tabs/login.dart';

User? user;
bool isDesktop = (defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.windows) &&
    !kIsWeb;
bool isDyslexic = false;


String theme = "Default";
var dict = {};



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  user = FirebaseAuth.instance.currentUser;

  runApp(const MyApp());
}

class MyApp<T> extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}



class _MyAppState<T> extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    dict  = {
      "Default" :
      ThemeData(
          primarySwatch: Colors.grey,
          dialogBackgroundColor: const Color(0xffcccccc),
          scaffoldBackgroundColor: const Color(0xff445756),
          cardColor: const Color(0xff708f8d),
          textTheme: isDyslexic ? GoogleFonts.lexendDecaTextTheme() : GoogleFonts.nunitoSansTextTheme(),
          primaryColor: Colors.black,
          highlightColor: Colors.blue,
          primaryColorLight: Colors.grey
      ),
      "Dark Mode" :
      ThemeData(
          primarySwatch: Colors.grey,
          dialogBackgroundColor: const Color(0xff3d3d3d),
          scaffoldBackgroundColor: const Color(0xff445756),
          cardColor: Colors.blueGrey.shade800,
          textTheme: isDyslexic ? GoogleFonts.lexendDecaTextTheme() : GoogleFonts.nunitoSansTextTheme(),
          primaryColor: Colors.white,
          highlightColor: Colors.blue,
          primaryColorLight: Colors.white
      ),
    };

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CENT - Exploration Tool',
        theme: dict[theme],
        initialRoute: '/home',
        routes: {
          '/home': (context) => const Home(),
          '/login': (context) => const Login(),
        }
    );
  }
}
