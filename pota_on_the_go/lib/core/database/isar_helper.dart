import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/parks/data/models/park_model.dart';
import '../../features/spots/data/models/spot_model.dart';

class IsarHelper {
  static late Isar _isar;
  static Future<Isar>? _initFuture;

  static Isar get isar => _isar;

  static Future<Isar> init() {
    return _initFuture ??= _open();
  }

  static Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      ParkModelSchema,
      SpotModelSchema,
    ], directory: dir.path);
    return _isar;
  }
}
