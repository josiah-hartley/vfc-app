import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/helpers/device.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/helpers/logger.dart' as Logger;

class ErrorReportingDialog extends StatefulWidget {
  ErrorReportingDialog({Key key}) : super(key: key);

  @override
  _ErrorReportingDialogState createState() => _ErrorReportingDialogState();
}

class _ErrorReportingDialogState extends State<ErrorReportingDialog> {
  SharedPreferences _prefs;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _name = '';
  String _email = '';
  String _errorDescription = '';
  bool _saveContactInfo = true;
  bool _attachLogs = true;
  bool _submitting = false;
  bool _finishedSubmitting = false;

  @override
  void initState() { 
    super.initState();
    loadPreferences();
  }

  void loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = _prefs.getString('errorReportName') ?? '';
      _email = _prefs.getString('errorReportEmail') ?? '';
      _saveContactInfo = _prefs.getBool('errorReportSaveContactInfo') ?? true;
      _attachLogs = _prefs.getBool('errorReportAttachLogs') ?? true;
    });
    _nameController.text = _prefs.getString('errorReportName') ?? '';
    _emailController.text = _prefs.getString('errorReportEmail') ?? '';
  }

  void savePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (_saveContactInfo) {
      _prefs.setString('errorReportName', _name);
      _prefs.setString('errorReportEmail', _email);
    }
    _prefs.setBool('errorReportSaveContactInfo', _saveContactInfo);
    _prefs.setBool('errorReportAttachLogs', _attachLogs);
  }

  Future<List<String>> getLogs() async {
    return await Logger.getEventLogs();
  }

  void submitForm() async {
    setState(() {
      _submitting = true;
    });
    savePreferences();
    List<String> logs = await getLogs();
    String deviceInfo = await deviceData();
    Map<String, dynamic> json = {
      'name': _name,
      'email': _email,
      'error': _errorDescription,
      'device': deviceInfo,
      'appVersion': Constants.APP_VERSION,
      'logs': jsonEncode(logs)
    };
    Dio().post(Constants.CLOUD_ERROR_REPORT_URL, data: json);
    setState(() {
      _submitting = false;
      _finishedSubmitting = true;
      _errorDescription = '';
      if (!_saveContactInfo) {
        _name = '';
        _email = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10.0,
          sigmaY: 10.0,
        ),
        child: Container(
          color: Theme.of(context).backgroundColor.withOpacity(0.7),
          //padding: EdgeInsets.only(bottom: 10.0),
          child: Column(
            children: [
              _title(),
              _body(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_finishedSubmitting) {
      return _thankYouMessage();
    }
    if (_submitting) {
      return Container(
        padding: EdgeInsets.only(top: 50.0),
        child: CircularProgressIndicator(),
      );
    }
    return _form();
  }

  Widget _title() {
    List<Widget> _titleChildren = [
      GestureDetector(
        child: Container(
          color: Theme.of(context).backgroundColor.withOpacity(0.01),
          padding: EdgeInsets.only(left: 16.0, right: 30.0, top: 52.0, bottom: 26.0),
          child: Icon(CupertinoIcons.back, 
            size: 32.0,
            color: Theme.of(context).accentColor
          ),
        ),
        onTap: () { Navigator.of(context).pop(); },
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.only(top: 55.0, bottom: 25.0),
          child: Text('Report Error',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).primaryTextTheme.headline1.copyWith(
              fontSize: 20.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.only(right: 16.0),
      child: Row(
        children: _titleChildren,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Theme.of(context).accentColor
        ))
      ),
    );
  }

  Widget _form() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Material(
          color: Colors.transparent,
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                _input(
                  label: 'Name',
                  hintText: 'Name',
                  controller: _nameController,
                  maxLines: 1,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _name = val;
                    });
                  }
                ),
                _input(
                  label: 'Email Address',
                  hintText: 'Email Address',
                  controller: _emailController,
                  maxLines: 1,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email cannot be empty';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _email = val;
                    });
                  }
                ),
                _checkbox(
                  label: 'Save contact info for next time',
                  value: _saveContactInfo,
                  onChanged: () {
                    setState(() {
                      _saveContactInfo = !_saveContactInfo;
                    });
                  }
                ),
                _input(
                  label: 'Description of Error',
                  hintText: 'Write a short description of the error you encountered.  Please be specific, and include what you were doing when the error occurred.',
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Error description cannot be empty';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _errorDescription = val;
                    });
                  }
                ),
                _checkbox(
                  label: 'Attach logs of recent activity',
                  value: _attachLogs,
                  onChanged: () {
                    setState(() {
                      _attachLogs = !_attachLogs;
                    });
                  }
                ),
                Container(
                  child: Text('Note: some information about your device (model, operating system, etc.) will also be sent, but none of this information can be used to uniquely identify you or your device.',
                    style: Theme.of(context).primaryTextTheme.headline4.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 12.0,
                    ),
                  ),
                ),
                _submitButton(),
                SizedBox(height: 300.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thankYouMessage() {
    return Material(
      color: Theme.of(context).backgroundColor.withOpacity(0.01),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 25.0, horizontal: 12.0),
              child: Text('Thank you for reporting this error',
                style: TextStyle(color: Theme.of(context).accentColor, fontSize: 18.0),
              ),
            ),
            Container(
              child: ActionButton(
                text: 'Report Another Error',
                onPressed: () {
                  setState(() {
                    _finishedSubmitting = false;
                  });
                },
              ),
            ),
          ],
        )
      ),
    );
  }

  Widget _input({String label, String hintText, TextEditingController controller, int maxLines, Function validator, Function onChanged}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        validator: validator,
        controller: controller,
        maxLines: maxLines,
        cursorColor: Theme.of(context).accentColor,
        cursorWidth: 2.0,
        style: TextStyle(
          color: Theme.of(context).accentColor,
          fontSize: 18.0,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? '',
          hintStyle: TextStyle(
            color: Theme.of(context).accentColor.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  Widget _checkbox({String label, bool value, Function onChanged}) {
    IconData icon = value ? CupertinoIcons.checkmark_square : CupertinoIcons.square;
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.0),
                child: Text(label ?? '',
                  style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontSize: 18.0,
                  )
                ),
              ),
            ),
            Container(
              child: Icon(icon,
                size: 30.0,
                color: Theme.of(context).accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      alignment: Alignment.centerRight,
      child: ActionButton(
        text: 'Send Report',
        onPressed: submitForm,
      ),
    );
  }
}