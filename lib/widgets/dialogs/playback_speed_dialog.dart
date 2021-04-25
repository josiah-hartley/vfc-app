import 'dart:math';
import 'package:flutter/material.dart';

class PlaybackSpeedDialog extends StatefulWidget {
  PlaybackSpeedDialog({Key key, this.initialSpeed}) : super(key: key);
  final double initialSpeed;

  @override
  _PlaybackSpeedDialogState createState() => _PlaybackSpeedDialogState();
}

class _PlaybackSpeedDialogState extends State<PlaybackSpeedDialog> {
  List<double> _availableSpeeds = [0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4];
  double _speed;
  int _speedIndex;
  double _canvasHeight = 250.0;
  double _canvasWidth = 250.0;
  double _startAngle = 220.0;
  double _endAngle = -40.0;
  List<double> _markerAngles = [];
  Point _centerPivot;
  List<Point> _markers = [];
  List<Point> _markersStart = [];
  List<Label> _labels = [];

  @override
  void initState() { 
    super.initState();
    setState(() {
      _speed = widget.initialSpeed;
      _speedIndex = _availableSpeeds.indexOf(_speed) ?? 0;
      if (_speedIndex < 0) {
        _speedIndex = 0;
      }
      setupCanvas();
    });
  }

  void setupCanvas() {
    _centerPivot = Point(_canvasWidth / 2, _canvasHeight / 2);
    double incrementAngle = (_startAngle - _endAngle).abs() / (_availableSpeeds.length - 1);

    for (int i = 0; i < _availableSpeeds.length; i++) {
      _markerAngles.add(_startAngle - i * incrementAngle);

      _markers.add(coordinatesOnCircle(
        center: _centerPivot,
        radius: _canvasHeight / 2 - 50.0,
        angle: _startAngle - i * incrementAngle,
      ));

      _markersStart.add(coordinatesOnCircle(
        center: _centerPivot,
        radius: _canvasHeight / 2 - 43.0,
        angle: _startAngle - i * incrementAngle,
      ));

      _labels.add(Label(
        position: coordinatesOnCircle(
          center: _centerPivot,
          radius: _canvasHeight / 2 - 20.0,
          angle: _startAngle - i * incrementAngle,
        ),
        text: _availableSpeeds[i].toString(),
      ));
    }
  }

  void _handleDragStart(DragStartDetails details) {
    updateSpeed(details.localPosition);
  }

  void _handleDrag(DragUpdateDetails details) {
    updateSpeed(details.localPosition);
  }

  void updateSpeed(Offset position) {
    double closestSpeed = closestSpeedToAngle(angleFromCenter(position));
    if (closestSpeed != _speed) {
      setState(() {
        _speed = closestSpeed;
        _speedIndex = _availableSpeeds.indexOf(_speed) ?? 0;
      });
    }
  }

  double angleFromCenter(Offset point) {
    double x = point.dx - _canvasWidth / 2;
    double y = _canvasHeight / 2 - point.dy;
    if (x == 0) {
      return y > 0 ? 90.0 : -90.0;
    }
    if (x > 0) {
      return atan(y / x) * 180 / pi;
    }
    return (pi + atan(y/x)) * 180 / pi;
  }

  double closestSpeedToAngle(double angle) {
    double minDistance = 360.0;
    double closestSpeed = 1.0;

    for (int i = 0; i < _markerAngles.length; i++) {
      if ((angle - _markerAngles[i]).abs() < minDistance) {
        minDistance = (angle - _markerAngles[i]).abs();
        closestSpeed = _availableSpeeds[i];
      }
    }

    return closestSpeed;
  }

