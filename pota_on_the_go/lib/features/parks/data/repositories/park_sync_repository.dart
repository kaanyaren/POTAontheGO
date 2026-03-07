import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_helper.dart';
import '../models/park_model.dart';
import '../../../../core/network/dio_client.dart';

// Riverpod Provider for ParkSyncRepository
final parkSyncRepositoryProvider = Provider<ParkSyncRepository>((ref) {
  return ParkSyncRepository(DioClient().dio);
});

class ParkSyncRepository {
  static const _csvEndpoints = <String>[
    'https://pota.app/all_parks_ext.csv',
    // fallback mirror endpoint for cases where primary DNS path fails
    'https://pota.app/all_parks.csv',
  ];
  static const _programListEndpoint = 'https://api.pota.app/program/';
  static const _programParksEndpointPrefix =
      'https://api.pota.app/program/parks/';

  final Dio _dio;

  ParkSyncRepository(this._dio);

  Future<bool> syncParksFromCsv() async {
    for (final endpoint in _csvEndpoints) {
      final synced = await _syncFromCsvEndpoint(endpoint);
      if (synced) {
        return true;
      }
    }

    final syncedFromApi = await _syncFromApiFallback();
    if (syncedFromApi) {
      return true;
    }

    debugPrint('Park sync skipped: CSV and API fallback endpoints failed.');
    return false;
  }

  Future<bool> _syncFromCsvEndpoint(String endpoint) async {
    try {
      final response = await _dio.get<List<int>>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200 || response.data == null) {
        return false;
      }

      final parsedRows = await compute(
        _parseParksFromCsvBytes,
        Uint8List.fromList(response.data!),
      );
      if (parsedRows.isEmpty) {
        return false;
      }

      await _persistRows(parsedRows, sourceLabel: endpoint);
      return true;
    } catch (e) {
      debugPrint('Park sync endpoint failed ($endpoint): $e');
      return false;
    }
  }

  Future<bool> _syncFromApiFallback() async {
    try {
      final programsResponse = await _dio.get<List<dynamic>>(
        _programListEndpoint,
      );

      if (programsResponse.statusCode != 200 || programsResponse.data == null) {
        return false;
      }

      final activePrefixes = programsResponse.data!
          .whereType<Map<String, dynamic>>()
          .where((program) => (program['isActive'] ?? 0) == 1)
          .map((program) => (program['programPrefix'] ?? '').toString().trim())
          .where((prefix) => prefix.isNotEmpty)
          .toSet()
          .toList(growable: false);

      if (activePrefixes.isEmpty) {
        return false;
      }

      const chunkSize = 8;
      final mergedRowsByReference = <String, Map<String, Object>>{};

      for (var start = 0; start < activePrefixes.length; start += chunkSize) {
        final end = (start + chunkSize < activePrefixes.length)
            ? start + chunkSize
            : activePrefixes.length;
        final chunk = activePrefixes.sublist(start, end);

        final chunkRows = await Future.wait(
          chunk.map(_fetchProgramParksRows),
          eagerError: false,
        );

        for (final rows in chunkRows) {
          for (final row in rows) {
            final reference = row['reference'] as String;
            mergedRowsByReference[reference] = row;
          }
        }
      }

      final mergedRows = mergedRowsByReference.values.toList(growable: false);
      if (mergedRows.isEmpty) {
        return false;
      }

      await _persistRows(mergedRows, sourceLabel: 'api.pota.app fallback');
      return true;
    } catch (e) {
      debugPrint('Park sync API fallback failed: $e');
      return false;
    }
  }

  Future<List<Map<String, Object>>> _fetchProgramParksRows(
    String programPrefix,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '$_programParksEndpointPrefix$programPrefix',
      );

      if (response.statusCode != 200 || response.data == null) {
        return const [];
      }

      final rows = <Map<String, Object>>[];
      for (final raw in response.data!.whereType<Map<String, dynamic>>()) {
        final reference = (raw['reference'] ?? '').toString().trim();
        final name = (raw['name'] ?? '').toString().trim();
        if (reference.isEmpty || name.isEmpty) {
          continue;
        }

        rows.add({
          'reference': reference,
          'name': name,
          'locationDesc': (raw['locationDesc'] ?? '').toString().trim(),
          'latitude': _toDouble(raw['latitude']),
          'longitude': _toDouble(raw['longitude']),
        });
      }

      return rows;
    } catch (e) {
      debugPrint('Program parks fetch failed ($programPrefix): $e');
      return const [];
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _persistRows(
    List<Map<String, Object>> parsedRows, {
    required String sourceLabel,
  }) async {
    final isar = IsarHelper.isar;
    const batchSize = 2000;

    for (var start = 0; start < parsedRows.length; start += batchSize) {
      final end = (start + batchSize < parsedRows.length)
          ? start + batchSize
          : parsedRows.length;
      final parksToInsert = parsedRows
          .sublist(start, end)
          .map(
            (row) => ParkModel()
              ..reference = row['reference']! as String
              ..name = row['name']! as String
              ..locationDesc = row['locationDesc']! as String
              ..latitude = row['latitude']! as double
              ..longitude = row['longitude']! as double,
          )
          .toList(growable: false);

      await isar.writeTxn(() async {
        await isar.parkModels.putAll(parksToInsert);
      });
    }

    debugPrint(
      'Successfully synced ${parsedRows.length} parks from $sourceLabel',
    );
  }
}

List<Map<String, Object>> _parseParksFromCsvBytes(Uint8List bytes) {
  final csvString = utf8.decode(bytes, allowMalformed: true);
  final lines = const LineSplitter()
      .convert(csvString)
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty) {
    return const [];
  }

  var refIdx = 0;
  var nameIdx = 1;
  var locIdx = 4;
  var latIdx = 5;
  var lonIdx = 6;

  final headers = _parseCsvRow(lines.first);
  for (var i = 0; i < headers.length; i++) {
    final header = headers[i].toLowerCase();
    if (header.contains('reference')) refIdx = i;
    if (header.contains('name')) nameIdx = i;
    if (header.contains('location') || header.contains('desc')) locIdx = i;
    if (header.contains('latitude')) latIdx = i;
    if (header.contains('longitude')) lonIdx = i;
  }

  final parks = <Map<String, Object>>[];
  for (var i = 1; i < lines.length; i++) {
    final row = _parseCsvRow(lines[i]);
    if (row.length <= lonIdx || row.length <= nameIdx || row.length <= refIdx) {
      continue;
    }

    final reference = row[refIdx].trim();
    final name = row[nameIdx].trim();
    if (reference.isEmpty || name.isEmpty) {
      continue;
    }

    parks.add({
      'reference': reference,
      'name': name,
      'locationDesc': locIdx < row.length ? row[locIdx].trim() : '',
      'latitude': double.tryParse(row[latIdx]) ?? 0.0,
      'longitude': double.tryParse(row[lonIdx]) ?? 0.0,
    });
  }

  return parks;
}

List<String> _parseCsvRow(String line) {
  final values = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      final isEscapedQuote =
          inQuotes && i + 1 < line.length && line[i + 1] == '"';
      if (isEscapedQuote) {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      values.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  values.add(buffer.toString().trim());
  return values;
}
