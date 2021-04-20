/*import 'package:flutter/material.dart';
//import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
//import 'package:just_audio/just_audio.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/scoped_models/player_model.dart';
import 'package:voices_for_christ/widgets/message_display/buttons/download_button.dart';

void main() async {
  /*MyAudioHandler _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelName: 'My Audio App',
      androidEnableQueue: true,
    ),
  );
  runApp(MyApp(audioHandler: _audioHandler,));*/
  WidgetsFlutterBinding.ensureInitialized(); // needed because of async work in initializePlayer()
  var playerModel = PlayerModel();
  playerModel.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  .then((_) {
    runApp(MyApp(playerModel: playerModel));
  });
}

class MyApp extends StatelessWidget {
  MyApp({Key key, this.playerModel}) : super(key: key);
  //final MyAudioHandler audioHandler;
  final PlayerModel playerModel;

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PlayerModel>(
      model: playerModel, 
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Message _defaultMessage;
  final db = MessageDB.instance;

  @override
  void initState() { 
    super.initState();
    loadInitialMessage();
  }

  void loadInitialMessage() async {
    Message msg = await db.queryOne(56823);
    setState(() {
      _defaultMessage = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PlayerModel>(
      builder: (context, child, model) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Audio Service Demo'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_defaultMessage?.title ?? ''),
                Text(model.currentlyPlayingMessage?.title ?? 'no current message'),
                Text(_defaultMessage?.filepath ?? ''),
                StreamBuilder<Duration>(
                  stream: model.currentPositionStream,
                  builder: (context, snapshot) {
                    final Duration position = snapshot.data ?? Duration(seconds:0);
                    return Text(position.inSeconds.toString());
                  }),
                StreamBuilder<bool>(
                  stream: model.playing,
                  builder: (context, snapshot) {
                    final bool p = snapshot.data ?? false;
                    return Text(p.toString());
                  }
                ),
                DownloadButton(message: _defaultMessage),
                TextButton(
                  child: Text('Play'),
                  onPressed: () async {
                    await model.setInitialMessage();
                    model.play();
                  },
                ),
                TextButton(
                  child: Text('Pause'),
                  onPressed: model.pause,
                )
              ],
            ),
          ),
        );
      }
    );
  }
}*/


import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:voices_for_christ/helpers/minimize_keyboard.dart';
import 'package:voices_for_christ/player/AudioPlayerTask.dart';
import 'package:voices_for_christ/player/player_panel_collapsed.dart';
import 'package:voices_for_christ/player/player_panel_expanded.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/scoped_models/player_model.dart';
import 'package:voices_for_christ/screens/home_screen.dart';
import 'package:voices_for_christ/screens/search.dart';
import 'package:voices_for_christ/ui/dark_theme.dart';
import 'package:voices_for_christ/ui/light_theme.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // needed because of async work in initializePlayer()
  var playerModel = PlayerModel();
  playerModel.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  .then((_) async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme');

    runApp(MyApp(playerModel: playerModel, initialTheme: theme));
  });
}

/*void _audioPlayerTaskEntryPoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}*/

class MyApp extends StatefulWidget {
  const MyApp({ Key key, this.initialTheme, this.playerModel }) : super(key: key);
  final String initialTheme;
  final PlayerModel playerModel;

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
    return ScopedModel<PlayerModel>(
      model: widget.playerModel, 
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

class MainScaffold extends StatefulWidget {
  MainScaffold({Key key, this.toggleTheme}) : super(key: key);
  final Function toggleTheme;

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  List<String> _routeNames = ['Home', 'Favorites'];
  List<int> _pageRoutes = [0];
  String _currentRouteName = 'Home';
  bool _searchWindowOpen = false;

  @override
  void initState() { 
    super.initState();
    //_initializeAudioService();
  }

  /*void _initializeAudioService() async {
    if (AudioService.running == false || AudioService.running == null) {
      print('starting');
      await AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
        androidNotificationChannelName: 'Voices for Christ',
        androidNotificationColor: 0xFF002D47,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
      );
    }
  }*/

  Future<bool> _handleBackButton() {
    // close window drawer if it's open
    if (_searchWindowOpen) {
      _closeSearchDrawer();
      return Future.value(false);
    }
    // otherwise, navigate back to last route
    if(_navigatorKey.currentState?.canPop() ?? false) {
      _navigatorKey.currentState?.pop();
      setState(() {
        _pageRoutes.removeLast();
        // update page header
        _currentRouteName = _routeNames[_pageRoutes.last] ?? '';
      });
      return Future.value(false);
    }
    // if the navigator stack is empty, close the application
    return Future.value(true);
  }

  void _openSearchDrawer() {
    setState(() {
      _searchWindowOpen = true;
    });
  }

  void _closeSearchDrawer() {
    setState(() {
      _searchWindowOpen = false;
    });
    minimizeKeyboard(context);
  }

  Widget _appBar(Function _openSearchDrawer) {
    return AppBar(
      title: Text(_currentRouteName.toUpperCase(),
        style: Theme.of(context).appBarTheme?.textTheme?.headline1,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings), 
          onPressed: () {
            widget.toggleTheme();
          }
        ),
        IconButton(
          icon: Icon(CupertinoIcons.search),
          onPressed: _openSearchDrawer
        ),
      ],
    );
  }

