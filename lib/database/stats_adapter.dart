import 'package:cookai/model/stats_model.dart';
import 'package:hive/hive.dart';

class StatsDataAdapter extends TypeAdapter<StatsData> {
  @override
  final typeId = 1; // Unique identifier for your custom class

  @override
  StatsData read(BinaryReader reader) {
    return StatsData(
      id: reader.readString(),
      title: reader.readString(),
      calories: reader.readString(),
      fat: reader.readString(),
      protein: reader.readString(),
      carbs: reader.readString(),
      date: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, StatsData obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.calories);
    writer.writeString(obj.fat);
    writer.writeString(obj.protein);
    writer.writeString(obj.carbs);
    writer.writeString(obj.date);
  }
}
