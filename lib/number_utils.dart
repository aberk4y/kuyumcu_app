double parseNumericValue(String raw) {
  var value = raw
      .replaceAll('₺', '')
      .replaceAll('%', '')
      .replaceAll(' ', '')
      .trim();

  if (value.isEmpty) {
    return 0;
  }

  if (value.contains(',') && value.contains('.')) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (value.contains(',')) {
    value = value.replaceAll(',', '.');
  }

  return double.tryParse(value) ?? 0;
}

String formatTurkishNumber(
  double value, {
  int minDecimals = 2,
  int maxDecimals = 2,
}) {
  final absolute = value.abs();
  final fixed = absolute.toStringAsFixed(maxDecimals);
  final parts = fixed.split('.');
  final whole = _withThousands(parts[0]);

  if (maxDecimals == 0) {
    return value.isNegative ? '-$whole' : whole;
  }

  var fraction = parts.length > 1 ? parts[1] : '';
  while (fraction.length > minDecimals && fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }

  final formatted = fraction.isEmpty ? whole : '$whole,$fraction';
  return value.isNegative ? '-$formatted' : formatted;
}

String formatRawNumber(
  String raw, {
  int minDecimals = 2,
  int maxDecimals = 2,
}) {
  if (raw.trim().isEmpty) {
    return '-';
  }

  return formatTurkishNumber(
    parseNumericValue(raw),
    minDecimals: minDecimals,
    maxDecimals: maxDecimals,
  );
}

String extractTimeLabel(String raw) {
  final match = RegExp(r'(\d{2}:\d{2})').firstMatch(raw);
  return match?.group(1) ?? '--:--';
}

String _withThousands(String wholePart) {
  final buffer = StringBuffer();

  for (var index = 0; index < wholePart.length; index++) {
    final reverseIndex = wholePart.length - index;
    buffer.write(wholePart[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}