  Widget _mainPageSlidingPanelWrapper(BuildContext context) {
    return Container(
      child: SlidingUpPanel(
        minHeight: 50.0,
        maxHeight: 500.0,
        collapsed: PlayerPanelCollapsed(),
        panel: PlayerPanelExpanded(),
        body: _mainPageBody(context),
      ),
    );
  }

  Widget _mainPageBody(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          child: Container(
            child: Navigator(
              key: _navigatorKey,
              initialRoute: '/',
              onGenerateRoute: _onGenerateRoute,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).accentColor.withOpacity(0.6),
                  width: 1.0,
                )
              )
            ),
          ),
          padding: EdgeInsets.only(
            //top: 0.0,
            top: Scaffold.of(context).appBarMaxHeight,
            left: 15.0,
            right: 15.0
          ),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.65,
              colors: [
                Theme.of(context).dialogBackgroundColor, 
                Theme.of(context).backgroundColor,
              ]
            )
          ),
        );
      }
    );
  }

  Widget _mainScaffold() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: _appBar(_openSearchDrawer),
      body: _mainPageSlidingPanelWrapper(context),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Favorites',
          )
        ],
        currentIndex: _pageRoutes.last,
        onTap: (index) {
          switch (index) {
            case 0:
              _navigatorKey.currentState?.pushNamed('/');
              break;
            case 1:
              _navigatorKey.currentState?.pushNamed('/favorites');
              break;
            default:
              _navigatorKey.currentState?.pushNamed('/');
          }

          setState(() {
            _pageRoutes.add(index);
            _currentRouteName = _routeNames[index];
          });
        },
      ),
    );
  }

  Widget _searchDrawer() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      top: 0.0,
      left: _searchWindowOpen ? 0.0 : MediaQuery.of(context).size.width,
      child: Scaffold(
        body: SearchWindow(
          closeWindow: _closeSearchDrawer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // handle back button on Android
      onWillPop: _handleBackButton,
      child: Container(
        child: Stack(
          children: [
            _mainScaffold(),
            _searchDrawer(),
          ],
        ),
      ),
    );
  }

  Route _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = HomePage();
        break;
      case '/favorites':
        page = FavoritesPage();
        break;
      default:
        page = HomePage();
    }
    return PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => page,
      transitionDuration: Duration(seconds: 0),
    );
  }
}

/*BottomNavigationBar _bottomNavigationBar = BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home'
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.star),
      label: 'Favorites'
    )
  ],
  onTap: (index) {
    switch(index) {
      case 0:
        Navigator.pushNamed(context, 'home');
        break;
      case 1:
        Navigator.pushNamed(context, 'favorites');
        break;
      default:
        print(index);
    }
  },
);*/

class HomePage extends StatelessWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('building home');
    return Container(
      child: Container(
        alignment: Alignment.topCenter,
        child: Text('Home page')
      ),
    );
  }
}

/*class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('building favorites');
    return Container(
      child: Center(
        child: Text('Favorites page')
      ),
    );
  }
}*/

class FavoritesPage extends StatefulWidget {
  FavoritesPage({Key key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() { 
    super.initState();
    print('initiating favorites state');
  }

  @override
  Widget build(BuildContext context) {
    print('building favorites');
    return Container(
      child: Center(
        child: Text('Favorites page')
      ),
    );
  }
}