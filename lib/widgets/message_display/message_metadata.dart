import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/duration_in_minutes.dart';
import 'package:voices_for_christ/helpers/reverse_speaker_name.dart';

Widget initialSticker({String name, Color borderColor}) {
  String initials = '';
  // split on a comma followed by space, comma, or space
  List<String> names = name.split(RegExp(r",\ |,|\ "));
  if (names.length >= 1) {
    initials = names[0][0].toUpperCase();
  }
  if (names.length >= 2) {
    initials = names[names.length - 1][0].toUpperCase() + initials;
  }

  if (initials.length < 1) {
    return Container();
  }
  return Container(
    padding: EdgeInsets.only(left: 10.0),
    child: Container(
      child: Text(initials,
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: initialStickerColors(initials)['textColor'] ?? Colors.white,
        )
      ),
      height: 40.0,
      width: 40.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: initialStickerColors(initials)['backgroundColor'] ?? Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        )
      ),
    ),
  );
}

Map<String, Color> initialStickerColors(String initials) {
  if (initials.length < 1) {
    return {
      'backgroundColor': Colors.black,
      'textColor': Colors.white
    };
  }
  String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  double hue;
  double lightness;
  int firstIndex = alphabet.indexOf(initials[0].toUpperCase());
  int secondIndex = alphabet.indexOf(initials[1].toUpperCase()) ?? 0;
  Color textColor;

  if (initials.length != 2) {
    hue = (firstIndex * 138.0) % 360;
    lightness = 0.4;
  } else {
    hue = (secondIndex * 138.0) % 360;
    lightness = firstIndex * 0.015 + 0.4;
  }

  if (hue > 40 && hue < 200) {
    if (lightness > 0.3) {
      textColor = Colors.black;
    } else {
      textColor = Colors.white;
    }
  } else if (hue == 240.0 || hue == 246.0) { // special cases by inspection
    if (lightness > 0.69) {
      textColor = Colors.black;
    } else {
      textColor = Colors.white;
    }
  } else {
    if (lightness > 0.64) {
      textColor = Colors.black;
    } else {
      textColor = Colors.white;
    }
  }

  return {
    'backgroundColor': HSLColor.fromAHSL(0.9, hue, 1.0, lightness).toColor(),
    'textColor': textColor
  };
}

Widget messageTitleAndSpeakerDisplay({Message message, bool truncateTitle, Color textColor}) {
  String _durationInMinutes = messageDurationInMinutes(message.durationinseconds);
  
  return Container(
    padding: EdgeInsets.all(15.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message.title ?? '',
          maxLines: 2,
          overflow: truncateTitle ? TextOverflow.ellipsis : TextOverflow.visible,
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: message.isdownloaded == 1 ? FontWeight.w500 : FontWeight.w400,
            color: message.isdownloaded == 1 ? textColor : textColor.withOpacity(0.9),
            //fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 6.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(speakerReversedName(message.speaker),
                  overflow: truncateTitle ? TextOverflow.ellipsis : TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 16.0,
                    //fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: message.isdownloaded == 1 ? textColor.withOpacity(0.9) : textColor.withOpacity(1.0),
                  ),
                ),
              ),
              Text(_durationInMinutes,
                style: TextStyle(
                  fontSize: 16.0,
                  fontStyle: FontStyle.italic,
                  color: message.isdownloaded == 1 ? textColor.withOpacity(0.9) : textColor.withOpacity(1.0),
                ),
              ),
              /*Container(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: CircularPercentIndicator(
                    radius: 15.0,
                    lineWidth: 3.0,
                    percent: (_percentagePlayed / 100).toDouble(),
                    backgroundColor: Theme.of(context).indicatorColor,
                    progressColor: Theme.of(context).buttonColor,
                  ),
              ),
              Text('${_percentagePlayed.round().toString()}%'),*/
            ],
          ),
        ),
      ]
    ),
  );
}