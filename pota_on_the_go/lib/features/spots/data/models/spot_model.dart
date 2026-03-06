import 'package:isar/isar.dart';

part 'spot_model.g.dart';

@collection
class SpotModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int spotId;

  late String activator;
  late String frequency;
  late String band;
  late String mode;

  @Index()
  late String reference;

  late DateTime spotTime;
}
