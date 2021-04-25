import 'package:flutter/material.dart';

class PlaylistsPage extends StatefulWidget {
  PlaylistsPage({Key key}) : super(key: key);

  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  @override
  void initState() { 
    super.initState();
    print('initiating playlists state');
  }

  @override
  Widget build(BuildContext context) {
    print('building playlists');
    return Container(
      child: Center(
        child: Text('Playlists page')
      ),
    );
  }
}