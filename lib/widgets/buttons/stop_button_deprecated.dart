import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';

class StopButton extends StatelessWidget {
  const StopButton({Key key, this.message}) : super(key: key);
  final Message message;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        return Container(
          child: TextButton(
            child: Text('Pause'),
            onPressed: () { model.pause(); },
          ),
        );
      }
    );
  }
}