final _frequencyRegex = RegExp(r'(\d+[\.,]?\d*)');
final _trailingZerosRegex = RegExp(r'0+$');
final _trailingDotRegex = RegExp(r'\.$');
final _nonAlphaNumDotRegex = RegExp(r'[^A-Z0-9.]');

double? tryParseFrequencyMHz(String rawFrequency) {
  final trimmed = rawFrequency.trim();
  if (trimmed.isEmpty) return null;

  final match = _frequencyRegex.firstMatch(trimmed);
  final token = match?.group(1)?.replaceAll(',', '.');
  if (token == null || token.isEmpty) return null;

  final parsed = double.tryParse(token);
  if (parsed == null || parsed <= 0) return null;

  if (parsed >= 1_000_000) {
    return parsed / 1_000_000;
  }
  if (parsed >= 1_000) {
    return parsed / 1_000;
  }

  return parsed;
}

String resolveBandLabel({String rawBand = '', String frequency = ''}) {
  final normalizedHint = _normalizeBandHint(rawBand);
  if (normalizedHint.isNotEmpty) {
    return normalizedHint;
  }

  final parsedFrequency = tryParseFrequencyMHz(frequency);
  if (parsedFrequency == null) {
    return '';
  }

  for (final band in _bandRanges) {
    if (parsedFrequency >= band.minMHz && parsedFrequency <= band.maxMHz) {
      return band.label;
    }
  }

  return '';
}

String formatFrequencyLabel(String rawFrequency) {
  final parsed = tryParseFrequencyMHz(rawFrequency);
  if (parsed == null) {
    return rawFrequency.trim();
  }

  final precision = parsed >= 100
      ? 1
      : parsed >= 10
      ? 3
      : 4;
  final formatted = parsed
      .toStringAsFixed(precision)
      .replaceFirst(_trailingZerosRegex, '')
      .replaceFirst(_trailingDotRegex, '');

  return formatted;
}

String _normalizeBandHint(String rawBand) {
  final compact = rawBand.trim().toUpperCase().replaceAll(
    _nonAlphaNumDotRegex,
    '',
  );
  if (compact.isEmpty) {
    return '';
  }

  return _knownBandLabels[compact] ?? '';
}

const _knownBandLabels = <String, String>{
  '2190M': '2190m',
  '630M': '630m',
  '160M': '160m',
  '80M': '80m',
  '60M': '60m',
  '40M': '40m',
  '30M': '30m',
  '20M': '20m',
  '17M': '17m',
  '15M': '15m',
  '12M': '12m',
  '10M': '10m',
  '6M': '6m',
  '4M': '4m',
  '2M': '2m',
  '1.25M': '1.25m',
  '125CM': '1.25m',
  '70CM': '70cm',
  '33CM': '33cm',
  '23CM': '23cm',
};

const _bandRanges = <_BandRange>[
  _BandRange('2190m', 0.1357, 0.1378),
  _BandRange('630m', 0.472, 0.479),
  _BandRange('160m', 1.8, 2.0),
  _BandRange('80m', 3.5, 4.0),
  _BandRange('60m', 5.0, 5.5),
  _BandRange('40m', 7.0, 7.3),
  _BandRange('30m', 10.1, 10.15),
  _BandRange('20m', 14.0, 14.35),
  _BandRange('17m', 18.068, 18.168),
  _BandRange('15m', 21.0, 21.45),
  _BandRange('12m', 24.89, 24.99),
  _BandRange('10m', 28.0, 29.7),
  _BandRange('6m', 50.0, 54.0),
  _BandRange('4m', 70.0, 71.0),
  _BandRange('2m', 144.0, 148.0),
  _BandRange('1.25m', 222.0, 225.0),
  _BandRange('70cm', 420.0, 450.0),
  _BandRange('33cm', 902.0, 928.0),
  _BandRange('23cm', 1240.0, 1300.0),
];

class _BandRange {
  const _BandRange(this.label, this.minMHz, this.maxMHz);

  final String label;
  final double minMHz;
  final double maxMHz;
}
