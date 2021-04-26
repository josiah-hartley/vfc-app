import 'dart:math';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/duration_in_minutes.dart';

class SeekBar extends StatefulWidget {
  SeekBar({Key key, this.position, this.duration, this.updatePosition}) : super(key: key);
  final Duration position;
  final Duration duration;
  final Function updatePosition;

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final position = widget.position?.inSeconds ?? 0;
    final duration = widget.duration?.inSeconds ?? 0;
    final value = min(_dragValue ?? (position.toDouble()), duration.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.25),
                trackHeight: 3.0,
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0.0,
                max: duration.toDouble(),
                //value: widget.position.inSeconds.toDouble(),
                value: value,
                onChanged: (double updatedValue) {
                  if (!_dragging) {
                    _dragging = true;
                  }
                  setState(() {
                    _dragValue = updatedValue;
                  });
                  /*if (widget.updatePosition != null) {
                    widget.updatePosition(updatedValue);
                  }*/
                },
                onChangeEnd: (double updatedValue) {
                  if (widget.updatePosition != null) {
                    widget.updatePosition(updatedValue);
                  }
                  _dragging = false;
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20.0),
                    child: Text(messageDurationInMinutes(position.toDouble()),
                      style: Theme.of(context).accentTextTheme.headline3,
                    )
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    child: Text(messageDurationInMinutes(duration.toDouble()),
                      style: Theme.of(context).accentTextTheme.headline3,
                    )
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}