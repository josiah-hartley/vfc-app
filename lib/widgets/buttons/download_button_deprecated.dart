import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/files/downloads.dart';

class DownloadButton extends StatefulWidget {
  DownloadButton({Key key, this.message}) : super(key: key);
  final Message message;

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  String _buttonText = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _buttonText = getButtonText(widget?.message);
    });
  }

  String getButtonText(Message message) {
    String _text = '';
    if (message?.isdownloaded == 1) {
      _text = 'Done';
    } else {
      if (message?.iscurrentlydownloading == 1) {
        _text = 'Downloading...';
      } else {
        _text = 'Download';
      }
    }
    return _text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       child: TextButton(
         child: Text(_buttonText),
         onPressed: () {downloadMessage(widget.message);},
       ),
    );
  }

  void downloadMessage(Message message) async {
    if (message.isdownloaded == 1) {
      return;
    }

    message.iscurrentlydownloading = 1;
    setState(() {
      _buttonText = getButtonText(message);
    });

    try {
      Message result = await downloadMessageFile(message);
      message = result;
      message.iscurrentlydownloading = 0;
      setState(() {
        _buttonText = getButtonText(message);
      });
    }
    catch (error) {
      message.iscurrentlydownloading = 0;
      message.isdownloaded = 0;
      setState(() {
        _buttonText = getButtonText(message);
      });
    }
  }
}