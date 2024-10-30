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
      calories: reader.readInt(), // Read as an integer
      fat: reader.readInt(), // Read as an integer
      protein: reader.readInt(), // Read as an integer
      carbs: reader.readInt(), // Read as an integer
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, StatsData obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeInt(obj.calories); // Write as an integer
    writer.writeInt(obj.fat); // Write as an integer
    writer.writeInt(obj.protein); // Write as an integer
    writer.writeInt(obj.carbs); // Write as an integer
    writer.writeInt(obj.date.millisecondsSinceEpoch);
  }
}
