class CallsignProfileModel {
  const CallsignProfileModel({
    required this.callsign,
    required this.name,
    required this.qth,
    required this.gravatarHash,
    required this.activator,
    required this.attempts,
    required this.hunter,
    required this.awards,
    required this.endorsements,
  });

  factory CallsignProfileModel.fromJson(Map<String, dynamic> json) {
    return CallsignProfileModel(
      callsign: (json['callsign'] ?? '').toString().trim().toUpperCase(),
      name: (json['name'] ?? '').toString().trim(),
      qth: (json['qth'] ?? '').toString().trim(),
      gravatarHash: (json['gravatar'] ?? '').toString().trim(),
      activator: CallsignActivityStats.fromJson(json['activator']),
      attempts: CallsignActivityStats.fromJson(json['attempts']),
      hunter: CallsignHunterStats.fromJson(json['hunter']),
      awards: _toInt(json['awards']),
      endorsements: _toInt(json['endorsements']),
    );
  }

  final String callsign;
  final String name;
  final String qth;
  final String gravatarHash;
  final CallsignActivityStats activator;
  final CallsignActivityStats attempts;
  final CallsignHunterStats hunter;
  final int awards;
  final int endorsements;

  String? get gravatarUrl {
    if (gravatarHash.isEmpty) {
      return null;
    }

    return 'https://www.gravatar.com/avatar/$gravatarHash?s=180&d=identicon';
  }
}

class CallsignActivityStats {
  const CallsignActivityStats({
    required this.activations,
    required this.parks,
    required this.qsos,
  });

  factory CallsignActivityStats.fromJson(dynamic payload) {
    if (payload is! Map) {
      return const CallsignActivityStats(activations: 0, parks: 0, qsos: 0);
    }

    return CallsignActivityStats(
      activations: _toInt(payload['activations']),
      parks: _toInt(payload['parks']),
      qsos: _toInt(payload['qsos']),
    );
  }

  final int activations;
  final int parks;
  final int qsos;
}

class CallsignHunterStats {
  const CallsignHunterStats({required this.parks, required this.qsos});

  factory CallsignHunterStats.fromJson(dynamic payload) {
    if (payload is! Map) {
      return const CallsignHunterStats(parks: 0, qsos: 0);
    }

    return CallsignHunterStats(
      parks: _toInt(payload['parks']),
      qsos: _toInt(payload['qsos']),
    );
  }

  final int parks;
  final int qsos;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