  Point coordinatesOnCircle({Point center, double radius, double angle}) {
    double x = center.x + radius * cos(angle * pi / 180);
    double y = center.y - radius * sin(angle * pi / 180);

    return Point(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 420,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 30.0),
        child: Column(
          children: [
            Text('Playback Speed',
              style: Theme.of(context).primaryTextTheme.headline1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            Container(
              child: Container(
                height: _canvasHeight,
                width: _canvasWidth,
                child: GestureDetector(
                  onPanStart: _handleDragStart,
                  onPanUpdate: _handleDrag,
                  child: CustomPaint(
                    size: Size(_canvasWidth, _canvasHeight),
                    painter: SpeedometerPainter(
                      speedIndex: _speedIndex,
                      markers: _markers,
                      markersStart: _markersStart,
                      labels: _labels,
                      center: _centerPivot,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                      unselectedColor: Theme.of(context).accentColor.withOpacity(0.7),
                      selectedColor: Theme.of(context).accentColor,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              child: TextButton(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).accentColor,
                    borderRadius: BorderRadius.all(Radius.circular(4.0))
                  ),
                  child: Text('SAVE',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(_speed);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  SpeedometerPainter({this.backgroundColor, this.unselectedColor, this.selectedColor, this.speedIndex, this.markers, this.markersStart, this.labels, this.center});
  final Color backgroundColor;
  final Color unselectedColor;
  final Color selectedColor;
  final int speedIndex;
  final List<Point> markers;
  final List<Point> markersStart;
  final List<Label> labels;
  final Point center;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < markers.length; i++) {
      if (i == speedIndex) {
        /*_drawLine(
          canvas: canvas,
          selected: true,
          start: center,
          end: markers[i],
        );*/
        _drawNeedle(
          canvas: canvas,
          start: center,
          end: markers[i],
        );
      } else {
        _drawLine(
          canvas: canvas,
          selected: false,
          start: markersStart[i],
          end: markers[i],
        );
      }
    }

    for (int j = 0; j < labels.length; j++) {
      TextPainter label = TextPainter(
        text: TextSpan(
          text: labels[j].text,
          style: TextStyle(
            color: j == speedIndex ? selectedColor : unselectedColor, 
            fontSize: j == speedIndex ? 22.0 : 18.0,
            fontWeight: j == speedIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      label.layout();
      label.paint(canvas, Offset(labels[j].position.x - label.width / 2, labels[j].position.y - label.height / 2));
    }
  }

  @override
  bool shouldRepaint(SpeedometerPainter oldDelegate) {
    return speedIndex != oldDelegate.speedIndex;
  }

  void _drawLine({Canvas canvas, bool selected, Point start, Point end}) {
    final paint = Paint()
      ..color = selected ? selectedColor : unselectedColor
      ..strokeWidth = selected ? 3.0 : 1.0
      ..style = PaintingStyle.stroke;

    final line = Path()
      ..moveTo(start.x.toDouble(), start.y.toDouble())
      ..lineTo(end.x.toDouble(), end.y.toDouble())
      ..close();

    canvas.drawPath(line, paint);
  }

  void _drawNeedle({Canvas canvas, Point start, Point end}) {
    double slope = (end.y - start.y) / (end.x - start.x);
    if ((end.x - start.x).abs() < 1) {
      slope = 1000;
    }
    double perpendicularSlope = slope == 0 ? 1000 : (-1 / slope);
    double flareDistance = 5.0;
    double backwardDistance = 20.0;
    double dxBehind = sqrt(pow(backwardDistance, 2) / (pow(slope, 2) + 1));
    double dyBehind = dxBehind * slope;
    if (end.x > start.x) {
      dxBehind = -dxBehind;
      dyBehind = -dyBehind;
    }
    double dxSide = sqrt(pow(flareDistance, 2) / (pow(perpendicularSlope, 2) + 1));
    double dySide = dxSide * perpendicularSlope;
    Point side1 = Point(
      start.x + dxSide,
      start.y + dySide,
    );
    Point side2 = Point(
      start.x - dxSide,
      start.y - dySide,
    );
    Point behind = Point(
      start.x + dxBehind,
      start.y + dyBehind,
    );

    final needlePaint = Paint()
      ..color = selectedColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final line = Path()
      ..moveTo(side1.x.toDouble(), side1.y.toDouble())
      ..lineTo(end.x.toDouble(), end.y.toDouble())
      ..lineTo(side2.x.toDouble(), side2.y.toDouble())
      ..lineTo(behind.x.toDouble(), behind.y.toDouble())
      ..close();

    final pinPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(line, needlePaint);
    canvas.drawCircle(Offset(start.x, start.y), 3.0, pinPaint);
  }
}

class Label {
  Point position;
  String text;

  Label({this.position, this.text});
}