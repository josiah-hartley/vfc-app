String messageDurationInMinutes(double durationInSeconds) {
  if (durationInSeconds == null) {
    return '';
  }

  int hours = durationInSeconds ~/ 3600;
  String minutes = (durationInSeconds ~/ 60).toString();
  String seconds = (durationInSeconds % 60).round().toString();
  if (seconds.length == 1) {
    seconds = '0' + seconds;
  }
  if (hours < 1) {
    return '$minutes:$seconds';
  }
  if (minutes.length == 1) {
    minutes = '0' + minutes;
  }
  return '$hours:$minutes:$seconds';
}