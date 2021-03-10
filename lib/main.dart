import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:voices_for_christ/helpers/minimize_keyboard.dart';
import 'package:voices_for_christ/screens/home_screen.dart';
import 'package:voices_for_christ/screens/search.dart';
import 'package:voices_for_christ/ui/dark_theme.dart';
import 'package:voices_for_christ/ui/light_theme.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  .then((_) {
    runApp(MyApp(
      initialTheme: 'light',
    ));
  });
}

class MyApp extends StatefulWidget {
  const MyApp({ Key key, this.initialTheme }) : super(key: key);
  final String initialTheme;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String appTheme;

  @override
  void initState() {
    super.initState();
    setState(() {
      appTheme = widget.initialTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voices for Christ',
      //home: AudioServiceWidget(child: HomeScreen()),
      /*initialRoute: '/',
      routes: {
        '/': (BuildContext context) => MainScaffold(pageIndex: 0),
        '/favorites': (BuildContext context) => MainScaffold(pageIndex: 1),
      },*/
      home: MainScaffold(
        toggleTheme: () {
          setState(() {
            appTheme = appTheme == 'light' ? 'dark' : 'light';
          });
        },
      ),
      theme: appTheme == 'light' ? lightTheme : darkTheme,
      debugShowCheckedModeBanner: false,
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
        collapsed: Container(
          alignment: Alignment.bottomCenter,
          child: Text('Panel'),
        ),
        panel: Container(
          alignment: Alignment.bottomCenter,
          color: Theme.of(context).bottomAppBarColor,
          child: Text('Panel'),
        ),
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
      resizeToAvoidBottomPadding: false,
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