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
  //WidgetsFlutterBinding.ensureInitialized(); // needed because of async work in initializePlayer()

  //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  //.then((_) {
    runApp(MyApp());
  //});
  /*.then((_) async { // moved down to try to fix freezing bug
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    runApp(MyApp(model: model));
  });*/
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MainModel mainModel;
  bool _loading = true;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    doMainSetup();
  }

  void updateLoadingMessage(String newMessage) {
    setState(() {
      _loadingMessage = newMessage;
    });
  }

  void doMainSetup() async {
    mainModel = MainModel();
    updateLoadingMessage('Loading settings...');
    await mainModel.loadSettings();
    updateLoadingMessage('Loading recommendations...');
    await mainModel.loadRecommendations();
    
    // moved here to try to fix freezing bug
    updateLoadingMessage('Configuring audio session...');
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // end moved block

    updateLoadingMessage('Initializing audio player...');
    await mainModel.initializePlayer(onChangedMessage: (Message message) {
      mainModel.updateDownloadedMessage(message);
      mainModel.updateFavoritedMessage(message);
      mainModel.updateMessageInCurrentPlaylist(message);
    });

    await mainModel.initialize(updateLoadingMessage);
    //await widget.model.loadSettings();
    updateLoadingMessage('');
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: 'Voices for Christ',
        home: Scaffold(
          body: Container(
            color: Color(0xff002D47),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                  child: Text(_loadingMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18.0,
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ScopedModel<MainModel>(
      model: mainModel, 
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