import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:flutter/foundation.dart';
import '../../../core/database/isar_helper.dart';
import '../models/park_model.dart';
import '../../../core/network/dio_client.dart';

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
        // Decode bytes to string
        final csvString = utf8.decode(response.data!);
        
        // Parse CSV string
        final List<List<dynamic>> rows = const CsvToListConverter(
          eol: '\n',
          fieldDelimiter: ',',
        ).convert(csvString);

        if (rows.isEmpty) return;
        
        final isar = IsarHelper.isar;
        
        // CSV headers logic (assuming first row is headers)
        // reference, name, active, entityId, locationDesc, latitude, longitude, grid...
        final List<ParkModel> parksToInsert = [];
        
        // Map expected indexes (fallback values based on pota.app format)
        int refIdx = 0;
        int nameIdx = 1;
        int locIdx = 4;
        int latIdx = 5;
        int lonIdx = 6;
        
        final headers = rows.first;
        for (int i = 0; i < headers.length; i++) {
          final header = headers[i].toString().toLowerCase();
          if (header.contains('reference')) refIdx = i;
          if (header.contains('name')) nameIdx = i;
          if (header.contains('location') || header.contains('desc')) locIdx = i;
          if (header.contains('latitude')) latIdx = i;
          if (header.contains('longitude')) lonIdx = i;
        }

        // Process rows (skip header)
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length > lonIdx) {
            final park = ParkModel()
              ..reference = row[refIdx].toString()
              ..name = row[nameIdx].toString()
              ..locationDesc = row[locIdx].toString()
              ..latitude = double.tryParse(row[latIdx].toString()) ?? 0.0
              ..longitude = double.tryParse(row[lonIdx].toString()) ?? 0.0;
            
            parksToInsert.add(park);
          }
        }

        // Batch insert into local Isar DB
        await isar.writeTxn(() async {
          await isar.parkModels.putAll(parksToInsert);
        });
        
        print('Successfully synced \${parksToInsert.length} parks from CSV');
      }
    } catch (e) {
      print('Error syncing parks: \$e');
      rethrow;
    }
  }
}
