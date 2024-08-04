import 'package:cookai/model/favorites_model.dart';
import 'package:hive/hive.dart';

class FavoriteDataAdapter extends TypeAdapter<FavoriteData> {
  @override
  final typeId = 0; // Unique identifier for your custom class

  @override
  FavoriteData read(BinaryReader reader) {
    return FavoriteData(
      id: reader.readString(),
      name: reader.readString(),
      description: reader.readString(),
      ingredients: reader.readString(),
      instructions: reader.readString(),
      timetomake: reader.readString(),
      calories: reader.readString(),
      image: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteData obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.ingredients);
    writer.writeString(obj.instructions);
    writer.writeString(obj.timetomake);
    writer.writeString(obj.calories);
    writer.writeString(obj.image);
  }
}
