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
  final Dio _dio;

  ParkSyncRepository(this._dio);

  Future<void> syncParksFromCsv() async {
    try {
      // POTA provides a daily CSV dump of all parks
      final response = await _dio.get<List<int>>(
        'https://pota.app/all_parks_ext.csv',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsedRows = await compute(
          _parseParksFromCsvBytes,
          Uint8List.fromList(response.data!),
        );
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

        debugPrint('Successfully synced ${parsedRows.length} parks from CSV');
      }
    } catch (e) {
      debugPrint('Error syncing parks: $e');
      rethrow;
    }
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
