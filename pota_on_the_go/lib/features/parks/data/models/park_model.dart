import 'package:isar/isar.dart';

part 'park_model.g.dart';

@collection
class ParkModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String reference;

  late String name;
  late double latitude;
  late double longitude;
  late String locationDesc;
}
