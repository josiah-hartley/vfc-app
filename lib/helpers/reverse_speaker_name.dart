String speakerReversedName(String name) {
  if (name == null) {
    return '';
  }
  return name.split(',').reversed.join(' ').trim();
}