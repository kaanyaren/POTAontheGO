import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_helper.dart';
import '../../data/models/park_model.dart';

final localParksProvider = FutureProvider<List<ParkModel>>((ref) async {
  return IsarHelper.isar.parkModels.where().findAll();
});

final localParkCountProvider = FutureProvider<int>((ref) async {
  return IsarHelper.isar.parkModels.count();
});
