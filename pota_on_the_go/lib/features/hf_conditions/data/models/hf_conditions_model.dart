import 'package:xml/xml.dart';

class HfConditionsSnapshot {
  const HfConditionsSnapshot({
    required this.source,
    required this.sourceUrl,
    required this.updated,
    required this.solarFlux,
    required this.aIndex,
    required this.kIndex,
    required this.kIndexNotice,
    required this.xray,
    required this.sunspots,
    required this.solarWind,
    required this.magneticField,
    required this.geomagneticField,
    required this.signalNoise,
    required this.muf,
    required this.bandConditions,
  });

  factory HfConditionsSnapshot.fromXml(String xmlPayload) {
    final document = XmlDocument.parse(xmlPayload);
    final solarData = _firstElementByLocalName(document, 'solardata');

    if (solarData == null) {
      throw const FormatException(
        'HF conditions XML: solardata node is missing.',
      );
    }

    final sourceElement = _firstElementByLocalName(solarData, 'source');
    final bandElements = _elementsByLocalName(
      _firstElementByLocalName(solarData, 'calculatedconditions') ?? solarData,
      'band',
    );
    final mufValue = _readText(solarData, 'muf');

    return HfConditionsSnapshot(
      source: sourceElement?.innerText.trim() ?? '',
      sourceUrl: sourceElement?.getAttribute('url') ?? '',
      updated: _readText(solarData, 'updated'),
      solarFlux: _readText(solarData, 'solarflux'),
      aIndex: _readText(solarData, 'aindex'),
      kIndex: _readText(solarData, 'kindex'),
      kIndexNotice: _readText(solarData, 'kindexnt'),
      xray: _readText(solarData, 'xray'),
      sunspots: _readText(solarData, 'sunspots'),
      solarWind: _readText(solarData, 'solarwind'),
      magneticField: _readText(solarData, 'magneticfield'),
      geomagneticField: _readText(solarData, 'geomagfield'),
      signalNoise: _readText(solarData, 'signalnoise'),
      muf: mufValue.isEmpty ? _readText(solarData, 'muffactor') : mufValue,
      bandConditions: bandElements
          .map(
            (band) => HfBandCondition(
              bandName: band.getAttribute('name')?.trim() ?? '',
              time: band.getAttribute('time')?.trim().toLowerCase() ?? '',
              condition: band.innerText.trim(),
            ),
          )
          .where((band) => band.bandName.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String source;
  final String sourceUrl;
  final String updated;
  final String solarFlux;
  final String aIndex;
  final String kIndex;
  final String kIndexNotice;
  final String xray;
  final String sunspots;
  final String solarWind;
  final String magneticField;
  final String geomagneticField;
  final String signalNoise;
  final String muf;
  final List<HfBandCondition> bandConditions;

  bool get hasDisplayableData {
    if (bandConditions.isNotEmpty) {
      return true;
    }

    final scalarValues = [
      source,
      updated,
      solarFlux,
      aIndex,
      kIndex,
      xray,
      sunspots,
      solarWind,
      magneticField,
      geomagneticField,
      signalNoise,
      muf,
    ];

    return scalarValues.any((value) => value.trim().isNotEmpty);
  }

  List<HfBandCondition> get dayBands => bandConditions
      .where((band) => band.time == 'day')
      .toList(growable: false);

  List<HfBandCondition> get nightBands => bandConditions
      .where((band) => band.time == 'night')
      .toList(growable: false);

  static String _readText(XmlElement parent, String tagName) {
    final element = _firstElementByLocalName(parent, tagName);
    return element?.innerText.trim() ?? '';
  }

  static XmlElement? _firstElementByLocalName(XmlNode node, String localName) {
    final targetName = localName.toLowerCase();
    for (final element in node.descendants.whereType<XmlElement>()) {
      if (element.name.local.toLowerCase() == targetName) {
        return element;
      }
    }
    return null;
  }

  static List<XmlElement> _elementsByLocalName(XmlNode node, String localName) {
    final targetName = localName.toLowerCase();
    final matched = <XmlElement>[];
    for (final element in node.descendants.whereType<XmlElement>()) {
      if (element.name.local.toLowerCase() == targetName) {
        matched.add(element);
      }
    }
    return matched;
  }
}

class HfBandCondition {
  const HfBandCondition({
    required this.bandName,
    required this.time,
    required this.condition,
  });

  final String bandName;
  final String time;
  final String condition;

  HfBandConditionLevel get level {
    final normalized = condition.trim().toLowerCase();
    if (normalized == 'good') {
      return HfBandConditionLevel.good;
    }
    if (normalized == 'fair') {
      return HfBandConditionLevel.fair;
    }
    if (normalized == 'poor') {
      return HfBandConditionLevel.poor;
    }
    return HfBandConditionLevel.unknown;
  }
}

enum HfBandConditionLevel { good, fair, poor, unknown }
