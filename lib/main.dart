import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/ui/dark_theme.dart';
import 'package:voices_for_christ/ui/light_theme.dart';
import 'package:voices_for_christ/screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // needed because of async work in initializePlayer()
  
  var model = MainModel();
  await model.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  .then((_) async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme');

    runApp(MyApp(model: model, initialTheme: theme));
  });
}

class MyApp extends StatefulWidget {
  const MyApp({ Key key, this.initialTheme, this.model }) : super(key: key);
  final String initialTheme;
  final MainModel model;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String appTheme;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    setState(() {
      appTheme = widget.initialTheme;
    });
  }

  void _toggleTheme() async {
    setState(() {
      appTheme = appTheme == 'light' ? 'dark' : 'light';
    });
    prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', appTheme);
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainModel>(
      model: widget.model, 
      child: MaterialApp(
        title: 'Voices for Christ',
        home: MainScaffold(
          toggleTheme: () {
            _toggleTheme();
          },
        ),
        theme: appTheme == 'light' ? lightTheme : darkTheme,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}