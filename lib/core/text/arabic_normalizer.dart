/// Arabic normalisation shared by search and fixtures:
/// أإآ→ا، ة→ه، ى→ي; tatweel and diacritics removed (research R7).
String normalizeArabic(String input) {
  const tatweel = '\u0640';
  const diacritics = [
    '\u064B',
    '\u064C',
    '\u064D',
    '\u064E',
    '\u064F',
    '\u0650',
    '\u0651',
    '\u0652',
  ];
  var output = input.replaceAll(tatweel, '');
  for (final diacritic in diacritics) {
    output = output.replaceAll(diacritic, '');
  }
  return output
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}
