import 'package:flutter_riverpod/legacy.dart';

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

final mapFocusRequestProvider = StateProvider<MapFocusRequest?>((ref) => null);

class MapFocusRequest {
  const MapFocusRequest({required this.reference, required this.activator});

  final String reference;
  final String activator;
}
