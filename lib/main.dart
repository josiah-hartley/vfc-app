import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/ui/dark_theme.dart';
import 'package:voices_for_christ/ui/light_theme.dart';
import 'package:voices_for_christ/screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // needed because of async work in initializePlayer()
  
  var model = MainModel();
  await model.loadSettings();
  await model.loadRecommendations();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  .then((_) async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    runApp(MyApp(model: model));
  });
}

class MyApp extends StatefulWidget {
  MyApp({Key key, this.model}) : super(key: key);
  final MainModel model;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() { 
    super.initState();
    widget.model.initializePlayer(onChangedMessage: (Message message) {
      widget.model.updateDownloadedMessage(message);
      widget.model.updateFavoritedMessage(message);
      widget.model.updateMessageInCurrentPlaylist(message);
    });
    widget.model.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainModel>(
      model: widget.model, 
      child: ScopedModelDescendant<MainModel>(
        builder: (context, child, model) {
          return MaterialApp(
            title: 'Voices for Christ',
            home: MainScaffold(),
            theme: model.darkMode == true ? darkTheme : lightTheme,
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
}